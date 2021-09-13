defmodule Bridge do
  @moduledoc """
  Bridge is a drop-in replacement for Erlangs `wx` modules that
  sends commands sent to `wx` modules via tcp/ip to a daemon.
  It's purpose is to make it possible to communicate with native
  parts of iOS/Android applications within the elixir-desktop
  framework to make apps mobile!
  """
  use GenServer
  defstruct port: nil, socket: nil, send: nil, requests: %{}, funs: %{}

  def new([]) do
    # GenServer.start(__MODULE__)
  end

  @impl true
  def init([]) do
    port = String.to_integer(System.get_env("BRIDGE_PORT", "0"))

    {socket, send} =
      if port == 0 do
        {Bridge.Mock, &Bridge.Mock.send/2}
      else
        IO.inspect({"localhost", port, packet: 4, active: true})

        {:ok, socket} =
          :gen_tcp.connect({127, 0, 0, 1}, port, packet: 4, active: true, mode: :binary)

        {socket, &:gen_tcp.send/2}
      end

    {:ok,
     %Bridge{
       port: port,
       socket: socket,
       send: send
     }}
  end

  def bridge_call(:wx, :batch, [fun]), do: fun.()

  def bridge_call(:wx, :new, _args) do
    case Process.whereis(__MODULE__) do
      nil ->
        {:ok, pid} = GenServer.start(__MODULE__, [], name: __MODULE__)
        pid

      pid ->
        pid
    end
  end

  def bridge_call(module, method, args) do
    IO.puts("bridge_call: #{module}.#{method}(#{inspect(args)})")
    ref = System.unique_integer([:positive])
    json = encode!([module, method, args])

    ret =
      GenServer.call(__MODULE__, {:bridge_call, ref, json})
      |> decode!()

    IO.puts("bridge_call: #{module}.#{method}(#{inspect(args)}) => #{inspect(ret)}")

    ret
  end

  def encode!(var) do
    pre_encode!(var)
    |> Jason.encode!()
  end

  def pre_encode!(var) do
    case var do
      tuple when is_tuple(tuple) ->
        pre_encode!(%{_type: :tuple, value: Tuple.to_list(tuple)})

      pid when is_pid(pid) ->
        pre_encode!(%{_type: :pid, value: List.to_string(:erlang.pid_to_list(pid))})

      fun when is_function(fun) ->
        pre_encode!(%{_type: :fun, value: GenServer.call(__MODULE__, {:register_fun, fun})})

      list when is_list(list) ->
        Enum.map(list, &pre_encode!/1)

      map when is_map(map) ->
        Enum.reduce(map, %{}, fn {key, value}, map ->
          Map.put(map, pre_encode!(key), pre_encode!(value))
        end)

      atom when is_atom(atom) ->
        ":" <> Atom.to_string(atom)

      other ->
        other
    end
  end

  def decode!(json) do
    Jason.decode!(json) |> decode()
  end

  defp decode(list) when is_list(list) do
    Enum.map(list, &decode/1)
  end

  defp decode(":" <> name) do
    String.to_atom(name)
  end

  defp decode(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, ret ->
      Map.put(ret, decode(key), decode(value))
    end)
    |> decode_map()
  end

  defp decode(other), do: other

  defp decode_map(%{_type: :tuple, value: tuple}) do
    List.to_tuple(tuple)
  end

  defp decode_map(%{_type: :pid, value: pid}) do
    :erlang.list_to_pid(String.to_charlist(pid))
  end

  defp decode_map(other), do: other

  @impl true
  def handle_call(
        {:bridge_call, ref, json},
        from,
        state = %Bridge{socket: socket, requests: reqs, send: send}
      ) do
    if socket do
      message = <<ref::unsigned-size(64), json::binary>>
      send.(socket, message)
      {:noreply, %Bridge{state | requests: Map.put(reqs, ref, {from, message})}}
    else
      {:reply, ":ok", state}
    end
  end

  def handle_call({:register_fun, fun}, _from, state = %Bridge{funs: funs}) do
    ref = System.unique_integer([:positive])
    funs = Map.put(funs, ref, fun)
    {:reply, ref, %Bridge{state | funs: funs}}
  end

  @impl true
  def handle_info(
        {:tcp, _port, <<ref::unsigned-size(64), json::binary>>},
        state = %Bridge{requests: reqs}
      ) do
    {from, message} = reqs[ref]

    if json == "use_mock" do
      Bridge.Mock.send(Bridge.Mock, message)
      {:noreply, state}
    else
      GenServer.reply(from, json)
      {:noreply, %Bridge{state | requests: Map.delete(reqs, ref)}}
    end
  end

  defmacro generate_bridge_calls(module, names) do
    names = names ++ [:new, :destroy, :connect]

    methods =
      for name <- names do
        """
          def #{name}(), do: Bridge.bridge_call(:#{module}, :#{name}, [])
          def #{name}(arg), do: Bridge.bridge_call(:#{module}, :#{name}, [arg])
          def #{name}(arg1, arg2), do: Bridge.bridge_call(:#{module}, :#{name}, [arg1, arg2])
          def #{name}(arg1, arg2, arg3), do: Bridge.bridge_call(:#{module}, :#{name}, [arg1, arg2, arg3])
          def #{name}(arg1, arg2, arg3, arg4), do: Bridge.bridge_call(:#{module}, :#{name}, [arg1, arg2, arg3, arg4])
        """
      end

    code = """
    defmodule :#{module} do
      #{methods}
    end
    """

    Code.string_to_quoted(code)
  end
end
