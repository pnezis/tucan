defmodule Tucan.AxesTest do
  use ExUnit.Case

  alias VegaLite, as: Vl

  describe "set_title and friends" do
    test "raises if the encoding does not exist" do
      vl = Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :horizontal)

      assert_raise ArgumentError, ~r"expects a single view", fn ->
        Tucan.Axes.set_x_title(vl, "title")
      end

      assert_raise ArgumentError, ~r"expects a single view", fn ->
        Tucan.Axes.set_y_title(vl, "title")
      end
    end

    test "sets the titles" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x")
        |> Vl.encode_field(:y, "y")
        |> Tucan.Axes.set_x_title("x title")
        |> Tucan.Axes.set_y_title("y title")

      assert get_in(vl.spec, ["encoding", "x", "axis", "title"]) == "x title"
      assert get_in(vl.spec, ["encoding", "y", "axis", "title"]) == "y title"
    end

    test "set_xy_titles" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x")
        |> Vl.encode_field(:y, "y")
        |> Tucan.Axes.set_xy_titles("x title", "y title")

      assert get_in(vl.spec, ["encoding", "x", "axis", "title"]) == "x title"
      assert get_in(vl.spec, ["encoding", "y", "axis", "title"]) == "y title"
    end
  end

  describe "put_options/3" do
    test "raises for multi view plots" do
      vl = Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :horizontal)

      assert_raise ArgumentError, ~r"expects a single view spec", fn ->
        Tucan.Axes.put_options(vl, :x, title: "hello")
      end
    end

    test "puts the given options if no axis is set" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Tucan.Axes.put_options(:x, title: "A title", foo: "bar", bar: 1)

      assert get_in(vl.spec, ["encoding", "x", "axis"]) == %{
               "bar" => 1,
               "foo" => "bar",
               "title" => "A title"
             }
    end

    test "deep merges the existing options with the new ones" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Tucan.Axes.put_options(:x, title: "A title", foo: "bar", bar: [a: 1, b: 2])
        |> Tucan.Axes.put_options(:x, title: "A new title", test: 2, bar: [a: 3, c: 2])

      assert get_in(vl.spec, ["encoding", "x", "axis"]) == %{
               "bar" => %{"a" => 3, "b" => 2, "c" => 2},
               "foo" => "bar",
               "test" => 2,
               "title" => "A new title"
             }
    end
  end

  describe "set_enabled/2" do
    test "disables both axes" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative, axis: [foo: 1])
        |> Vl.encode_field(:x, "y", type: :quantitative, axis: [foo: 1])
        |> Tucan.Axes.set_enabled(false)

      assert get_in(vl.spec, ["encoding", "x", "axis"]) == nil
      assert get_in(vl.spec, ["encoding", "y", "axis"]) == nil
    end
  end

  describe "set_enabled/3" do
    test "sets to nil an existing axis" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative, axis: [foo: 1])
        |> Tucan.Axes.set_enabled(:x, false)

      assert get_in(vl.spec, ["encoding", "x", "axis"]) == nil
    end

    test "re-enables a disabled axis" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative, axis: [foo: 1])
        |> Tucan.Axes.set_enabled(:x, false)
        |> Tucan.Axes.set_enabled(:x, true)

      assert get_in(vl.spec, ["encoding", "x", "axis"]) == []
    end
  end

  describe "set_orientation/3" do
    test "invalid arguments" do
      assert_raise ArgumentError,
                   "you can only set orientation for :x, :y axes, got: :color",
                   fn ->
                     Tucan.Axes.set_orientation(Vl.new(), :color, :left)
                   end

      assert_raise ArgumentError,
                   "you can only set :bottom or :top orientation for :x axis, got: :left",
                   fn ->
                     Tucan.Axes.set_orientation(Vl.new(), :x, :left)
                   end

      assert_raise ArgumentError,
                   "you can only set :left or :right orientation for :y axis, got: :bottom",
                   fn ->
                     Tucan.Axes.set_orientation(Vl.new(), :y, :bottom)
                   end
    end

    test "sets axes orientation" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative, axis: [foo: 1])
        |> Vl.encode_field(:y, "y", type: :quantitative, axis: [foo: 1])
        |> Tucan.Axes.set_orientation(:x, :top)
        |> Tucan.Axes.set_orientation(:y, :right)

      assert get_in(vl.spec, ["encoding", "x", "axis"]) == %{"foo" => 1, "orient" => "top"}
      assert get_in(vl.spec, ["encoding", "y", "axis"]) == %{"foo" => 1, "orient" => "right"}
    end
  end

  describe "set_offset/3" do
    test "raises if invalid axis" do
      assert_raise ArgumentError,
                   "invalid axis :z set in set_offset/3, only one of [:x, :y] is allowed",
                   fn ->
                     Tucan.Axes.set_offset(Vl.new(), :z, 10)
                   end
    end

    test "sets axes offset" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative, axis: [foo: 1])
        |> Vl.encode_field(:y, "y", type: :quantitative, axis: [foo: 1])
        |> Tucan.Axes.set_offset(:x, 10)
        |> Tucan.Axes.set_offset(:y, -10)

      assert get_in(vl.spec, ["encoding", "x", "axis"]) == %{"foo" => 1, "offset" => 10}
      assert get_in(vl.spec, ["encoding", "y", "axis"]) == %{"foo" => 1, "offset" => -10}
    end
  end

  describe "colors" do
    test "raises if invalid axis" do
      assert_raise ArgumentError,
                   "invalid axis :z set in set_color/3, only one of [:x, :y] is allowed",
                   fn ->
                     Tucan.Axes.set_color(Vl.new(), :z, "red")
                   end
    end

    test "sets axes colors" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative, axis: [foo: 1])
        |> Vl.encode_field(:y, "y", type: :quantitative, axis: [foo: 1])
        |> Tucan.Axes.set_color(:x, "red")
        |> Tucan.Axes.set_color(:y, "#fa2323")

      assert get_in(vl.spec, ["encoding", "x", "axis"]) == %{"foo" => 1, "domainColor" => "red"}

      assert get_in(vl.spec, ["encoding", "y", "axis"]) == %{
               "foo" => 1,
               "domainColor" => "#fa2323"
             }
    end

    test "set_color/2 sets both axes colors" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative, axis: [foo: 1])
        |> Vl.encode_field(:y, "y", type: :quantitative, axis: [foo: 1])
        |> Tucan.Axes.set_color("red")

      assert get_in(vl.spec, ["encoding", "x", "axis"]) == %{"foo" => 1, "domainColor" => "red"}

      assert get_in(vl.spec, ["encoding", "y", "axis"]) == %{"foo" => 1, "domainColor" => "red"}
    end

    test "set_title_color/3 raises with invalid axis" do
      assert_raise ArgumentError,
                   "invalid axis :z set in set_title_color/3, only one of [:x, :y] is allowed",
                   fn ->
                     Tucan.Axes.set_title_color(Vl.new(), :z, "red")
                   end
    end

    test "set_title_color/3 sets the title_color of the given axis" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x")
        |> Vl.encode_field(:y, "y")
        |> Tucan.Axes.set_title_color(:x, "red")
        |> Tucan.Axes.set_title_color(:y, "#FFCCEE")

      assert get_in(vl.spec, ["encoding", "x", "axis", "titleColor"]) == "red"
      assert get_in(vl.spec, ["encoding", "y", "axis", "titleColor"]) == "#FFCCEE"
    end
  end

  test "set_labels_enabled/3 sets the labels enabled of the given axis" do
    vl =
      Vl.new()
      |> Vl.encode_field(:x, "x")
      |> Vl.encode_field(:y, "y")
      |> Tucan.Axes.set_labels_enabled(:x, false)
      |> Tucan.Axes.set_labels_enabled(:y, false)

    assert get_in(vl.spec, ["encoding", "x", "axis", "labels"]) == false
    assert get_in(vl.spec, ["encoding", "y", "axis", "labels"]) == false
  end

  test "set_labels_angle/3 sets the label angle of the given axis" do
    vl =
      Vl.new()
      |> Vl.encode_field(:x, "x")
      |> Vl.encode_field(:y, "y")
      |> Tucan.Axes.set_labels_angle(:x, 45)

    assert get_in(vl.spec, ["encoding", "x", "axis", "labelAngle"]) == 45
  end
end
