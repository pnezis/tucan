defmodule Tucan.AxesTest do
  use ExUnit.Case

  alias VegaLite, as: Vl

  describe "set_title and friends" do
    test "raises if the encoding does not exist" do
      vl = Vl.new()

      assert_raise ArgumentError, "encoding for channel :x not found in the spec", fn ->
        Tucan.Axes.set_x_title(vl, "title")
      end

      assert_raise ArgumentError, "encoding for channel :y not found in the spec", fn ->
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
    test "raises if encoding does not exist" do
      vl = Vl.new()

      assert_raise ArgumentError, "encoding for channel :x not found in the spec", fn ->
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
end
