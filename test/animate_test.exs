defmodule AnimateTest do
  use ExUnit.Case
  doctest Animate

  defmodule TestState do
    use Animate, get: &get/3, assign: &assign/3

    defstruct assigns: %{}, rendered: false

    def get(state, key, default \\ nil) do
      Map.get(state, :assigns)
      |> Map.get(key, default)
    end

    def assign(state, key, value) do
      assigns =
        Map.get(state, :assigns)
        |> Map.put(key, value)

      Map.put(state, :assigns, assigns)
    end
  end

  test "README install version check" do
    app = :animate

    app_version = "#{Application.spec(app, :vsn)}"
    readme = File.read!("README.md")
    [_, readme_versions] = Regex.run(~r/{:#{app}, "(.+)"}/, readme)

    assert Version.match?(app_version, readme_versions),
           """
           Install version constraint in README.md does not match to current app version.
           Current App Version: #{app_version}
           Readme Install Versions: #{readme_versions}
           """
  end

  describe "processing queue" do
    test "when queue is empty" do
      state = %TestState{}

      new_state = Animate.process_queues(state, [], 16, &TestState.state_handler/4)

      assert state == new_state
    end
  end

  # describe "push" do
  #   test "no type passed, default to :concurrent" do
  #     Animate.push(%TestState{}, :foobar, {:linear, 1}, {1_000, 1}, {:sine, :out}, fn(state) -> state end)

  #     assert_receive {:animate_push, :foobar, frame_builder}
  #     [frame_1, frame_2] = frame_builder.(0)
  #     assert frame_1.data == 0.0
  #     assert frame_1.duration == 1_000
  #     assert frame_2.data == 1.0
  #     assert frame_2.duration == 1_000
  #   end

  #   test "if only duration is passed and no framerate default to 60fps" do
  #     Animate.push(%TestState{}, :foobar, {:linear, 1}, 16*3, {:sine, :out}, fn(state) -> state end, :concurrent)

  #     assert_receive {:animate_push, :foobar, frame_builder}
  #     frames = frame_builder.(0)
  #     assert length(frames) == 4
  #     frame_1 = Enum.at(frames, 0)
  #     assert frame_1.data == 0.0
  #     assert frame_1.duration == 16
  #     frame_2 = Enum.at(frames, -1)
  #     assert frame_2.data == 1.0
  #     assert frame_2.duration == 16
  #   end

  #   test "if no shape of the easing is passed assume :linear" do
  #     Animate.push(%TestState{}, :foobar, 1, {1_000, 1}, {:sine, :out}, fn(state) -> state end, :concurrent)

  #     assert_receive {:animate_push, :foobar, frame_builder}
  #     [frame_1, frame_2] = frame_builder.(0)
  #     assert frame_1.data == 0.0
  #     assert frame_1.duration == 1_000
  #     assert frame_2.data == 1.0
  #     assert frame_2.duration == 1_000
  #   end

  #   test "will push the animation frames into the queue to process" do
  #     Animate.push(%TestState{}, :foobar, {:linear, 1}, {1_000, 1}, {:sine, :out}, fn(state) -> state end, :concurrent)

  #     assert_receive {:animate_push, :foobar, frame_builder}
  #     [frame_1, frame_2] = frame_builder.(0)
  #     assert frame_1.data == 0.0
  #     assert frame_1.duration == 1_000
  #     assert frame_2.data == 1.0
  #     assert frame_2.duration == 1_000
  #   end
  # end

  # describe "module integration" do
  #   setup do
  #     state = %TestState{assigns: %{foobar: 1}}
  #     renderer = fn(state) -> struct(state, rendered: true) end
  #     [
  #       state: state,
  #       renderer: renderer,
  #       frame_builder: &Animate.Frame.build(:raw, &1, 1, 1_000, 60, {:linear, :in}, renderer)
  #     ]
  #   end

  #   test "handle_info with a framebuilder", context do
  #     {:noreply, state} = TestState.handle_info({:animate, :foobar, context.frame_builder}, context.state)
  #     assert state.rendered
  #   end

  #   test "handle_info with empty frames", context do
  #     {:noreply, state} = TestState.handle_info({:animate, :foobar, []}, context.state)
  #     refute state.rendered
  #   end

  #   test "handle_info with frames", context do
  #     first = context.state.assigns.foobar
  #     {:noreply, state} = TestState.handle_info({:animate, :foobar, context.frame_builder.(first)}, context.state)
  #     assert state.rendered
  #   end
  # end
end
