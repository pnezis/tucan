defmodule Tucan.Finance do
  @moduledoc """
  Financial plots.

  This module provides specialized financial plots like `candlestick/7`.
  """
  alias VegaLite, as: Vl

  @global_opts Tucan.Options.global_opts() ++ [:zoomable]
  @global_mark_opts Tucan.Options.global_mark_opts()

  @volume_opts [
    volume: [
      type: :string,
      doc: """
      A field with the traded volume of each period. If set the volume is drawn as a
      bar chart below the prices, colored by the direction of the price.
      """
    ],
    volume_height: [
      type: :pos_integer,
      default: 60,
      doc: "The height of the volume chart in pixels, if `:volume` is set.",
      section: :style
    ]
  ]

  @candlestick_opts Tucan.Options.take!([@global_opts, @global_mark_opts], @volume_opts)
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

  With the traded volume below the prices, here for generated data:

  ```tucan
  :rand.seed(:exsss, {1, 2, 3})

  {data, _close} =
    Enum.map_reduce(Date.range(~D[2024-03-01], ~D[2024-05-31]), 100.0, fn date, previous ->
      open = previous + :rand.normal()
      close = open + 2 * :rand.normal()
      high = max(open, close) + abs(:rand.normal())
      low = min(open, close) - abs(:rand.normal())
      volume = round(1_000_000 * (1 + abs(close - open)) * (0.5 + :rand.uniform()))

      {%{date: date, open: open, high: high, low: low, close: close, volume: volume}, close}
    end)

  Tucan.Finance.candlestick(data, "date", "open", "high", "low", "close",
    volume: "volume",
    width: 450,
    height: 200
  )
  ```

  With `:volume` set the plot is a vertical concatenation of the prices and the
  volume, sharing the time axis. The price axis is titled `"Price"`, and functions
  that expect a single or layered view, e.g. `Tucan.Axes.set_y_title/2`, cannot be
  applied to it.
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

    color = [
      condition: [test: "datum.#{open} < datum.#{close}", value: "#06982d"],
      value: "#ae1325"
    ]

    mark_opts = Tucan.Options.take_options(opts, @candlestick_opts, :mark)

    rule_layer =
      Vl.new()
      |> Vl.mark(:rule, mark_opts)
      |> Vl.encode_field(:x, timestamp, type: :temporal)
      |> Vl.encode_field(:y, low, type: :quantitative, scale: [zero: false])
      |> Vl.encode_field(:y2, high, type: :quantitative)
      |> Tucan.Utils.maybe_zoomable(opts[:zoomable])

    bar_layer =
      Vl.new()
      |> Vl.mark(:bar, mark_opts)
      |> Vl.encode_field(:x, timestamp, type: :temporal)
      |> Vl.encode_field(:y, open, type: :quantitative, scale: [zero: false])
      |> Vl.encode_field(:y2, close, type: :quantitative)
      |> Vl.encode(:color, color)

    price_plot(plotdata, [rule_layer, bar_layer], timestamp, color, spec_opts, opts)
  end

  # A layered plot of the prices, with the volume below it if set
  defp price_plot(plotdata, layers, timestamp, color, spec_opts, opts) do
    case opts[:volume] do
      nil ->
        plotdata
        |> Tucan.new(spec_opts)
        |> Tucan.layers(layers)

      volume ->
        prices =
          Vl.new(Keyword.take(spec_opts, [:width, :height]))
          |> Tucan.layers(layers)
          |> Tucan.Axes.put_options(:x, title: nil, labels: false)
          |> Tucan.Axes.put_options(:y, title: "Price")

        volumes =
          Vl.new(Keyword.take(spec_opts, [:width]) ++ [height: opts[:volume_height]])
          |> Vl.mark(:bar, Keyword.take(opts, [:tooltip]))
          |> Vl.encode_field(:x, timestamp, type: :temporal)
          |> Vl.encode_field(:y, volume, type: :quantitative, title: "Volume")
          |> Vl.encode(:color, color)

        # the data and the title are set on the concatenated plot
        plotdata
        |> Tucan.new(Keyword.take(spec_opts, [:title, :only]))
        |> Vl.concat([prices, volumes], :vertical)
        |> Vl.resolve(:scale, x: :shared)
    end
  end
end
