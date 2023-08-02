defmodule Animate do
  @fps 60
  @timing Kernel.trunc(1_000 / @fps)
  @queus_key :__animate_queues__
  @animate_reference_key :__animate_reference__

  @callback render(any()) :: any()

  defmacro __using__(opts) do
    quote do
      @behaviour Animate

      def state_handler(state, type, key, default \\ nil)
      def state_handler(state, :get, key, default), do: unquote(opts[:get]).(state, key, default)
      def state_handler(state, :assign, key, value), do: unquote(opts[:assign]).(state, key, value)

      def handle_info({:animate_push, id, frames_builder, type}, state) do
        queues =
          state
          |> state_handler(:get, unquote(@queus_key), [])
          |> Animate.update_queues(id, frames_builder, type)

        state = state_handler(state, :assign, unquote(@queus_key), queues)

        state =
          state
          |> state_handler(:get, unquote(@animate_reference_key))
          |> case do
            nil ->
              Process.send(self(), :animate, [])
              state_handler(state, :assign, unquote(@animate_reference_key), :ok)
            _ -> state
            end

        {:noreply, state}
      end

      def handle_info(:animate, state) do
        frame_queues = state_handler(state, :get, unquote(@queus_key), [])

        {:noreply, Animate.process_queues(state, frame_queues, unquote(@timing), &state_handler/4, &render/1)}
      end
    end
  end

  def update_queues(queues, id, frames_builder, :append) do
    Enum.reduce(queues, {false, []}, fn
      {^id, frames}, {false, queues} ->
        frames = List.insert_at(frames, -1, frames_builder)
        queues = List.insert_at(queues, -1, frames)
        {true, queues}
      frames_queue, {bool, queues} -> {bool, List.insert_at(queues, -1, frames_queue)}
    end)
    |> case do
      {false, queues} -> List.insert_at(queues, -1, {id, [frames_builder]})
      _ -> queues
    end
  end

  def frame_time(_state), do: @frame_time

  def process_queues(state, [], _timing, _state_handler, _render), do: state
  def process_queues(state, queues, timing, state_handler, render) do
    {state, queues} = Enum.reduce(queues, {state, []}, &pop_frame_from_queue(&1, &2, timing, state_handler))

    state = render.(state)

    schedule_next(state, queues, timing, state_handler)
  end

  defp pop_frame_from_queue({_id, []}, {state, queues}, _timing, _state_handler), do: {state, queues}
  defp pop_frame_from_queue({id, [frame_builder | frames]}, {state, queues}, timing, state_handler) when is_function(frame_builder) do
    new_frames =
      state
      |> state_handler.(:get, id, nil)
      |> frame_builder.()

    pop_frame_from_queue({id, new_frames ++ frames}, {state, queues}, timing, state_handler)
  end
  defp pop_frame_from_queue({id, [%Animate.Frame{duration: duration} = frame | frames]}, {state, queues}, timing, _state_handler) when duration > timing do
    frame = struct(frame, duration: frame.duration - timing)
    {state, [{id, [frame | frames]} | queues]}
  end
  defp pop_frame_from_queue({id, [%Animate.Frame{duration: duration} = frame, next_frame | frames]}, {state, queues}, timing, state_handler) when duration < 0 do
    next_frame = struct(next_frame, duration: next_frame.duration + frame.duration)
    frame = struct(frame, duration: 0)
    pop_frame_from_queue({id, [frame, next_frame | frames]}, {state, queues}, timing, state_handler)
  end
  defp pop_frame_from_queue({id, [frame | frames]}, {state, queues}, _timing, state_handler) do
    {process_frame(state, {id, frame}, state_handler), List.insert_at(queues, -1, {id, frames})}
  end

  def process_frame(state, {id, frame}, state_handler) do
    state_handler.(state, :assign, id, frame.data)
  end

  defp schedule_next(state, [] = queues, _timing, state_handler) do
    state
    |> state_handler.(:assign, @animate_reference_key, nil)
    |> state_handler.(:assign, @queus_key, queues)
  end

  defp schedule_next(state, queues, timing, state_handler) do
    reference = Process.send_after(self(), :animate, timing)

    state
    |> state_handler.(:assign, @animate_reference_key, reference)
    |> state_handler.(:assign, @queus_key, queues)
  end

  def push(state, id, shape, duration, easing) do
    push(state, id, shape, duration, easing, :append)
  end

  def push(state, id, shape, duration, easing, type) when is_number(duration) do
    push(state, id, shape, {duration, @fps}, easing, type)
  end

  def push(state, id, last, timing, easing, type) when is_number(last) do
    push(state, id, {:linear, last}, timing, easing, type)
  end

  def push(state, id, {shape, last}, {duration, framerate}, easing, type) do
    frames_builder = &Animate.Frame.build(shape, &1, last, duration, framerate, easing)

    Process.send(self(), {:animate_push, id, frames_builder, type}, [])

    state
  end
end
