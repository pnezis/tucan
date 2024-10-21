defmodule Tucan.Finance do
  @moduledoc """
  Financial plots.

  This module provides specialized financial plots like `candlestick/7`.
  """
  alias VegaLite, as: Vl

  @global_opts [:width, :height, :title, :only, :zoomable]
  @global_mark_opts [:clip, :fill_opacity, :tooltip]

  @candlestick_opts Tucan.Options.take!([@global_opts, @global_mark_opts])
  @candlestick_schema Tucan.Options.to_nimble_schema!(@candlestick_opts)

  @doc """
  Plots a candlestick chart from OHLC data.

  `timestamp` is expected to correspond to the beginning of the chart's period.

  ## Options

  #{Tucan.Options.docs(@candlestick_opts)}

  ## Examples

  ```tucan
  Tucan.Finance.candlestick(:ohlc, "date", "open", "high", "low", "close",
    width: 400,
    tooltip: true
  )
  |> Tucan.Axes.set_y_title("Price")
  ```
  """
  @spec candlestick(
          plotdata :: Tucan.plotdata(),
          timestamp :: String.t(),
          open :: String.t(),
          high :: String.t(),
          low :: String.t(),
          close :: String.t(),
          opts :: keyword()
        ) :: VegaLite.t()
  def candlestick(plotdata, timestamp, open, high, low, close, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @candlestick_schema)

    spec_opts = Tucan.Options.take_options(opts, @candlestick_opts, :spec)
    mark_opts = Tucan.Options.take_options(opts, @candlestick_opts, :mark)

    rule_layer =
      Vl.new()
      |> Vl.mark(:rule, mark_opts)
      |> Vl.encode_field(:x, timestamp, type: :temporal)
      |> Vl.encode_field(:y, low, type: :quantitative, scale: [zero: false])
      |> Vl.encode_field(:y2, high, type: :quantitative)

    bar_layer =
      Vl.new()
      |> Vl.mark(:bar, mark_opts)
      |> Vl.encode_field(:x, timestamp, type: :temporal)
      |> Vl.encode_field(:y, open, type: :quantitative, scale: [zero: false])
      |> Vl.encode_field(:y2, close, type: :quantitative)
      |> Vl.encode(:color,
        condition: [test: "datum.#{open} < datum.#{close}", value: "#06982d"],
        value: "#ae1325"
      )

    plotdata
    |> Tucan.new(spec_opts)
    |> Tucan.layers([rule_layer, bar_layer])
  end
end
