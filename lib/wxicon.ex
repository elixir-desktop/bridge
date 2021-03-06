defmodule :wxIcon do
  # credo:disable-for-next-line
  def copyFromBitmap(_icon, _bitmap), do: :ok

  def new(name \\ nil, options \\ nil) do
    [type: __MODULE__, args: [name, options]]
  end

  def destroy(_image), do: :ok
  # credo:disable-for-next-line
  def getHeight(_image), do: 1
  # credo:disable-for-next-line
  def getWidth(_image), do: 1
  def rescale(image, _width, _height, _options \\ nil), do: image
  # credo:disable-for-next-line
  def getAlpha(_image), do: <<>>
  # credo:disable-for-next-line
  def setAlpha(_image, _binary), do: :ok
  # credo:disable-for-next-line
  def getData(_image), do: <<>>
  # credo:disable-for-next-line
  def setData(_image, _binary), do: :ok
  def replace(_image, _r1, _g1, _b1, _r2, _g2, _b2), do: :ok
end
