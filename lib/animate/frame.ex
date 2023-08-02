defmodule Animate.Frame do
  import Animate.Math

  defstruct data: nil, duration: nil

  def build(shape, nil, last, duration, framerate, easing) do
    build(shape, last, last, duration, framerate, easing)
  end

  def build(shape, first, last, duration, framerate, easing) do
    frame_duration = Kernel.trunc(1_000 / framerate)

    Easing.Range.calculate(duration, framerate)
    |> Easing.stream(easing)
    |> Stream.map(&calculate(shape, first, last, &1))
    |> Stream.map(&new(&1, frame_duration))
    |> Enum.to_list()
  end

  def new(data, duration), do: %__MODULE__{data: data, duration: duration}

  def calculate(:raw, _first, _last, percentage), do: percentage
  def calculate(:linear, first, last, percentage) do
    first + (last - first) * percentage
  end

  def calculate(:color, first, last, percentage) do
    calculate_color(first, last, percentage)
  end

  def calculate(:text, first, last, percentage) do
    calculate_text(String.to_charlist(first), String.to_charlist(last), percentage)
    |> List.to_string()
  end

  def calculate(:circular, first, last, percentage, max \\ 360) do
    half = Kernel.trunc(max / 2)
    first + (mod(last - first + half, max) - half) * percentage
    |> case do
      value when value < 0 -> max + value
      value when value > max -> value - max
      value -> value
    end
  end

  defp calculate_color({:color_g, {_first_gray, _first_alpha}} = first_gray, {:color_g, {_last_gray, _last_alpha}} = last_gray, percentage) do
    calculate_color(Scenic.Color.to_hsv(first_gray), Scenic.Color.to_hsv(last_gray), percentage)
    |> Scenic.Color.to_ga()
  end
  defp calculate_color({:color_g, first_gray}, {:color_g, last_gray}, percentage) do
    calculate_color(Scenic.Color.to_hsv(first_gray), Scenic.Color.to_hsv(last_gray), percentage)
    |> Scenic.Color.to_g()
  end
  defp calculate_color({:color_rgb, _first_rgb} = first_rgb, {:color_rgb, _last_rgb} = last_rgb, percentage) do
    calculate_color(Scenic.Color.to_hsv(first_rgb), Scenic.Color.to_hsv(last_rgb), percentage)
    |> Scenic.Color.to_rgb()
  end
  defp calculate_color({:color_rgba, _first_rgba} = first_rgba, {:color_rgba, _last_rgba} = last_rgba, percentage) do
    calculate_color(Scenic.Color.to_hsv(first_rgba), Scenic.Color.to_hsv(last_rgba), percentage)
    |> Scenic.Color.to_rgba()
  end
  defp calculate_color({:color_hsl, {_first_hue, _first_saturation, _first_lightness}} = first_hsl, {:color_hsl, {_last_hue, _last_saturation, _last_lightness}} = last_hsl, percentage) do
    calculate_color(Scenic.Color.to_hsv(first_hsl), Scenic.Color.to_hsv(last_hsl), percentage)
    |> Scenic.Color.to_hsl()
  end
  defp calculate_color({:color_hsv, {first_hue, first_saturation, first_value}}, {:color_hsv, {last_hue, last_saturation, last_value}}, percentage) do
    hue = calculate(:circular, first_hue, last_hue, percentage, 360)
    saturation = calculate(:circular, first_saturation, last_saturation, percentage, 100)
    value = calculate(:circular, first_value, last_value, percentage, 100)

    {:color_hsv, {hue, saturation, value}}
  end

  defp calculate_text(first, last, percentage), do: calculate_text(first, last, percentage, [])

  defp calculate_text([], [], _percentage, acc), do: acc
  defp calculate_text([first | first_text], [], percentage, acc) do
    [calculate(:linear, first, ?\s, percentage) |> Kernel.trunc() | calculate_text(first_text, [], percentage, acc)]
  end
  defp calculate_text([], [last | last_text], percentage, acc) do
    [calculate(:linear, ?\s, last, percentage) |> Kernel.trunc() | calculate_text([], last_text, percentage, acc)]
  end
  defp calculate_text([first | first_text], [last | last_text], percentage, acc) do
    [calculate(:linear, first, last, percentage) |> Kernel.trunc() | calculate_text(first_text, last_text, percentage, acc)]
  end
end
