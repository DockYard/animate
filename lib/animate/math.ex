defmodule Animate.Math do
  @doc """
  This custom mod function is necesary instead of using `Kernel.rem/2`
  because of how Erlang returns a value the same as the dividend.

  See: https://stackoverflow.com/a/7869457/366782
  """

  def mod(dividend, divisor) do
    dividend - Float.floor(dividend / divisor) * divisor
  end
end
