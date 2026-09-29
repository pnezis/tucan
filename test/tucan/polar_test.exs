defmodule Tucan.PolarTest do
  use ExUnit.Case

  @data [r: [0.3, 1.7, -0.5], theta: [0, 90, 180]]

  defp layers(vl), do: VegaLite.to_spec(vl)["layer"]

  # the data layers are between the grid lines and the grid labels
  defp data_layer(vl), do: vl |> layers() |> Enum.drop(-2) |> List.last()

  defp grid_layer(vl, mark) do
    vl |> layers() |> Enum.find(fn layer -> layer["mark"]["type"] == mark end)
  end

  defp angle_labels(vl) do
    vl |> layers() |> Enum.at(-2) |> get_in(["data", "values"]) |> Enum.map(& &1["label"])
  end

  defp radius_labels(vl) do
    vl
    |> layers()
    |> Enum.filter(fn layer -> layer["mark"]["type"] == "text" end)
    |> List.last()
    |> get_in(["data", "values"])
    |> Enum.map(& &1["label"])
  end

  describe "lineplot/4" do
    test "creates a square layered plot with the data between the grid lines and labels" do
      spec = Tucan.Polar.lineplot(@data, "r", "theta") |> VegaLite.to_spec()

      assert spec["width"] == 300
      assert spec["height"] == 300
      assert spec["config"] == %{"view" => %{"stroke" => nil}}
      assert %{"values" => [_, _, _]} = spec["data"]

      assert Enum.map(spec["layer"], & &1["mark"]["type"]) == [
               "line",
               "rule",
               "line",
               "text",
               "text"
             ]
    end

    test "converts the polar coordinates to cartesian" do
      layer = Tucan.Polar.lineplot(@data, "r", "theta") |> data_layer()

      assert [
               %{"calculate" => angle, "as" => "__polar_angle"},
               %{
                 "calculate" => ~S|toNumber(datum["r"]) * cos(datum.__polar_angle)|,
                 "as" => "__polar_x"
               },
               %{
                 "calculate" => ~S|toNumber(datum["r"]) * sin(datum.__polar_angle)|,
                 "as" => "__polar_y"
               }
             ] = layer["transform"]

      assert angle == ~s|#{:math.pi() / 180} * toNumber(datum["theta"]) + 0.0|

      assert layer["mark"] == %{"type" => "line", "fillOpacity" => 1}
      assert layer["encoding"]["order"] == %{"field" => "theta", "type" => "quantitative"}

      for channel <- ["x", "y"] do
        assert layer["encoding"][channel] == %{
                 "field" => "__polar_#{channel}",
                 "type" => "quantitative",
                 "scale" => %{"domain" => [-2, 2], "nice" => false, "zero" => false},
                 "axis" => nil
               }
      end
    end

    test "applies the angle unit, direction and offset" do
      layer =
        Tucan.Polar.lineplot(@data, "r", "theta",
          angle_unit: :radians,
          direction: :clockwise,
          angle_offset: 90
        )
        |> data_layer()

      assert hd(layer["transform"])["calculate"] ==
               ~s|-1 * toNumber(datum["theta"]) + #{:math.pi() / 2}|
    end

    test "escapes field names" do
      layer =
        Tucan.Polar.lineplot([{"my r", [1]}, {~s|"t"|, [0]}], "my r", ~s|"t"|)
        |> data_layer()

      assert [%{"calculate" => angle}, %{"calculate" => x} | _] = layer["transform"]
      assert angle =~ ~S|toNumber(datum["\"t\""])|
      assert x == ~S|toNumber(datum["my r"]) * cos(datum.__polar_angle)|
    end

    test "infers a round max radius and ticks from the data" do
      vl = Tucan.Polar.lineplot(@data, "r", "theta")

      assert radius_labels(vl) == ["0.5", "1", "1.5", "2"]

      vl = Tucan.Polar.lineplot([r: [0, 37, 12], theta: [0, 1, 2]], "r", "theta")

      assert get_in(data_layer(vl), ["encoding", "x", "scale", "domain"]) == [-40, 40]
      assert radius_labels(vl) == ["10", "20", "30", "40"]

      # round radiuses are not rounded up
      for {max, expected} <- [{5, 5}, {4.2, 5}, {9, 10}, {0.3, 0.3}, {17.3, 20}, {130, 150}] do
        vl = Tucan.Polar.lineplot([r: [max], theta: [0]], "r", "theta")

        assert get_in(data_layer(vl), ["encoding", "x", "scale", "domain"]) == [
                 -expected,
                 expected
               ]
      end

      vl = Tucan.Polar.lineplot([r: [0, 0], theta: [0, 1]], "r", "theta")

      assert get_in(data_layer(vl), ["encoding", "x", "scale", "domain"]) == [-1, 1]
    end

    test "uses the radius options if set" do
      vl = Tucan.Polar.lineplot(@data, "r", "theta", radius_ticks: [1, 3])

      assert get_in(data_layer(vl), ["encoding", "x", "scale", "domain"]) == [-3, 3]
      assert radius_labels(vl) == ["1", "3"]

      vl = Tucan.Polar.lineplot(@data, "r", "theta", max_radius: 5)

      assert get_in(data_layer(vl), ["encoding", "x", "scale", "domain"]) == [-5, 5]
      assert radius_labels(vl) == ["1", "2", "3", "4", "5"]

      # the outer circle is not labeled if no round step divides the max radius
      vl = Tucan.Polar.lineplot(@data, "r", "theta", max_radius: 7)

      assert radius_labels(vl) == ["2", "4", "6"]

      vl = Tucan.Polar.lineplot(@data, "r", "theta", max_radius: 1)

      assert radius_labels(vl) == ["0.25", "0.5", "0.75", "1"]

      vl = Tucan.Polar.lineplot(@data, "r", "theta", max_radius: 5, radius_ticks: [2])

      assert get_in(data_layer(vl), ["encoding", "x", "scale", "domain"]) == [-5, 5]
      assert radius_labels(vl) == ["2"]

      circles = get_in(grid_layer(vl, "line"), ["data", "values"])

      assert circles |> Enum.map(& &1["r"]) |> Enum.uniq() == [2, 5]
    end

    test "raises if the max radius cannot be inferred" do
      assert_raise ArgumentError, ~r/cannot infer the maximum radius/, fn ->
        Tucan.Polar.lineplot("https://example.com/data.csv", "r", "theta")
      end

      assert %VegaLite{} =
               Tucan.Polar.lineplot("https://example.com/data.csv", "r", "theta", max_radius: 1)
    end

    test "draws the angle lines and labels at the angle marks" do
      vl =
        Tucan.Polar.lineplot(@data, "r", "theta",
          max_radius: 1,
          angle_marks: [0, 90],
          grid_color: "red",
          grid_opacity: 0.5
        )

      rules = grid_layer(vl, "rule")

      assert rules["mark"] == %{
               "type" => "rule",
               "color" => "red",
               "opacity" => 0.5,
               "strokeWidth" => 1
             }

      assert rules["data"]["values"] == [
               %{"x" => 0, "y" => 0, "x2" => 1, "y2" => 0},
               %{"x" => 0, "y" => 0, "x2" => 0, "y2" => 1}
             ]

      labels = vl |> layers() |> Enum.at(-2) |> get_in(["data", "values"])

      assert Enum.map(labels, & &1["label"]) == ["0°", "90°"]
    end

    test "with angle labels" do
      labels = fn opts ->
        Tucan.Polar.lineplot(@data, "r", "theta", [max_radius: 1] ++ opts)
        |> layers()
        |> Enum.at(-2)
        |> get_in(["data", "values"])
        |> Enum.map(& &1["label"])
      end

      assert labels.(angle_marks: [0, 22.5, 90]) == ["0°", "22.5°", "90°"]

      assert labels.(angle_marks: [0, 22.5, 45, 90, 180, 270, 360, 10], angle_labels: :compass) ==
               ["N", "NNE", "NE", "E", "S", "W", "N", "10°"]

      assert labels.(angle_marks: [0, 90], angle_labels: ["a", "b"]) == ["a", "b"]
      assert labels.(angle_labels: :none) == []

      assert_raise ArgumentError, ~r/expected as many :angle_labels as :angle_marks/, fn ->
        labels.(angle_marks: [0, 90], angle_labels: ["a"])
      end
    end

    test "rotates the grid with the direction and offset" do
      vl =
        Tucan.Polar.lineplot(@data, "r", "theta",
          max_radius: 1,
          angle_marks: [0, 90],
          direction: :clockwise,
          angle_offset: 90
        )

      assert get_in(grid_layer(vl, "rule"), ["data", "values"]) == [
               %{"x" => 0, "y" => 0, "x2" => 0, "y2" => 1},
               %{"x" => 0, "y" => 0, "x2" => 1, "y2" => 0}
             ]
    end

    test "with width and title" do
      spec =
        Tucan.Polar.lineplot(@data, "r", "theta", width: 200, title: "Polar")
        |> VegaLite.to_spec()

      assert spec["width"] == 200
      assert spec["height"] == 200
      assert spec["title"] == "Polar"
    end

    test "with grouping and styling options" do
      layer =
        Tucan.Polar.lineplot([r: [1, 2], theta: [0, 1], g: ["a", "b"]], "r", "theta",
          color_by: "g",
          group_by: "g",
          line_color: "red",
          stroke_width: 3,
          interpolate: "linear-closed",
          points: true,
          point_size: 20
        )
        |> data_layer()

      assert layer["mark"] == %{
               "type" => "line",
               "color" => "red",
               "fillOpacity" => 1,
               "interpolate" => "linear-closed",
               "point" => %{"size" => 20},
               "strokeWidth" => 3
             }

      assert layer["encoding"]["color"] == %{"field" => "g"}
      assert layer["encoding"]["detail"] == %{"field" => "g", "type" => "nominal"}

      layer = Tucan.Polar.lineplot(@data, "r", "theta", points: true) |> data_layer()

      assert layer["mark"]["point"] == true
    end

    test "tooltip shows the polar coordinates" do
      layer =
        Tucan.Polar.lineplot([r: [1, 2], theta: [0, 1], g: ["a", "b"]], "r", "theta",
          color_by: "g",
          tooltip: true
        )
        |> data_layer()

      assert layer["mark"]["tooltip"] == true

      assert layer["encoding"]["tooltip"] == [
               %{"field" => "r", "type" => "quantitative"},
               %{"field" => "theta", "type" => "quantitative"},
               %{"field" => "g", "type" => "nominal"}
             ]
    end

    test "raises with invalid options" do
      for opts <- [
            [max_radius: 0],
            [radius_ticks: [-1]],
            [angle_unit: :gradians],
            [direction: :up],
            [grid_opacity: 2]
          ] do
        assert_raise NimbleOptions.ValidationError, fn ->
          Tucan.Polar.lineplot(@data, "r", "theta", opts)
        end
      end
    end
  end

  describe "scatter/4" do
    test "draws the points between the grid lines and labels" do
      vl = Tucan.Polar.scatter(@data, "r", "theta")
      spec = VegaLite.to_spec(vl)
      layer = data_layer(vl)

      assert spec["width"] == 300
      assert spec["height"] == 300

      assert Enum.map(spec["layer"], & &1["mark"]["type"]) == [
               "line",
               "rule",
               "point",
               "text",
               "text"
             ]

      assert layer["mark"] == %{"type" => "point", "fillOpacity" => 1}

      assert Enum.map(layer["transform"], & &1["as"]) == [
               "__polar_angle",
               "__polar_x",
               "__polar_y"
             ]

      assert get_in(layer, ["encoding", "x", "scale", "domain"]) == [-2, 2]
      refute Map.has_key?(layer["encoding"], "order")
    end

    test "with grouping and styling options" do
      layer =
        Tucan.Polar.scatter([r: [1, 2], theta: [0, 1], g: ["a", "b"]], "r", "theta",
          color_by: "g",
          shape_by: "g",
          size_by: "r",
          point_color: "red",
          point_shape: "square",
          point_size: 30,
          filled: true,
          tooltip: true
        )
        |> data_layer()

      assert layer["mark"] == %{
               "type" => "point",
               "color" => "red",
               "shape" => "square",
               "size" => 30,
               "filled" => true,
               "fillOpacity" => 1,
               "tooltip" => true
             }

      assert layer["encoding"]["color"] == %{"field" => "g", "type" => "nominal"}
      assert layer["encoding"]["shape"] == %{"field" => "g", "type" => "nominal"}
      assert layer["encoding"]["size"] == %{"field" => "r", "type" => "quantitative"}

      assert layer["encoding"]["tooltip"] == [
               %{"field" => "r", "type" => "quantitative"},
               %{"field" => "theta", "type" => "quantitative"},
               %{"field" => "g", "type" => "nominal"}
             ]
    end

    test "with custom encoding options" do
      layer =
        Tucan.Polar.scatter([r: [1, 2], theta: [0, 1], g: ["a", "b"]], "r", "theta",
          color_by: "g",
          color: [scale: [scheme: "set1"]]
        )
        |> data_layer()

      assert layer["encoding"]["color"] == %{
               "field" => "g",
               "type" => "nominal",
               "scale" => %{"scheme" => "set1"}
             }
    end
  end

  describe "area/4" do
    test "draws a closed filled shape" do
      vl = Tucan.Polar.area(@data, "r", "theta")
      layer = data_layer(vl)

      assert length(layers(vl)) == 5

      assert layer["mark"] == %{
               "type" => "line",
               "filled" => true,
               "fillOpacity" => 0.5,
               "interpolate" => "linear-closed"
             }

      assert layer["encoding"]["order"] == %{"field" => "theta", "type" => "quantitative"}

      assert Enum.map(layer["transform"], & &1["as"]) == [
               "__polar_angle",
               "__polar_x",
               "__polar_y"
             ]

      assert get_in(layer, ["encoding", "x", "scale", "domain"]) == [-2, 2]
    end

    test "with colors and outline" do
      layer =
        Tucan.Polar.area(@data, "r", "theta",
          fill_color: "red",
          line_color: "black",
          stroke_width: 2,
          fill_opacity: 0.3,
          interpolate: "cardinal-closed"
        )
        |> data_layer()

      assert layer["mark"] == %{
               "type" => "line",
               "filled" => true,
               "color" => "red",
               "stroke" => "black",
               "strokeWidth" => 2,
               "fillOpacity" => 0.3,
               "interpolate" => "cardinal-closed"
             }
    end

    test "with color_by and group_by" do
      layer =
        Tucan.Polar.area([r: [1, 2], theta: [0, 1], g: ["a", "b"]], "r", "theta",
          color_by: "g",
          group_by: "g",
          tooltip: true
        )
        |> data_layer()

      assert layer["encoding"]["color"] == %{
               "field" => "g",
               "legend" => %{"symbolType" => "square"}
             }

      assert layer["encoding"]["detail"] == %{"field" => "g", "type" => "nominal"}

      assert layer["encoding"]["tooltip"] == [
               %{"field" => "r", "type" => "quantitative"},
               %{"field" => "theta", "type" => "quantitative"},
               %{"field" => "g", "type" => "nominal"}
             ]
    end
  end

  describe "radar/4" do
    @radar_data [
      %{s: "a", k: "x", v: 1},
      %{s: "a", k: "y", v: 3},
      %{s: "a", k: "z", v: 2},
      %{s: "b", k: "x", v: 2},
      %{s: "b", k: "y", v: 1},
      %{s: "b", k: "z", v: 4}
    ]

    test "places the categories at equal angles" do
      vl = Tucan.Polar.radar(@radar_data, "v", "k")
      layer = data_layer(vl)
      index = ~S|indexof(["x","y","z"], datum["k"])|

      assert length(layers(vl)) == 5
      assert angle_labels(vl) == ["x", "y", "z"]

      assert [
               %{"filter" => filter},
               %{"calculate" => angle, "as" => "__radar_angle"},
               %{"calculate" => theta_expr, "as" => "__polar_angle"} | _
             ] = layer["transform"]

      assert filter == "#{index} >= 0"
      assert angle == "#{index} * 120.0"

      # clockwise from the top by default
      assert theta_expr ==
               ~s|#{-:math.pi() / 180} * toNumber(datum["__radar_angle"]) + #{:math.pi() / 2}|

      assert layer["mark"] == %{
               "type" => "line",
               "interpolate" => "linear-closed",
               "point" => true
             }

      assert layer["encoding"]["order"] == %{"field" => "__radar_angle", "type" => "quantitative"}
      assert get_in(layer, ["encoding", "x", "scale", "domain"]) == [-4, 4]

      rules = vl |> layers() |> Enum.at(1) |> get_in(["data", "values"])
      assert length(rules) == 3
    end

    test "with explicit categories" do
      vl = Tucan.Polar.radar(@radar_data, "v", "k", categories: ["z", "x"])

      assert angle_labels(vl) == ["z", "x"]

      assert [%{"filter" => ~S|indexof(["z","x"], datum["k"]) >= 0|} | _] =
               data_layer(vl)["transform"]
    end

    test "raises if the categories cannot be inferred" do
      assert_raise ArgumentError, ~r/set the :categories option/, fn ->
        Tucan.Polar.radar("https://example.com/data.csv", "v", "k", max_radius: 1)
      end

      assert %VegaLite{} =
               Tucan.Polar.radar("https://example.com/data.csv", "v", "k",
                 max_radius: 1,
                 categories: ["x"]
               )
    end

    test "filled radar adds a fill layer below the outlines" do
      vl =
        Tucan.Polar.radar(@radar_data, "v", "k",
          color_by: "s",
          filled: true,
          fill_opacity: 0.2,
          points: false,
          stroke_width: 3,
          tooltip: true
        )

      [fill, line] = vl |> layers() |> Enum.slice(2, 2)

      assert fill["mark"] == %{
               "type" => "line",
               "filled" => true,
               "interpolate" => "linear-closed",
               "fillOpacity" => 0.2
             }

      assert line["mark"] == %{
               "type" => "line",
               "interpolate" => "linear-closed",
               "strokeWidth" => 3,
               "tooltip" => true
             }

      for layer <- [fill, line] do
        assert layer["encoding"]["color"] == %{"field" => "s"}
        assert hd(layer["transform"])["filter"] =~ "indexof"
      end

      assert line["encoding"]["tooltip"] == [
               %{"field" => "v", "type" => "quantitative"},
               %{"field" => "k", "type" => "nominal"},
               %{"field" => "s", "type" => "nominal"}
             ]
    end

    test "with styling options" do
      layer =
        Tucan.Polar.radar(@radar_data, "v", "k",
          group_by: "s",
          line_color: "red",
          point_color: "black",
          point_size: 40,
          direction: :counter_clockwise,
          angle_offset: 0
        )
        |> data_layer()

      assert layer["mark"] == %{
               "type" => "line",
               "color" => "red",
               "interpolate" => "linear-closed",
               "point" => %{"color" => "black", "size" => 40}
             }

      assert layer["encoding"]["detail"] == %{"field" => "s", "type" => "nominal"}

      assert Enum.at(layer["transform"], 2)["calculate"] ==
               ~s|#{:math.pi() / 180} * toNumber(datum["__radar_angle"]) + 0.0|
    end
  end

  describe "period" do
    test "with a numeric period" do
      vl = Tucan.Polar.lineplot([r: [1, 2], h: [0, 12]], "r", "h", period: 24, tooltip: true)
      layer = data_layer(vl)

      assert [
               %{"calculate" => period, "as" => "__polar_period_angle"},
               %{"calculate" => angle, "as" => "__polar_angle"} | _
             ] = layer["transform"]

      assert period == ~S|((toNumber(datum["h"]) % 24) + 24) % 24 / 24 * 360|

      # clock-like by default
      assert angle ==
               "#{-:math.pi() / 180} * datum.__polar_period_angle + #{:math.pi() / 2}"

      assert angle_labels(vl) == ~w(0 3 6 9 12 15 18 21)
      assert layer["encoding"]["order"]["type"] == "quantitative"

      assert Enum.at(layer["encoding"]["tooltip"], 1) == %{
               "field" => "h",
               "type" => "quantitative"
             }

      assert angle_labels(Tucan.Polar.lineplot([r: [1], h: [0]], "r", "h", period: 12)) ==
               ~w(0 1 2 3 4 5 6 7 8 9 10 11)

      assert angle_labels(Tucan.Polar.lineplot([r: [1], h: [0]], "r", "h", period: 1)) ==
               ~w(0 0.125 0.25 0.375 0.5 0.625 0.75 0.875)
    end

    test "with temporal periods" do
      data = [r: [1, 2], d: [~D[2024-01-01], ~D[2024-06-01]]]

      for {period, expr, labels} <- [
            {:day, "/ 86400 * 360", ~w(00:00 03:00 06:00 09:00 12:00 15:00 18:00 21:00)},
            {:week, "(day(datum.__polar_date) + 6) % 7", ~w(Mon Tue Wed Thu Fri Sat Sun)},
            {:year, "time(datetime(year(datum.__polar_date) + 1, 0, 1))",
             ~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)}
          ] do
        vl = Tucan.Polar.lineplot(data, "r", "d", period: period, tooltip: true)
        layer = data_layer(vl)

        assert [
                 %{"calculate" => ~S|toDate(datum["d"])|, "as" => "__polar_date"},
                 %{"calculate" => period_expr, "as" => "__polar_period_angle"} | _
               ] = layer["transform"]

        assert period_expr =~ expr
        assert angle_labels(vl) == labels
        assert layer["encoding"]["order"] == %{"field" => "d", "type" => "temporal"}
        assert Enum.at(layer["encoding"]["tooltip"], 1) == %{"field" => "d", "type" => "temporal"}
      end
    end

    test "user options take precedence over the period defaults" do
      vl =
        Tucan.Polar.area([r: [1], h: [0]], "r", "h",
          period: 24,
          direction: :counter_clockwise,
          angle_offset: 0,
          angle_marks: [0, 180]
        )

      assert Enum.at(data_layer(vl)["transform"], 1)["calculate"] ==
               "#{:math.pi() / 180} * datum.__polar_period_angle + 0.0"

      # custom angle marks are labeled in degrees
      assert angle_labels(vl) == ["0°", "180°"]

      vl =
        Tucan.Polar.scatter([r: [1], h: [0]], "r", "h",
          period: 24,
          angle_marks: [0, 180],
          angle_labels: ["midnight", "noon"]
        )

      assert angle_labels(vl) == ["midnight", "noon"]
    end

    test "raises with an invalid period" do
      for period <- [0, -1, :month] do
        assert_raise NimbleOptions.ValidationError, fn ->
          Tucan.Polar.lineplot(@data, "r", "theta", period: period)
        end
      end
    end
  end

  describe "bar/4" do
    @bar_data [
      %{k: "x", v: 1, g: "a"},
      %{k: "y", v: 3, g: "a"},
      %{k: "x", v: 2, g: "b"},
      %{k: "y", v: 4, g: "b"},
      %{k: "z", v: 2, g: "a"}
    ]

    test "draws a sector per category" do
      vl = Tucan.Polar.bar(@bar_data, "v", "k")
      layer = data_layer(vl)
      index = ~S|indexof(["x","y","z"], datum["k"])|

      assert layer["mark"] == %{"type" => "arc", "fillOpacity" => 1}

      assert Enum.map(layer["transform"], &(&1["as"] || &1["filter"])) == [
               "#{index} >= 0",
               "__value",
               "__start_angle",
               "__end_angle",
               "__r_end",
               "__r_start",
               "__theta",
               "__theta2"
             ]

      assert Enum.at(layer["transform"], 2)["calculate"] == "#{index} * 120.0 - 60.0"

      # clockwise from the top, converted to vega-lite arc angles
      assert Enum.at(layer["transform"], 6)["calculate"] ==
               "0.0 - #{-:math.pi() / 180} * (datum.__start_angle)"

      assert layer["encoding"]["theta"] == %{
               "field" => "__theta",
               "type" => "quantitative",
               "scale" => nil,
               "stack" => nil
             }

      assert layer["encoding"]["radius"] == %{
               "field" => "__r_end",
               "type" => "quantitative",
               "scale" => %{
                 "type" => "linear",
                 "domain" => [0, 4],
                 "range" => [0, 150.0],
                 "nice" => false
               },
               "stack" => nil
             }

      assert layer["encoding"]["radius2"] == %{"field" => "__r_start"}

      # grid lines at the sector boundaries and labels at their centers
      assert get_in(Enum.at(layers(vl), 1), ["data", "values"]) |> length() == 3
      assert angle_labels(vl) == ["x", "y", "z"]
    end

    test "stacks the bars by color" do
      vl =
        Tucan.Polar.bar(@bar_data, "v", "k",
          color_by: "g",
          aggregate: :sum,
          tooltip: true
        )

      layer = data_layer(vl)

      assert Enum.at(layer["transform"], 1) == %{
               "aggregate" => [%{"op" => "sum", "field" => "v", "as" => "__value"}],
               "groupby" => ["k", "g"]
             }

      assert Enum.at(layer["transform"], 4) == %{
               "window" => [%{"op" => "sum", "field" => "__value", "as" => "__r_end"}],
               "groupby" => ["k"],
               "sort" => [%{"field" => "g"}],
               "frame" => [nil, 0]
             }

      # x: 1 + 2, y: 3 + 4, z: 2 rounded up
      assert get_in(layer, ["encoding", "radius", "scale", "domain"]) == [0, 7.5]
      assert layer["encoding"]["color"] == %{"field" => "g", "type" => "nominal"}

      assert layer["encoding"]["tooltip"] == [
               %{"field" => "k", "type" => "nominal"},
               %{"field" => "__value", "type" => "quantitative", "title" => "sum(v)"},
               %{"field" => "g", "type" => "nominal"}
             ]
    end

    test "infers the max radius from the aggregated values" do
      domain = fn opts ->
        Tucan.Polar.bar(@bar_data, "v", "k", opts)
        |> data_layer()
        |> get_in(["encoding", "radius", "scale", "domain"])
      end

      assert domain.([]) == [0, 4]
      assert domain.(aggregate: :sum) == [0, 7.5]
      assert domain.(aggregate: :count) == [0, 2]
      assert domain.(aggregate: :mean) == [0, 4]
      assert domain.(aggregate: :min) == [0, 3]
      assert domain.(categories: ["x"]) == [0, 2]
    end

    test "with styling options" do
      vl =
        Tucan.Polar.bar(@bar_data, "v", "k",
          fill_color: "red",
          line_color: "white",
          stroke_width: 2,
          fill_opacity: 0.5,
          width: 200
        )

      layer = data_layer(vl)

      assert layer["mark"] == %{
               "type" => "arc",
               "color" => "red",
               "stroke" => "white",
               "strokeWidth" => 2,
               "fillOpacity" => 0.5
             }

      assert get_in(layer, ["encoding", "radius", "scale", "range"]) == [0, 100.0]
    end

    test "raises if the categories cannot be inferred" do
      assert_raise ArgumentError, ~r/set the :categories option/, fn ->
        Tucan.Polar.bar("https://example.com/data.csv", "v", "k", max_radius: 1)
      end
    end
  end

  describe "histogram/3" do
    defp domain(vl), do: get_in(data_layer(vl), ["encoding", "radius", "scale", "domain"])

    test "bins the angles and counts the values" do
      vl = Tucan.Polar.histogram([t: [10, 20, 100, 370, -80]], "t", bins: 4)
      layer = data_layer(vl)

      assert [
               %{"calculate" => degrees, "as" => "__degrees"},
               %{"calculate" => bin, "as" => "__bin"},
               %{"aggregate" => [%{"op" => "count", "as" => "__value"}], "groupby" => ["__bin"]},
               %{"calculate" => "datum.__bin * 90.0", "as" => "__start_angle"},
               %{"calculate" => "datum.__start_angle + 90.0", "as" => "__end_angle"},
               %{"as" => "__r_end"},
               %{"as" => "__r_start"},
               %{"calculate" => "datum.__start_angle * 1", "as" => "__bin_start"},
               %{"calculate" => "datum.__end_angle * 1", "as" => "__bin_end"},
               %{"as" => "__theta"},
               %{"as" => "__theta2"}
             ] = layer["transform"]

      assert degrees == ~S|((toNumber(datum["t"])) % 360 + 360) % 360|
      assert bin == "min(floor(datum.__degrees / 90.0), 3)"

      # 10, 20 and 370 are in the first bin
      assert domain(vl) == [0, 3]
      assert layer["mark"]["type"] == "arc"

      # counter clockwise from the right by default
      assert Enum.at(layer["transform"], 9)["calculate"] ==
               "#{:math.pi() / 2} - #{:math.pi() / 180} * (datum.__start_angle)"
    end

    test "with stacked colors and relative values" do
      data = [t: [10, 20, 30, 200], g: ["a", "b", "b", "a"]]
      vl = Tucan.Polar.histogram(data, "t", bins: 4, color_by: "g", relative: true, tooltip: true)
      layer = data_layer(vl)

      assert Enum.at(layer["transform"], 2)["groupby"] == ["__bin", "g"]

      assert Enum.at(layer["transform"], 3) == %{
               "joinaggregate" => [%{"op" => "sum", "field" => "__value", "as" => "__total"}]
             }

      assert Enum.at(layer["transform"], 7)["sort"] == [%{"field" => "g"}]

      # 3 of the 4 values are in the first bin
      assert domain(vl) == [0, 75]

      assert layer["encoding"]["tooltip"] == [
               %{
                 "field" => "__bin_start",
                 "type" => "quantitative",
                 "title" => "t from",
                 "format" => ".4~f"
               },
               %{
                 "field" => "__bin_end",
                 "type" => "quantitative",
                 "title" => "t to",
                 "format" => ".4~f"
               },
               %{
                 "field" => "__value",
                 "type" => "quantitative",
                 "title" => "Percentage",
                 "format" => ".3~f"
               },
               %{"field" => "g", "type" => "nominal"}
             ]
    end

    test "with angle units and periods" do
      pi = :math.pi()

      vl = Tucan.Polar.histogram([t: [0.1, 0.2, pi]], "t", bins: 2, angle_unit: :radians)
      assert domain(vl) == [0, 2]

      assert hd(data_layer(vl)["transform"])["calculate"] ==
               ~s|((toNumber(datum["t"]) * #{180 / pi}) % 360 + 360) % 360|

      vl = Tucan.Polar.histogram([h: [1, 2, 25, 13]], "h", bins: 2, period: 24)
      assert domain(vl) == [0, 3]

      assert Enum.at(data_layer(vl)["transform"], -3)["calculate"] ==
               "datum.__end_angle * #{24 / 360}"

      dates = [d: [~D[2024-01-02], "2024-01-05", ~N[2024-09-01 10:00:00], "invalid"]]
      vl = Tucan.Polar.histogram(dates, "d", bins: 2, period: :year, tooltip: true)

      assert domain(vl) == [0, 2]

      assert Enum.map(data_layer(vl)["encoding"]["tooltip"], & &1["field"]) == ["__value"]

      # a week starts on Monday
      vl =
        Tucan.Polar.histogram([d: ["2024-01-01T10:00:00", "2024-01-07"]], "d",
          bins: 7,
          period: :week
        )

      assert domain(vl) == [0, 1]
    end

    test "raises if the max radius cannot be inferred" do
      assert_raise ArgumentError, ~r/cannot infer the maximum radius/, fn ->
        Tucan.Polar.histogram("https://example.com/data.csv", "t")
      end
    end
  end
end
