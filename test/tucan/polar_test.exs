defmodule Tucan.PolarTest do
  use ExUnit.Case

  @data [r: [0.3, 1.7, -0.5], theta: [0, 90, 180]]

  defp layers(vl), do: VegaLite.to_spec(vl)["layer"]

  defp data_layer(vl), do: vl |> layers() |> List.last()

  defp grid_layer(vl, mark) do
    vl |> layers() |> Enum.find(fn layer -> layer["mark"]["type"] == mark end)
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
    test "creates a square layered plot with the grid below the data" do
      spec = Tucan.Polar.lineplot(@data, "r", "theta") |> VegaLite.to_spec()

      assert spec["width"] == 300
      assert spec["height"] == 300
      assert spec["config"] == %{"view" => %{"stroke" => nil}}
      assert %{"values" => [_, _, _]} = spec["data"]

      assert Enum.map(spec["layer"], & &1["mark"]["type"]) == [
               "line",
               "rule",
               "text",
               "text",
               "line"
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

      labels = vl |> layers() |> Enum.at(2) |> get_in(["data", "values"])

      assert Enum.map(labels, & &1["label"]) == ["0°", "90°"]
    end

    test "with angle labels" do
      labels = fn opts ->
        Tucan.Polar.lineplot(@data, "r", "theta", [max_radius: 1] ++ opts)
        |> layers()
        |> Enum.at(2)
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
    test "draws the points on top of the polar grid" do
      vl = Tucan.Polar.scatter(@data, "r", "theta")
      spec = VegaLite.to_spec(vl)
      layer = data_layer(vl)

      assert spec["width"] == 300
      assert spec["height"] == 300

      assert Enum.map(spec["layer"], & &1["mark"]["type"]) == [
               "line",
               "rule",
               "text",
               "text",
               "point"
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
end
