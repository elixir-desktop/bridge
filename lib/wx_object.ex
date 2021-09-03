defmodule :wx_object do
  use GenServer
  defstruct frame: nil, state: nil, module: nil

  def start_link(name, module, args, _flags \\ []) do
    name =
      case name do
        {:local, name} -> name
        name -> name
      end

    {:ok, pid} = GenServer.start_link(__MODULE__, {module, args}, name: name)
    {:ref, 0, __MODULE__, pid}
  end

  @impl true
  def init({module, args}) do
    {frame, state} = module.init(args)
    {:ok, %:wx_object{frame: frame, state: state, module: module}}
  end

  @impl true
  def handle_info(message, s = %:wx_object{state: state, module: module}) do
    case module.handle_info(message, state) do
      {:noreply, new_state} -> {:noreply, %{s | state: new_state}}
      other -> other
    end
  end

  @impl true
  def handle_cast(message, s = %:wx_object{state: state, module: module}) do
    case module.handle_cast(message, state) do
      {:noreply, new_state} -> {:noreply, %{s | state: new_state}}
      other -> other
    end
  end

  @impl true
  def handle_call(message, from, s = %:wx_object{state: state, module: module}) do
    case module.handle_call(message, from, state) do
      {:noreply, new_state} -> {:noreply, %{s | state: new_state}}
      {:reply, reply, new_state} -> {:reply, reply, %{s | state: new_state}}
      other -> other
    end
  end
end
