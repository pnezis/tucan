defmodule Tucan.GeometryTest do
  use ExUnit.Case

  alias VegaLite, as: Vl

  describe "circle/4" do
    test "sequence for circle with the given center and radius" do
      expected =
        Vl.new()
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:line, stroke_width: 1)
          |> Vl.data(sequence: [start: 0, stop: 361, step: 0.1, as: "theta"])
          |> Vl.transform(calculate: "-1 + cos(datum.theta*PI/180) * 2.5", as: "x")
          |> Vl.transform(calculate: "3 + sin(datum.theta*PI/180) * 2.5", as: "y")
          |> Vl.encode_field(:x, "x", type: :quantitative)
          |> Vl.encode_field(:y, "y", type: :quantitative)
          |> Vl.encode_field(:order, "theta")
        ])

      assert Tucan.Geometry.circle(Vl.new(), {-1, 3}, 2.5) == expected
    end

    test "with custom style options" do
      %VegaLite{spec: %{"layer" => [circle]}} =
        Tucan.Geometry.circle(Vl.new(), {-1, 3}, 2.5, line_color: "red", stroke_width: 4)

      assert circle["mark"] == %{"strokeWidth" => 4, "type" => "line", "color" => "red"}
    end
  end
end
