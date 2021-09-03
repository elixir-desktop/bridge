defmodule :wxe_util do
  def get_const(const) do
    case const do
      # Fake wxWidgets version 13.5.5 to turn on all feature detection
      :wxMAJOR_VERSION -> 13
      :wxMINOR_VERSION -> 5
      :wxRELEASE_NUMBER -> 5
      other -> other
    end
  end
end
