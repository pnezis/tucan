defmodule Tucan.GeometryTest do
  use ExUnit.Case

  alias VegaLite, as: Vl

  describe "circle/4" do
    test "sequence for circle with the given center and radius" do
      expected =
        Vl.new()
        |> Vl.mark(:line, stroke_width: 1, fill_opacity: 1, stroke_opacity: 1)
        |> Vl.data(sequence: [start: 0, stop: 361, step: 1, as: "theta"])
        |> Vl.transform(calculate: "-1 + cos(datum.theta*PI/180) * 2.5", as: "x")
        |> Vl.transform(calculate: "3 + sin(datum.theta*PI/180) * 2.5", as: "y")
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:y, "y", type: :quantitative)
        |> Vl.encode_field(:order, "theta")

      assert Tucan.Geometry.circle({-1, 3}, 2.5) == expected
    end

    test "with custom style options" do
      %VegaLite{spec: circle} =
        Tucan.Geometry.circle({-1, 3}, 2.5, line_color: "red", stroke_width: 4)

      assert circle["mark"] == %{
               "strokeWidth" => 4,
               "type" => "line",
               "color" => "red",
               "fillOpacity" => 1,
               "strokeOpacity" => 1
             }
    end

    test "with fill color and opacities" do
      %VegaLite{spec: circle} =
        Tucan.Geometry.circle({-1, 3}, 2.5,
          line_color: "red",
          stroke_width: 4,
          fill_color: "green",
          fill_opacity: 0.2,
          stroke_opacity: 0.5
        )

      assert circle["mark"] == %{
               "strokeWidth" => 4,
               "type" => "line",
               "color" => "red",
               "fillOpacity" => 0.2,
               "fill" => "green",
               "strokeOpacity" => 0.5
             }
    end
  end

  describe "ellipse/5" do
    test "sequence for ellipse with the given center axes and angle" do
      expected =
        Vl.new()
        |> Vl.mark(:line, stroke_width: 1, fill_opacity: 1, stroke_opacity: 1)
        |> Vl.data(sequence: [start: 0, stop: 361, step: 1, as: "theta"])
        |> Vl.transform(
          calculate:
            "-1 + cos(datum.theta*PI/180) * cos(32*PI/180) * 2.5 -sin(datum.theta*PI/180) * sin(32*PI/180) * 3",
          as: "x"
        )
        |> Vl.transform(
          calculate:
            "3 + cos(datum.theta*PI/180) * sin(32*PI/180) * 2.5 +sin(datum.theta*PI/180) * cos(32*PI/180) * 3",
          as: "y"
        )
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:y, "y", type: :quantitative)
        |> Vl.encode_field(:order, "theta")

      assert Tucan.Geometry.ellipse({-1, 3}, 2.5, 3, 32) == expected
    end

    test "with custom style options" do
      %VegaLite{spec: ellipse} =
        Tucan.Geometry.ellipse({-1, 3}, 2.5, 3, -15, line_color: "red", stroke_width: 4)

      assert ellipse["mark"] == %{
               "strokeWidth" => 4,
               "type" => "line",
               "color" => "red",
               "fillOpacity" => 1,
               "strokeOpacity" => 1
             }
    end

    test "with fill color and opacities" do
      %VegaLite{spec: ellipse} =
        Tucan.Geometry.ellipse({-1, 3}, 2.5, 3, 20,
          line_color: "red",
          stroke_width: 4,
          fill_color: "green",
          fill_opacity: 0.2,
          stroke_opacity: 0.5
        )

      assert ellipse["mark"] == %{
               "strokeWidth" => 4,
               "type" => "line",
               "color" => "red",
               "fillOpacity" => 0.2,
               "fill" => "green",
               "strokeOpacity" => 0.5
             }
    end
  end

  describe "circle and ellipse sampling" do
    test "the shapes are closed with one point per degree" do
      for vl <- [Tucan.Geometry.circle({0, 0}, 1), Tucan.Geometry.ellipse({0, 0}, 2, 1, 30)] do
        %{"start" => start, "stop" => stop, "step" => step} =
          VegaLite.to_spec(vl)["data"]["sequence"]

        thetas = Enum.to_list(start..(stop - step)//step)

        # the last point coincides with the first one, closing the shape
        assert hd(thetas) == 0
        assert List.last(thetas) == 360
        assert length(thetas) == 361
      end
    end
  end

  describe "polyline/3" do
    @points [{1, 2}, {5, 7}, {9, 13}, {-1, 4}]

    test "with default settings" do
      expected =
        Vl.new()
        |> Vl.mark(:line, stroke_width: 1, fill_opacity: 1, stroke_opacity: 1)
        |> Vl.data_from_values(%{x: [1, 5, 9, -1], y: [2, 7, 13, 4], order: [0, 1, 2, 3]})
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:y, "y", type: :quantitative)
        |> Vl.encode_field(:order, "order")

      assert Tucan.Geometry.polyline(@points) == expected
    end

    test "with closed set to true" do
      expected =
        Vl.new()
        |> Vl.mark(:line, stroke_width: 1, fill_opacity: 1, stroke_opacity: 1)
        |> Vl.data_from_values(%{
          x: [1, 5, 9, -1, 1],
          y: [2, 7, 13, 4, 2],
          order: [0, 1, 2, 3, 4]
        })
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:y, "y", type: :quantitative)
        |> Vl.encode_field(:order, "order")

      assert Tucan.Geometry.polyline(@points, closed: true) == expected
    end

    test "with styling options" do
      %VegaLite{spec: polygon} =
        Tucan.Geometry.polyline(@points,
          line_color: "red",
          stroke_width: 4,
          fill_color: "green",
          fill_opacity: 0.2,
          stroke_opacity: 0.5,
          stroke_dash: [5, 5]
        )

      assert polygon["mark"] == %{
               "strokeWidth" => 4,
               "type" => "line",
               "color" => "red",
               "fillOpacity" => 0.2,
               "fill" => "green",
               "strokeOpacity" => 0.5,
               "strokeDash" => [5, 5]
             }
    end
  end

  describe "rectangle/4" do
    test "raises with invalid points" do
      assert_raise ArgumentError, "the two points must have different x coordinates", fn ->
        Tucan.Geometry.rectangle({1, 1}, {1, 3})
      end

      assert_raise ArgumentError, "the two points must have different y coordinates", fn ->
        Tucan.Geometry.rectangle({1, 3}, {2, 3})
      end
    end

    test "valid rectangle" do
      expected =
        Vl.new()
        |> Vl.mark(:line, stroke_width: 1, fill_opacity: 1, stroke_opacity: 1)
        |> Vl.data_from_values(%{x: [1, 1, 5, 5, 1], y: [2, 6, 6, 2, 2], order: [0, 1, 2, 3, 4]})
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:y, "y", type: :quantitative)
        |> Vl.encode_field(:order, "order")

      assert Tucan.Geometry.rectangle({1, 2}, {5, 6}) == expected
    end
  end

  describe "line/3" do
    test "draws a segment between the points" do
      spec = Tucan.Geometry.line({1, 2}, {3, 4}) |> VegaLite.to_spec()

      assert spec == %{
               "$schema" => "https://vega.github.io/schema/vega-lite/v5.json",
               "data" => %{"values" => [%{}]},
               "mark" => %{"type" => "rule", "strokeWidth" => 1},
               "encoding" => %{
                 "x" => %{"datum" => 1, "type" => "quantitative"},
                 "y" => %{"datum" => 2, "type" => "quantitative"},
                 "x2" => %{"datum" => 3},
                 "y2" => %{"datum" => 4}
               }
             }
    end

    test "with style options" do
      spec =
        Tucan.Geometry.line({1, 2}, {3, 4},
          line_color: "red",
          stroke_width: 3,
          stroke_dash: [4, 4],
          opacity: 0.5
        )
        |> VegaLite.to_spec()

      assert spec["mark"] == %{
               "type" => "rule",
               "color" => "red",
               "strokeWidth" => 3,
               "strokeDash" => [4, 4],
               "opacity" => 0.5
             }
    end

    test "does not affect the axis titles of the plot" do
      svg =
        Tucan.layers([
          Tucan.scatter([%{a: 1, b: 2}, %{a: 3, b: 4}], "a", "b"),
          Tucan.Geometry.line({0, 0}, {4, 4})
        ])
        |> Tucan.Export.to_svg()

      assert axis_titles(svg) == ["X-axis titled 'a'", "Y-axis titled 'b'"]
    end
  end

  describe "arrow/3" do
    test "draws a segment and a head at the end point" do
      spec = Tucan.Geometry.arrow({1, 2}, {3, 4}) |> VegaLite.to_spec()

      assert [segment, head] = spec["layer"]

      assert segment == %{
               "data" => %{"values" => [%{}]},
               "mark" => %{"type" => "rule", "color" => "black", "strokeWidth" => 2},
               "encoding" => %{
                 "x" => %{"datum" => 1, "type" => "quantitative"},
                 "y" => %{"datum" => 2, "type" => "quantitative"},
                 "x2" => %{"datum" => 3},
                 "y2" => %{"datum" => 4}
               }
             }

      assert %{
               "mark" => %{
                 "type" => "point",
                 "shape" => "triangle",
                 "filled" => true,
                 "size" => 60,
                 "color" => "black"
               },
               "encoding" => %{
                 "x" => %{"datum" => 3, "type" => "quantitative"},
                 "y" => %{"datum" => 4, "type" => "quantitative"}
               }
             } = head
    end

    test "with style options" do
      spec =
        Tucan.Geometry.arrow({1, 2}, {3, 4}, line_color: "red", head_size: 100, stroke_width: 1)
        |> VegaLite.to_spec()

      [segment, head] = spec["layer"]

      assert segment["mark"]["color"] == "red"
      assert segment["mark"]["strokeWidth"] == 1
      assert head["mark"]["color"] == "red"
      assert head["mark"]["size"] == 100
    end

    test "the head points in the direction of the arrow" do
      # clockwise angles from the up direction on a square plot
      directions = [
        {{0, 1}, 0},
        {{1, 1}, 45},
        {{1, 0}, 90},
        {{1, -1}, 135},
        {{0, -1}, 180},
        {{-1, -1}, -135},
        {{-1, 0}, -90},
        {{-1, 1}, -45}
      ]

      for {end_point, angle} <- directions do
        svg =
          Tucan.layers([Tucan.Geometry.arrow({0, 0}, end_point)])
          |> Tucan.set_size(200, 200)
          |> Tucan.Export.to_svg()

        assert_in_delta head_rotation(svg), angle, 0.01, "arrow to #{inspect(end_point)}"
      end
    end

    test "the head follows the screen direction if the scales differ" do
      # on a plot twice as wide as high the diagonal is less steep on the screen
      svg =
        Tucan.layers([Tucan.Geometry.arrow({0, 0}, {1, 1})])
        |> Tucan.set_size(400, 200)
        |> Tucan.Export.to_svg()

      assert_in_delta head_rotation(svg), :math.atan2(400, 200) * 180 / :math.pi(), 0.01
    end

    test "does not affect the axis titles of the plot" do
      svg =
        Tucan.layers([
          Tucan.scatter([%{a: 1, b: 2}, %{a: 3, b: 4}], "a", "b"),
          Tucan.Geometry.arrow({0, 0}, {4, 4})
        ])
        |> Tucan.Export.to_svg()

      assert axis_titles(svg) == ["X-axis titled 'a'", "Y-axis titled 'b'"]
    end
  end

  # the rotation of the arrow head in degrees, vega omits it if it is 0
  defp head_rotation(svg) do
    [symbols] = Regex.run(~r/class="mark-symbol.*?<\/g>/s, svg)

    case Regex.run(~r/rotate\(([-\d.]+)\)/, symbols, capture: :all_but_first) do
      nil -> 0.0
      [angle] -> angle |> Float.parse() |> elem(0)
    end
  end

  defp axis_titles(svg) do
    ~r/aria-label="([XY]-axis titled '[^']*')/
    |> Regex.scan(svg, capture: :all_but_first)
    |> List.flatten()
  end
end
