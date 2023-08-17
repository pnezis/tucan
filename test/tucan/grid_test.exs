defmodule Tucan.GridTest do
  use ExUnit.Case

  alias VegaLite, as: Vl

  test "all channel functions raise if channel is not encoded" do
    functions = [
      fn vl -> Tucan.Grid.set_color(vl, :x, "red") end,
      fn vl -> Tucan.Grid.set_dash_style(vl, :x, 2, 3) end,
      fn vl -> Tucan.Grid.set_enabled(vl, :x, true) end,
      fn vl -> Tucan.Grid.set_opacity(vl, :x, 0.1) end,
      fn vl -> Tucan.Grid.set_width(vl, :x, 1) end
    ]

    vl = Vl.new()

    for fun <- functions do
      assert_raise ArgumentError, fn -> fun.(vl) end
    end
  end

  describe "set_enabled/2" do
    test "with all axes defined" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x")
        |> Vl.encode_field(:y, "y")
        |> Tucan.Grid.set_enabled(false)

      assert_encoding_value(vl, :x, ["axis", "grid"], false)
      assert_encoding_value(vl, :y, ["axis", "grid"], false)
    end

    test "with no axis defined" do
      vl = Vl.new()

      assert Tucan.Grid.set_enabled(vl, false) == vl
    end

    test "with a single axis defined" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x")
        |> Tucan.Grid.set_enabled(false)

      assert_encoding_value(vl, :x, ["axis", "grid"], false)
      assert_encoding_value(vl, :y, ["axis", "grid"], nil)
    end
  end

  test "set_color/3" do
    vl =
      Vl.new()
      |> Vl.encode_field(:x, "x")
      |> Tucan.Grid.set_color(:x, "red")

    assert_encoding_value(vl, :x, ["axis", "gridColor"], "red")
  end

  test "set_enabled/3" do
    vl =
      Vl.new()
      |> Vl.encode_field(:x, "x")
      |> Tucan.Grid.set_enabled(:x, false)

    assert_encoding_value(vl, :x, ["axis", "grid"], false)
  end

  test "set_opacity/3" do
    vl =
      Vl.new()
      |> Vl.encode_field(:x, "x")
      |> Tucan.Grid.set_opacity(:x, 0.3)

    assert_encoding_value(vl, :x, ["axis", "gridOpacity"], 0.3)
  end

  test "set_width/3" do
    vl =
      Vl.new()
      |> Vl.encode_field(:x, "x")
      |> Tucan.Grid.set_width(:x, 3)

    assert_encoding_value(vl, :x, ["axis", "gridWidth"], 3)
  end

  test "set_dash_style/4" do
    vl =
      Vl.new()
      |> Vl.encode_field(:x, "x")
      |> Tucan.Grid.set_dash_style(:x, 3, 2)

    assert_encoding_value(vl, :x, ["axis", "gridDash"], [3, 2])
  end

  defp assert_encoding_value(vl, channel, key, value) when is_binary(key),
    do: assert_encoding_value(vl, channel, [key], value)

  defp assert_encoding_value(vl, channel, keys, value) do
    assert get_in(vl.spec, ["encoding", "#{channel}"] ++ keys) == value
  end
end
