defmodule Tucan.InteractiveTest do
  use ExUnit.Case

  @dataset "dataset.csv"

  describe "brush/2" do
    @brush %{"name" => "_brush", "select" => %{"type" => "interval", "encodings" => ["x", "y"]}}
    @brush_opacity %{"condition" => %{"param" => "_brush", "value" => 1}, "value" => 0.15}

    test "adds a linked brush to the plots of a concatenated plot" do
      spec =
        Tucan.hconcat([
          Tucan.scatter(@dataset, "x", "y"),
          Tucan.scatter(@dataset, "a", "b", color_by: "c")
        ])
        |> Tucan.Interactive.brush()
        |> VegaLite.to_spec()

      for view <- spec["hconcat"] do
        assert view["params"] == [@brush]
        assert view["encoding"]["opacity"] == @brush_opacity
      end

      # existing encodings are kept
      assert get_in(Enum.at(spec["hconcat"], 1), ["encoding", "color", "field"]) == "c"
    end

    test "brushes only the continuous axes of views drawing individual rows" do
      spec =
        Tucan.vconcat([
          Tucan.stripplot(@dataset, "x", group_by: "g", style: :jitter),
          Tucan.histogram(@dataset, "x"),
          Tucan.density(@dataset, "x"),
          Tucan.bar(@dataset, "a", "b"),
          Tucan.layers([Tucan.scatter(@dataset, "x", "y")])
        ])
        |> Tucan.Interactive.brush(unselected_opacity: 0.3)
        |> VegaLite.to_spec()

      [strip, histogram, density, bar, layered] = spec["vconcat"]

      assert strip["params"] == [put_in(@brush, ["select", "encodings"], ["x"])]
      assert strip["encoding"]["opacity"] == put_in(@brush_opacity, ["value"], 0.3)

      # aggregated views and layered views are not affected
      for view <- [histogram, density, layered] do
        refute Map.has_key?(view, "params")
        refute Map.has_key?(view["encoding"] || %{}, "opacity")
      end

      # the bars of individual rows are brushed on their continuous y-axis
      assert bar["params"] == [put_in(@brush, ["select", "encodings"], ["y"])]
      assert bar["encoding"]["opacity"] == put_in(@brush_opacity, ["value"], 0.3)
    end

    test "views without continuous axes are highlighted but they cannot be brushed" do
      spec =
        Tucan.concat([
          Tucan.scatter(@dataset, "x", "y", x: [type: :nominal], y: [type: :ordinal])
        ])
        |> Tucan.Interactive.brush()
        |> VegaLite.to_spec()

      view = hd(spec["concat"])
      refute Map.has_key?(view, "params")
      assert view["encoding"]["opacity"] == @brush_opacity
    end

    test "appends the brush to existing params" do
      spec =
        Tucan.concat([Tucan.scatter(@dataset, "x", "y", zoomable: true)])
        |> Tucan.Interactive.brush()
        |> VegaLite.to_spec()

      assert [%{"name" => "_grid"}, @brush] = hd(spec["concat"])["params"]
    end

    test "raises for plots that are not concatenated" do
      assert_raise ArgumentError, ~r/expects a concatenated plot/, fn ->
        Tucan.Interactive.brush(Tucan.scatter(@dataset, "x", "y"))
      end
    end

    test "the rows selected in one plot are highlighted in all plots" do
      data = for i <- 1..6, do: %{x: i, y: i * 10, a: 7 - i, b: rem(i, 3)}

      vl =
        Tucan.hconcat([Tucan.scatter(data, "x", "y"), Tucan.scatter(data, "a", "b")])
        |> Tucan.Interactive.brush()

      # a brush on the first plot selecting the rows with x in [1.5, 3.5]
      [first, second] = render_with_brush(vl, 0, %{"x" => [1.5, 3.5], "y" => [0, 100]})

      assert selected(first) == ["x: 2; y: 20", "x: 3; y: 30"]
      assert selected(second) == ["a: 5; b: 2", "a: 4; b: 0"]
    end
  end

  # renders the plot with the brush of the given view set to the given intervals and
  # returns the marks of each view with their opacity. All views share the same
  # brush, whose initial value is taken from the first view defining it.
  defp render_with_brush(vl, view, value) do
    spec = VegaLite.to_spec(vl)
    [key] = Enum.filter(["concat", "hconcat", "vconcat"], &Map.has_key?(spec, &1))

    svg =
      spec
      |> update_in([key, Access.at(view), "params"], fn params ->
        Enum.map(params, &Map.put(&1, "value", value))
      end)
      |> Jason.encode!()
      |> VegaLite.from_json()
      |> Tucan.Export.to_svg()

    ~r/class="mark-symbol.*?<\/g>/s
    |> Regex.scan(svg)
    |> Enum.map(fn [group] ->
      Regex.scan(~r/aria-label="([^"]*)"[^>]*\sopacity="([^"]*)"/, group, capture: :all_but_first)
    end)
  end

  defp selected(marks), do: for([label, "1"] <- marks, do: label)
end
