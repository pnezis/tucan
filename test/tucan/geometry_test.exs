defmodule Tucan.GeometryTest do
  use ExUnit.Case

  alias VegaLite, as: Vl

  describe "circle/4" do
    test "sequence for circle with the given center and radius" do
      expected =
        Vl.new()
        |> Vl.mark(:line, stroke_width: 1, fill_opacity: 1, stroke_opacity: 1)
        |> Vl.data(sequence: [start: 0, stop: 361, step: 0.1, as: "theta"])
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
        |> Vl.data(sequence: [start: 0, stop: 361, step: 0.1, as: "theta"])
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
end
