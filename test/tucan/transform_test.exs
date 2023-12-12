defmodule Tucan.TransformTest do
  use ExUnit.Case

  alias VegaLite, as: Vl

  test "aggregate/2" do
    expected =
      Vl.transform(Vl.new(),
        aggregate: [[op: :mean, field: "x", as: "x_mean"]],
        groupby: ["x", "y"]
      )

    assert Tucan.Transform.aggregate(Vl.new(),
             operation: :mean,
             field: "x",
             as: "x_mean",
             groupby: ["x", "y"]
           ) == expected
  end
end
