defmodule Bridge.Mock do
  def send(_pid, message) do
    handle_message(message, self())
  end

  def handle_message(<<ref::unsigned-size(64), json::binary>>, from) do
    response =
      case Bridge.decode!(json) do
        [:wx, :getObjectType, [arg]] ->
          Keyword.get(arg, :type)

        [:wxLocale | _] ->
          'en'

        [type, :new | args] ->
          [type: type, args: args]

        [:wxMenuBar, :getMenuCount | _] ->
          0

        [_module, method, _args] ->
          case Atom.to_string(method) do
            <<"is", _::binary>> -> true
            <<"set", _::binary>> -> true
            _other -> :ok
          end
      end

    reply = Bridge.encode!(response)
    Kernel.send(from, {:tcp, Bridge.Mock, <<ref::unsigned-size(64), reply::binary>>})
  end
end
