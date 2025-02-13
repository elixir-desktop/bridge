defmodule Bridge do
  @moduledoc """
  Bridge is a drop-in replacement for Erlangs `wx` modules that
  sends commands sent to `wx` modules via tcp/ip to a daemon.
  It's purpose is to make it possible to communicate with native
  parts of iOS/Android applications within the elixir-desktop
  framework to make apps mobile!

  # Protocol

  Current protocol is json based.

  All :wx***.new(args...) calls generate keyword lists like:
    `[id: System.unique_integer([:positive]), type: module, args: args]`

  Most wx***.method(args...) calls are then forwarded via JSON to the native side with
  a 64-bit request id value:
    `<<request_ref :: unsigned-size(64), json :: binary>>`

  The responses correspndingly return the same ref and the json response:
    `<<response_ref :: unsigned-size(64), json :: binary>>`

  For receiving commands from the native side of the bridge there are three special ref
  values:
    * ref = 0 -> This indicates a published system event system, corresponding to `:wx.subscribe_events()`
      needed for publishing files that are shared to the app.
      `<<0 :: unsigned-size(64), event :: binary>>`
    * ref = 1 -> This indicates triggering a callback function call that was previously passed over.
      Internally an `funs` that are passed into `:wx.method()` calls are converted to 64-bit references,
      those can be used here to indicate which function to call.
    `<<1 :: unsigned-size(64), fun :: unsigned-size(64), event :: binary>>`
    * ref = 2 -> This indicates a call from the native side back into the app side. TBD
    `<<2 :: unsigned-size(64), ...>>`

    # JSON Encoding of Elixir Terms



  """
  use GenServer
  require Logger

  defstruct port: nil,
            socket: nil,
            send: nil,
            requests: %{},
            funs: %{},
            events: [],
            subscribers: [],
            lastURL: nil

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
  def bridge_call(:wx, :set_env, _args), do: :ok
  def bridge_call(:wx, :get_env, _args), do: :ok
  def bridge_call(:wx, :getObjectType, [obj]), do: Keyword.get(obj, :type)

  def bridge_call(:wxWebView, :loadURL, [obj, uri]) do
    GenServer.cast(__MODULE__, {:lastURL, uri})
    do_bridge_call(:wxWebView, :loadURL, [obj, uri])
  end

  def bridge_call(:wx, :new, _args) do
    case Process.whereis(__MODULE__) do
      nil ->
        {:ok, pid} = GenServer.start(__MODULE__, [], name: __MODULE__)
        pid

      pid ->
        pid
    end
  end

  def bridge_call(type, :new, args) do
    [id: System.unique_integer([:positive]), type: type, args: args]
  end

  def bridge_call(_type, :getId, args) do
    Keyword.get(args, :id)
  end

  def bridge_call(module, method = :connect, args) do
    IO.puts("bridge_cast: #{module}.#{method}(#{inspect(args)})")
    ref = System.unique_integer([:positive]) + 10
    json = encode!([module, method, args ++ [self()]])

    GenServer.cast(__MODULE__, {:bridge_call, ref, json})
  end

  def bridge_call(module, method, args) do
    do_bridge_call(module, method, args)
  end

  defp do_bridge_call(module, method, args) do
    IO.puts("bridge_call: #{module}.#{method}(#{inspect(args)})")
    ref = System.unique_integer([:positive]) + 10
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
  def handle_cast({:bridge_call, ref, json}, state) do
    case handle_call({:bridge_call, ref, json}, nil, state) do
      {:reply, _ret, state} -> {:noreply, state}
      {:noreply, state} -> {:noreply, state}
    end
  end

  def handle_cast({:lastURL, uri}, state) do
    {:noreply, %Bridge{state | lastURL: uri}}
  end

  @impl true
  def handle_call(
        {:subscribe_events, pid},
        _from,
        state = %Bridge{events: events, subscribers: subscribers}
      ) do
    for event <- events do
      send(pid, event)
    end

    {:reply, :ok, %Bridge{state | events: [], subscribers: [pid | subscribers]}}
  end

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
        {:tcp, _port, <<0::unsigned-size(64), json::binary>>},
        state = %Bridge{subscribers: subscribers, events: events}
      ) do
    event = decode!(json)

    if [] == subscribers do
      IO.puts("no subscriber for event #{inspect(event)}")
      {:noreply, %Bridge{state | events: events ++ [event]}}
    else
      IO.puts("sending event to subscribers #{inspect(event)}")

      for sub <- subscribers do
        send(sub, event)
      end

      {:noreply, state}
    end
  end

  def handle_info(
        {:tcp, _port, <<1::unsigned-size(64), fun_ref::unsigned-size(64), json::binary>>},
        state = %Bridge{funs: funs}
      ) do
    args = decode!(json)

    case Map.get(funs, fun_ref) do
      nil ->
        IO.puts("no fun defined for fun_ref #{fun_ref} (#{inspect(args)})")

      fun ->
        IO.puts("executing callback fun_ref #{fun_ref} (#{inspect(args)})")
        spawn(fn -> apply(fun, args) end)
    end

    {:noreply, state}
  end

  def handle_info(
        {:tcp, _port, <<2::unsigned-size(64), json::binary>>},
        state = %Bridge{}
      ) do
    json = decode!(json)
    payload = json[:payload]
    pid = json[:pid]
    Logger.info("sending event #{inspect(payload)} to #{inspect(pid)}")

    if is_pid(pid) do
      send(pid, payload)
    else
      Logger.error("Event contains invalid pid: #{inspect(json)}")
    end

    {:noreply, state}
  end

  def handle_info(
        {:tcp, _port, <<ref::unsigned-size(64), json::binary>>},
        state = %Bridge{requests: reqs}
      ) do
    {from, message} = reqs[ref]

    if json == "use_mock" do
      Bridge.Mock.send(Bridge.Mock, message)
      {:noreply, state}
    else
      if from, do: GenServer.reply(from, json)
      {:noreply, %Bridge{state | requests: Map.delete(reqs, ref)}}
    end
  end

  def handle_info({:tcp_error, socket, reason}, state = %Bridge{socket: socket}) do
    Logger.error("Bridge connection failed: #{inspect(reason)}")
    {:noreply, try_reconnect(state)}
  end

  def handle_info({:tcp_closed, socket}, state = %Bridge{socket: socket}) do
    Logger.error("Bridge connection closed")
    {:noreply, try_reconnect(state)}
  end

  def handle_info(other, state) do
    Logger.error("Bridge received unhandled info: #{inspect(other)}")
    {:noreply, state}
  end

  defp try_reconnect(state = %Bridge{port: port, lastURL: lastURL}) do
    Logger.error("Bridge try_reconnnect(#{port})")

    case :gen_tcp.connect({127, 0, 0, 1}, port, [packet: 4, active: true, mode: :binary], 1_000) do
      {:ok, socket} ->
        Logger.error("Bridge reconnect succeeded!")
        spawn(fn -> bridge_call(:wxWebView, :loadURL, [nil, lastURL]) end)
        %Bridge{state | socket: socket}

      {:error, err} ->
        Logger.error("Bridge reconnect failed: #{inspect(err)}")
        Process.sleep(1_000)
        try_reconnect(state)
    end
  end

  defmacro generate_bridge_calls(module, names) do
    names = names ++ [:new, :destroy, :connect, :getId]

    methods =
      for name <- names do
        """
          def #{name}(), do: Bridge.bridge_call(:#{module}, :#{name}, [])
          def #{name}(arg), do: Bridge.bridge_call(:#{module}, :#{name}, [arg])
          def #{name}(arg1, arg2), do: Bridge.bridge_call(:#{module}, :#{name}, [arg1, arg2])
          def #{name}(arg1, arg2, arg3), do: Bridge.bridge_call(:#{module}, :#{name}, [arg1, arg2, arg3])
          def #{name}(arg1, arg2, arg3, arg4), do: Bridge.bridge_call(:#{module}, :#{name}, [arg1, arg2, arg3, arg4])
          def #{name}(arg1, arg2, arg3, arg4, arg5), do: Bridge.bridge_call(:#{module}, :#{name}, [arg1, arg2, arg3, arg4, arg5])
          def #{name}(arg1, arg2, arg3, arg4, arg5, arg6), do: Bridge.bridge_call(:#{module}, :#{name}, [arg1, arg2, arg3, arg4, arg5, arg6])
          def #{name}(arg1, arg2, arg3, arg4, arg5, arg6, arg7), do: Bridge.bridge_call(:#{module}, :#{name}, [arg1, arg2, arg3, arg4, arg5, arg6, arg7])
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
