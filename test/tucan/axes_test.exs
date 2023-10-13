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
end
