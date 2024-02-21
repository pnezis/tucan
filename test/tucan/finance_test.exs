defmodule Tucan.FinanceTest do
  use ExUnit.Case
  alias VegaLite, as: Vl

  @ohlc_dataset Tucan.Datasets.dataset(:ohlc)

  describe "candlestick/7" do
    test "returns the expected specification" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@ohlc_dataset)
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rule, fill_opacity: 1.0)
          |> Vl.encode_field(:x, "date", type: :temporal)
          |> Vl.encode_field(:y, "low", type: :quantitative, scale: [zero: false])
          |> Vl.encode_field(:y2, "high", type: :quantitative),
          Vl.new()
          |> Vl.mark(:bar, fill_opacity: 1.0)
          |> Vl.encode(:color,
            value: "#ae1325",
            condition: [test: "datum.open < datum.close", value: "#06982d"]
          )
          |> Vl.encode_field(:x, "date", type: :temporal)
          |> Vl.encode_field(:y, "open", type: :quantitative, scale: [zero: false])
          |> Vl.encode_field(:y2, "close", type: :quantitative)
        ])

      assert Tucan.Finance.candlestick(@ohlc_dataset, "date", "open", "high", "low", "close") ==
               expected
    end
  end
end
