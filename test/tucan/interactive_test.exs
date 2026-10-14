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

  describe "crosshair/2" do
    test "adds a rule and points at the nearest x value" do
      spec =
        Tucan.lineplot(@dataset, "x", "y", color_by: "c")
        |> Tucan.Interactive.crosshair()
        |> VegaLite.to_spec()

      refute Map.has_key?(spec, "mark")
      assert spec["data"] == %{"url" => @dataset}

      x = %{"field" => "x", "type" => "quantitative"}
      y = %{"field" => "y", "type" => "quantitative"}
      color = %{"field" => "c"}

      highlighted = %{
        "condition" => %{"param" => "_hover", "empty" => false, "value" => 1},
        "value" => 0
      }

      assert [line, selector, rule, points] = spec["layer"]

      assert line == %{
               "mark" => %{"type" => "line", "fillOpacity" => 1},
               "encoding" => %{"x" => x, "y" => y, "color" => color}
             }

      assert selector == %{
               "params" => [
                 %{
                   "name" => "_hover",
                   "select" => %{
                     "type" => "point",
                     "fields" => ["x"],
                     "nearest" => true,
                     "on" => "pointerover",
                     "clear" => "pointerout"
                   }
                 }
               ],
               "mark" => %{"type" => "point", "opacity" => 0},
               "encoding" => %{"x" => x}
             }

      assert rule == %{
               "mark" => %{"type" => "rule", "color" => "gray"},
               "encoding" => %{"x" => x, "opacity" => highlighted}
             }

      assert points == %{
               "mark" => %{"type" => "point", "filled" => true, "size" => 50},
               "encoding" => %{
                 "x" => x,
                 "y" => y,
                 "color" => color,
                 "opacity" => highlighted,
                 "tooltip" => [x, y, color]
               }
             }
    end

    test "with options and without colors" do
      spec =
        Tucan.area(@dataset, "x", "y")
        |> Tucan.Interactive.crosshair(rule_color: "red", point_size: 20)
        |> VegaLite.to_spec()

      [_area, _selector, rule, points] = spec["layer"]

      assert rule["mark"]["color"] == "red"
      assert points["mark"]["size"] == 20
      refute Map.has_key?(points["encoding"], "color")
    end

    test "raises for invalid plots" do
      assert_raise ArgumentError, ~r/x encoding/, fn ->
        Tucan.Interactive.crosshair(Tucan.new())
      end

      assert_raise ArgumentError, ~r/y encoding/, fn ->
        Tucan.new() |> VegaLite.encode_field(:x, "x") |> Tucan.Interactive.crosshair()
      end

      assert_raise ArgumentError, fn ->
        Tucan.layers([Tucan.lineplot(@dataset, "x", "y")]) |> Tucan.Interactive.crosshair()
      end
    end

    test "keeps the zoom of zoomable plots in the layer of the marks" do
      spec =
        Tucan.lineplot(@dataset, "x", "y", zoomable: true)
        |> Tucan.Interactive.crosshair()
        |> VegaLite.to_spec()

      refute Map.has_key?(spec, "params")
      assert [line, selector, _rule, _points] = spec["layer"]
      assert [%{"name" => "_grid"}] = line["params"]
      assert [%{"name" => "_hover"}] = selector["params"]
    end

    test "highlights the points of all series at the hovered x value" do
      data =
        for x <- 1..5, series <- ["a", "b"] do
          %{x: x, y: if(series == "a", do: x, else: 10 - x), series: series}
        end

      svg =
        Tucan.lineplot(data, "x", "y", color_by: "series")
        |> Tucan.Interactive.crosshair()
        |> render_with_param("_hover", [%{"x" => 3}])

      [rules] = Regex.run(~r/class="mark-rule role-mark.*?<\/g>/s, svg)
      [points] = Regex.run(~r/class="mark-symbol[^"]*layer_3.*?<\/g>/s, svg)

      # the visible rules, one per row at x = 3, are drawn at the same position
      positions =
        for [x, "1"] <-
              Regex.scan(~r/translate\(([^,]+),[^"]*"[^>]*\sopacity="([^"]*)"/, rules,
                capture: :all_but_first
              ),
            uniq: true,
            do: x

      assert length(positions) == 1

      # the points of both series at x = 3 are highlighted
      assert visible(points) == ["x: 3; y: 3; series: a", "x: 3; y: 7; series: b"]
    end
  end

  describe "slider/3" do
    test "filters the rows equal to the selected value" do
      spec =
        Tucan.scatter(@dataset, "x", "y")
        |> VegaLite.transform(filter: "datum.x > 0")
        |> Tucan.Interactive.slider("year", min: 1955, max: 2005, step: 5)
        |> VegaLite.to_spec()

      assert spec["params"] == [
               %{
                 "name" => "slider_year",
                 "value" => 1955,
                 "bind" => %{
                   "input" => "range",
                   "min" => 1955,
                   "max" => 2005,
                   "step" => 5,
                   "name" => "year "
                 }
               }
             ]

      assert spec["transform"] == [
               %{"filter" => ~s'datum["year"] == slider_year'},
               %{"filter" => "datum.x > 0"}
             ]
    end

    test "infers the range from inline data" do
      data = [%{"a b" => 3}, %{"a b" => 1}, %{"a b" => nil}, %{"a b" => 7}]

      spec =
        Tucan.lineplot(data, "a b", "a b")
        |> Tucan.Interactive.slider("a b", mode: :up_to, value: 5, label: "Value", step: 0.5)
        |> VegaLite.to_spec()

      assert [
               %{
                 "name" => "slider_a_b",
                 "value" => 5,
                 "bind" => %{"min" => 1, "max" => 7, "step" => 0.5, "name" => "Value "}
               }
             ] = spec["params"]

      assert spec["transform"] == [%{"filter" => ~s'datum["a b"] <= slider_a_b'}]

      assert [%{"bind" => %{"min" => 0, "max" => 7}}] =
               Tucan.lineplot(data, "a b", "a b")
               |> Tucan.Interactive.slider("a b", min: 0)
               |> VegaLite.to_spec()
               |> Map.fetch!("params")

      assert [%{"value" => 1, "bind" => %{"min" => 1, "max" => 7, "step" => 1}}] =
               Tucan.lineplot(data, "a b", "a b")
               |> Tucan.Interactive.slider("a b")
               |> VegaLite.to_spec()
               |> Map.fetch!("params")
    end

    test "raises if the range cannot be inferred" do
      message = ~s'cannot infer the range of "year", set the :min and :max options'

      assert_raise ArgumentError, message, fn ->
        Tucan.scatter(@dataset, "x", "y") |> Tucan.Interactive.slider("year", min: 1)
      end
    end

    test "the plot shows only the rows of the selected value" do
      data = for x <- 1..5, do: %{x: x, y: x * x}

      drawn = fn opts ->
        Tucan.scatter(data, "x", "y")
        |> Tucan.Interactive.slider("x", opts)
        |> Tucan.Export.to_svg()
        |> marks()
      end

      assert drawn.(value: 3) == ["x: 3; y: 9"]
      assert drawn.(value: 3, mode: :up_to) == ["x: 1; y: 1", "x: 2; y: 4", "x: 3; y: 9"]
      assert drawn.([]) == ["x: 1; y: 1"]
    end

    test "aggregations are computed on the filtered rows" do
      data = for year <- [2020, 2021], value <- 1..(year - 2017), do: %{year: year, v: value}

      counts = fn year ->
        Tucan.histogram(data, "v", maxbins: 10)
        |> Tucan.Interactive.slider("year", value: year)
        |> Tucan.Export.to_svg()
        |> marks()
        |> length()
      end

      # one bar per distinct value, 3 values in 2020 and 4 in 2021
      assert counts.(2020) == 3
      assert counts.(2021) == 4
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

  # renders the plot with the value of every param with the given name set, as if the
  # user had interacted with the plot
  defp render_with_param(vl, name, value) do
    vl
    |> VegaLite.to_spec()
    |> put_param_value(name, value)
    |> Jason.encode!()
    |> VegaLite.from_json()
    |> Tucan.Export.to_svg()
  end

  defp put_param_value(%{"name" => name, "select" => _select} = param, name, value),
    do: Map.put(param, "value", value)

  defp put_param_value(%{} = map, name, value),
    do: Map.new(map, fn {key, item} -> {key, put_param_value(item, name, value)} end)

  defp put_param_value(list, name, value) when is_list(list),
    do: Enum.map(list, &put_param_value(&1, name, value))

  defp put_param_value(other, _name, _value), do: other

  defp visible(marks) do
    for [label, opacity] <-
          Regex.scan(~r/aria-label="([^"]*)"[^>]*\sopacity="([^"]*)"/, marks,
            capture: :all_but_first
          ),
        opacity != "0",
        do: label
  end

  # the labels of the drawn marks
  defp marks(svg) do
    for [label] <-
          Regex.scan(~r/aria-label="([^"]*)" role="graphics-symbol"/, svg,
            capture: :all_but_first
          ),
        do: label
  end
end
