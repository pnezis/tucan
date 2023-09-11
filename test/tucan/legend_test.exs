defmodule Tucan.LegendTest do
  use ExUnit.Case

  alias VegaLite, as: Vl

  describe "set_title/4" do
    test "raises if the encoding does not exist or is invalid" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x")

      assert_raise ArgumentError, "encoding for channel :color not found in the spec", fn ->
        Tucan.Legend.set_title(vl, :color, "title")
      end

      assert_raise ArgumentError,
                   "set_title/4: invalid legend channel, allowed: [:color, :size, :shape], got: :x",
                   fn ->
                     Tucan.Legend.set_title(vl, :x, "title")
                   end
    end

    test "sets the titles" do
      vl =
        Vl.new()
        |> Vl.encode_field(:color, "x")
        |> Vl.encode_field(:shape, "x")
        |> Tucan.Legend.set_title(:color, "color title")
        |> Tucan.Legend.set_title(:shape, "shape title", foo: 1)

      assert get_in(vl.spec, ["encoding", "color", "legend", "title"]) == "color title"

      assert get_in(vl.spec, ["encoding", "shape", "legend"]) == %{
               "foo" => 1,
               "title" => "shape title"
             }
    end
  end

  describe "set_enabled/3" do
    test "disables the legend" do
      vl =
        Vl.new()
        |> Vl.encode_field(:color, "x")
        |> Vl.encode_field(:shape, "x")
        |> Tucan.Legend.set_enabled(:color, false)
        |> Tucan.Legend.set_enabled(:shape, true)

      assert Map.has_key?(vl.spec["encoding"]["color"], "legend")
      assert get_in(vl.spec, ["encoding", "color", "legend"]) == nil

      refute Map.has_key?(vl.spec["encoding"]["shape"], "legend")
    end
  end

  describe "set_orientation/4" do
    test "raises if the encoding does not exist or is invalid" do
      vl =
        Vl.new()
        |> Vl.encode_field(:shape, "x")

      assert_raise ArgumentError, "encoding for channel :color not found in the spec", fn ->
        Tucan.Legend.set_orientation(vl, :color, "bottom")
      end

      assert_raise ArgumentError,
                   "set_orientation/3: invalid legend channel, allowed: [:color, :size, :shape], got: :x",
                   fn ->
                     Tucan.Legend.set_orientation(vl, :x, "bottom")
                   end

      message = """
      invalid legend orientation, allowed: ["left", "right", "top", "bottom", "top-left", \
      "top-right", "bottom-left", "bottom-right", "none"], got: "other"\
      """

      assert_raise ArgumentError,
                   message,
                   fn ->
                     Tucan.Legend.set_orientation(vl, :color, "other")
                   end
    end

    test "sets the orientation" do
      vl =
        Vl.new()
        |> Vl.encode_field(:color, "x")
        |> Vl.encode_field(:shape, "x")
        |> Tucan.Legend.set_orientation(:color, "top")
        |> Tucan.Legend.set_orientation(:shape, "bottom")

      assert get_in(vl.spec, ["encoding", "color", "legend", "orient"]) == "top"
      assert get_in(vl.spec, ["encoding", "shape", "legend", "orient"]) == "bottom"
    end
  end

  describe "put_options/3" do
    test "raises if the encoding does not exist or is invalid" do
      vl =
        Vl.new()
        |> Vl.encode_field(:shape, "x")

      assert_raise ArgumentError, "encoding for channel :color not found in the spec", fn ->
        Tucan.Legend.put_options(vl, :color, foo: 1)
      end

      assert_raise ArgumentError,
                   "put_legend_options/3: invalid legend channel, allowed: [:color, :size, :shape], got: :x",
                   fn ->
                     Tucan.Legend.put_options(vl, :x, foo: 1)
                   end
    end

    test "puts arbitrary options" do
      vl =
        Vl.new()
        |> Vl.encode_field(:color, "x", legend: [bar: 0])
        |> Tucan.Legend.put_options(:color, foo: 1)

      assert get_in(vl.spec, ["encoding", "color", "legend"]) == %{"bar" => 0, "foo" => 1}
    end
  end
end
