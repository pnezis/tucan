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

    test "with zoomable set" do
      vl =
        Tucan.Finance.candlestick(@ohlc_dataset, "date", "open", "high", "low", "close",
          zoomable: true
        )

      refute Map.has_key?(vl.spec, "params")
      assert [layer0, layer1] = vl.spec["layer"]

      assert layer0["params"] == [
               %{"bind" => "scales", "name" => "_grid", "select" => "interval"}
             ]

      refute Map.has_key?(layer1, "params")
    end
  end

  describe "volume" do
    @volume_color %{
      "condition" => %{"test" => "datum.open < datum.close", "value" => "#06982d"},
      "value" => "#ae1325"
    }

    test "draws the volume below the candlesticks" do
      spec =
        Tucan.Finance.candlestick(@ohlc_dataset, "date", "open", "high", "low", "close",
          volume: "volume",
          width: 300,
          height: 200,
          title: "Prices"
        )
        |> VegaLite.to_spec()

      assert spec["title"] == "Prices"
      assert spec["data"] == %{"url" => @ohlc_dataset}
      assert spec["resolve"] == %{"scale" => %{"x" => "shared"}}

      assert [prices, volumes] = spec["vconcat"]

      assert %{"width" => 300, "height" => 200, "layer" => [_rule, _bar]} = prices

      for layer <- prices["layer"] do
        assert layer["encoding"]["x"]["axis"] == %{"title" => nil, "labels" => false}
        assert layer["encoding"]["y"]["axis"] == %{"title" => "Price"}
      end

      assert volumes == %{
               "width" => 300,
               "height" => 60,
               "mark" => "bar",
               "encoding" => %{
                 "x" => %{"field" => "date", "type" => "temporal"},
                 "y" => %{"field" => "volume", "type" => "quantitative", "title" => "Volume"},
                 "color" => @volume_color
               }
             }
    end

    test "with data, size and tooltip options" do
      data = [%{d: "2024-01-01", o: 1, h: 2, l: 0, c: 1, v: 5, extra: "dropped"}]

      spec =
        Tucan.Finance.candlestick(data, "d", "o", "h", "l", "c",
          volume: "v",
          volume_height: 40,
          only: ["d", "o", "h", "l", "c", "v"],
          tooltip: true
        )
        |> VegaLite.to_spec()

      assert spec["data"] == %{
               "values" => [
                 %{"d" => "2024-01-01", "o" => 1, "h" => 2, "l" => 0, "c" => 1, "v" => 5}
               ]
             }

      assert [_prices, volumes] = spec["vconcat"]
      assert volumes["height"] == 40
      assert volumes["mark"] == %{"type" => "bar", "tooltip" => true}
    end

    test "the volume bars are aligned with the candles and share their colors" do
      data = [
        %{d: ~D[2024-01-01], o: 10, h: 12, l: 9, c: 11, v: 100},
        %{d: ~D[2024-01-02], o: 11, h: 11.5, l: 8, c: 9, v: 300},
        %{d: ~D[2024-01-03], o: 9, h: 13, l: 9, c: 12, v: 200}
      ]

      svg =
        Tucan.Finance.candlestick(data, "d", "o", "h", "l", "c", volume: "v")
        |> Tucan.Export.to_svg()

      [candles, volumes] =
        ~r/class="mark-rect.*?<\/g>/s
        |> Regex.scan(svg)
        |> Enum.map(fn [group] -> bars(group) end)

      # one bar per period, at the same position and with the same color
      assert length(candles) == 3
      assert Enum.map(candles, &{&1.x, &1.fill}) == Enum.map(volumes, &{&1.x, &1.fill})
      assert Enum.map(candles, & &1.fill) == ["#06982d", "#ae1325", "#06982d"]

      # the volume bars start at zero, so their heights are proportional to the volume
      [h1, h2, h3] = Enum.map(volumes, & &1.height)
      assert_in_delta h2 / h1, 3, 1.0e-6
      assert_in_delta h3 / h1, 2, 1.0e-6
    end
  end

  # the x position, height and fill of the rendered bars
  defp bars(group) do
    ~r/d="M([^,]+),[^h]+h[^v]+v([^h]+)h[^"]*" fill="([^"]+)"/
    |> Regex.scan(group, capture: :all_but_first)
    |> Enum.map(fn [x, height, fill] ->
      %{x: parse_number(x), height: parse_number(height), fill: fill}
    end)
  end

  defp parse_number(string) do
    {number, ""} = Float.parse(string)
    number
  end
end
