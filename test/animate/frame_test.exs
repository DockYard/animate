defmodule Animate.FrameTest do
  use ExUnit.Case
  doctest Animate.Frame

  alias Animate.Frame

  test "new" do
    renderer = fn(scene) -> scene end
    frame = Frame.new(1, 2, renderer)
    assert frame.data == 1
    assert frame.duration == 2
    assert frame.render.(true) == true
  end

  test "build" do
    frames = Frame.build(:linear, 0, 1, 1000, 1, {:linear, :in}, fn(s) -> s end)
    assert length(frames) == 2
    assert Enum.at(frames, 0).data == 0
    assert Enum.at(frames, 1).data == 1.0
    assert Enum.at(frames, 0).duration == 1000
    assert Enum.at(frames, 0).render.(123) == 123
  end

  describe "calculations" do
    test "raw" do
      assert Frame.calculate(:raw, 0, 1, 0.5) == 0.5
    end

    test "linear" do
      assert Frame.calculate(:linear, 0, 0.5, 0.5) == 0.25
    end

    # test "color ga" do
    #   data = Frame.calculate(:color, {:color_g, {0, 0.0}}, {:color_g, {10, 1.0}}, 0.25)
    #   assert data == {:color_g, {25, 0.25}}
    # end

    test "color g" do
      data = Frame.calculate(:color, {:color_g, 0}, {:color_g, 100}, 0.25)
      assert data == {:color_g, 25}
    end

    test "color rgb" do
      data = Frame.calculate(:color, {:color_rgb, {0, 100, 200}}, {:color_rgb, {100, 200, 10}}, 0.25)
      assert data == {:color_rgb, {2, 199, 200}}
    end

    # test "color rgba" do
    #   data = Frame.calculate(:color, {:color_rgb, {0, 100, 200, 0}}, {:color_rgb, {100, 200, 10, 1}}, 0.25)
    #   assert data == {:color_rgb, {25, 125, 42, 0.25}}
    # end

    test "color hsl" do

    end

    test "color hsv" do
      data = Frame.calculate(:color, {:color_hsv, {0, 50, 99}}, {:color_hsv, {100, 100, 10}}, 0.25)
      assert data == {:color_hsv, {25.0, 37.5, 1.75}}
    end

    test "text" do
      data = Frame.calculate(:text, "abc", "efg", 0.25)
      assert data == "bcd"
    end

    test "text with first is longer" do
      data = Frame.calculate(:text, "abcd", "efg", 0.25)
      assert data == "bcdS"
    end

    test "text with second is longer" do
      data = Frame.calculate(:text, "abc", "efgh", 0.25)
      assert data == "bcd2"
    end

    test "circular 358 to 3" do
      data = Frame.calculate(:circular, 358, 3, 0.25)
      assert data == 359.25
    end

    test "circular 3 to 358" do
      data = Frame.calculate(:circular, 3, 358, 0.25)
      assert data == 1.75
    end

    test "circular always finds shortest path" do
      data = Frame.calculate(:circular, 0, 181, 0.5)
      assert data == 270.5
      data = Frame.calculate(:circular, 0, 179, 0.5)
      assert data == 89.5
    end

    test "circular can take any max" do
      data = Frame.calculate(:circular, 10, 100, 0.5, 100)
      assert data == 5.0
    end
  end
end
