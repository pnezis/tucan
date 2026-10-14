defmodule Tucan.LegendTest do
  use ExUnit.Case

  alias VegaLite, as: Vl

  describe "set_title/4" do
    test "raises if the encoding is invalid" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x")

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

  describe "set_offset/3" do
    test "sets the legend offset" do
      vl =
        Vl.new()
        |> Vl.encode_field(:color, "x")
        |> Tucan.Legend.set_offset(:color, 5)

      assert get_in(vl.spec, ["encoding", "color", "legend", "offset"]) == 5
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
    test "raises if the encoding is invalid" do
      vl =
        Vl.new()
        |> Vl.encode_field(:shape, "x")

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
    test "raises if the encoding is invalid" do
      vl =
        Vl.new()
        |> Vl.encode_field(:shape, "x")

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

  describe "set_selectable/3" do
    @selection %{
      "name" => "_legend",
      "select" => %{"type" => "point", "fields" => ["c"]},
      "bind" => "legend"
    }

    @selection_opacity %{
      "condition" => %{"param" => "_legend", "value" => 1},
      "value" => 0.15
    }

    test "highlights the selected legend entries of a single view plot" do
      spec =
        Tucan.scatter("data.csv", "x", "y", color_by: "c")
        |> Tucan.Legend.set_selectable(:color)
        |> VegaLite.to_spec()

      assert spec["params"] == [@selection]
      assert spec["encoding"]["opacity"] == @selection_opacity
    end

    test "keeps the existing params" do
      spec =
        Tucan.scatter("data.csv", "x", "y", color_by: "c", zoomable: true)
        |> Tucan.Legend.set_selectable(:color)
        |> VegaLite.to_spec()

      assert [%{"name" => "_grid"}, @selection] = spec["params"]
    end

    test "highlights all layers with the legend field" do
      spec =
        Tucan.layers([
          Tucan.scatter("data.csv", "x", "y", shape_by: "c"),
          Tucan.lineplot("data.csv", "x", "y"),
          Tucan.scatter("data.csv", "x", "z", shape_by: "c", zoomable: true)
        ])
        |> Tucan.Legend.set_selectable(:shape, unselected_opacity: 0.3)
        |> VegaLite.to_spec()

      [first, second, third] = spec["layer"]
      opacity = %{@selection_opacity | "value" => 0.3}

      assert first["params"] == [@selection]
      assert first["encoding"]["opacity"] == opacity
      refute Map.has_key?(second, "params")
      refute Map.has_key?(second["encoding"], "opacity")
      assert [%{"name" => "_grid"}] = third["params"]
      assert third["encoding"]["opacity"] == opacity
    end

    test "raises without a legend field" do
      assert_raise ArgumentError, ~r/legend for the color channel/, fn ->
        Tucan.scatter("data.csv", "x", "y") |> Tucan.Legend.set_selectable(:color)
      end

      for opts <- [[invalid: 1], [unselected_opacity: 2]] do
        assert_raise NimbleOptions.ValidationError, fn ->
          Tucan.scatter("data.csv", "x", "y", color_by: "c")
          |> Tucan.Legend.set_selectable(:color, opts)
        end
      end
    end

    test "the marks of the selected entries are highlighted" do
      data = for {c, x} <- [{"a", 1}, {"b", 2}, {"a", 3}], do: %{c: c, x: x, y: x}

      svg =
        Tucan.scatter(data, "x", "y", color_by: "c")
        |> Tucan.Legend.set_selectable(:color)
        |> VegaLite.to_spec()
        # as if the user had clicked on the "a" entry of the legend
        |> update_in(["params", Access.at(0)], &Map.put(&1, "value", [%{"c" => "a"}]))
        |> Jason.encode!()
        |> VegaLite.from_json()
        |> Tucan.Export.to_svg()

      [symbols] = Regex.run(~r/class="mark-symbol role-mark.*?<\/g>/s, svg)

      opacities =
        Regex.scan(~r/aria-label="([^"]*)"[^>]*\sopacity="([^"]*)"/, symbols,
          capture: :all_but_first
        )

      assert opacities == [
               ["x: 1; y: 1; c: a", "1"],
               ["x: 2; y: 2; c: b", "0.15"],
               ["x: 3; y: 3; c: a", "1"]
             ]
    end
  end
end
