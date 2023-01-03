defmodule Tucan do
  @moduledoc """
  Documentation for `Tucan`.
  """
  alias VegaLite, as: Vl

  def new, do: VegaLite.new()

  def data(vl, data) when is_atom(data), do: data(vl, Tucan.Datasets.dataset(data))
  def data(vl, data) when is_binary(data), do: Vl.data_from_url(vl, data)
  def data(vl, data), do: Vl.data_from_values(vl, data)

  # TODO: make plot either a vegalite or a dataset
  def scatter(plot, x, y, opts \\ [])

  def scatter(%VegaLite{} = plot, x, y, opts) do
    opts = NimbleOptions.validate!(opts, options(:scatter))

    plot
    |> Vl.mark(:point, opts)
    |> Vl.encode_field(:x, x, type: :quantitative)
    |> Vl.encode_field(:y, y, type: :quantitative)
  end

  def scatter(data, x, y, opts) do
    new()
    |> data(data)
    |> scatter(x, y, opts)
  end

  def color_by(vl, field, opts \\ []) do
    Vl.encode_field(vl, :color, field, opts)
  end

  def shape_by(vl, field, opts \\ []) do
    Vl.encode_field(vl, :shape, field, opts)
  end

  def fill_by(vl, field, opts \\ []) do
    Vl.encode_field(vl, :fill, field, opts)
  end

  def size_by(vl, field, opts \\ []) do
    Vl.encode_field(vl, :size, field, opts)
  end

  defp options(:scatter) do
    [
      shape: [
        type:
          {:in,
           [
             :circle,
             :square,
             :cross,
             :diamond,
             :triangle_up,
             :triangle_down,
             :triangle_right,
             :triangle_left
           ]},
        default: :circle,
        doc: """
        Shape of the point mark, for more details check the [Vega-Lite docs](https://vega.github.io/vega-lite/docs/point.html#properties)
        """
      ]
    ]
  end
end
