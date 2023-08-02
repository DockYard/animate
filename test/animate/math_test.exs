defmodule Animate.MathTest do
  use ExUnit.Case
  doctest Animate.Math

  import Animate.Math

  test "mod" do
    assert mod(-2, 360) == 358.0
  end
end
