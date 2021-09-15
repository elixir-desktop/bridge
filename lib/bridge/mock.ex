defmodule Bridge.Mock do
  @moduledoc """
    Mock implementation of some wxWidgets calls used as defaults fallbacks
    so that even without any implementation on the Bridge side the application runs
    without crashing
  """
  def send(_pid, message) do
    handle_message(message, self())
  end

  def handle_message(<<ref::unsigned-size(64), json::binary>>, from) do
    response = handle_method(Bridge.decode!(json))
    reply = Bridge.encode!(response)
    Kernel.send(from, {:tcp, Bridge.Mock, <<ref::unsigned-size(64), reply::binary>>})
  end

  def handle_method([:wx, :getObjectType, [arg]]), do: Keyword.get(arg, :type)
  def handle_method([:wxLocale | _]), do: 'en'
  def handle_method([type, :new | args]), do: [type: type, args: args]
  def handle_method([:wxMenuBar, :getMenuCount | _]), do: 0
  def handle_method([:wxImage, :getAlpha | _]), do: <<>>
  def handle_method([:wxImage, :getData | _]), do: <<>>

  def handle_method([_module, method | _]) do
    case Atom.to_string(method) do
      <<"is", _::binary>> -> true
      <<"set", _::binary>> -> true
      _other -> :ok
    end
  end
end
