defmodule Tucan do
  @moduledoc """
  Documentation for `Tucan`.
  """
  alias VegaLite, as: Vl

  def new, do: VegaLite.new()

  defdelegate histogram(plot, field, opts \\ []), to: Tucan.Plots
  defdelegate scatter(plot, x, y, opts \\ []), to: Tucan.Plots
  defdelegate stripplot(plot, field, opts \\ []), to: Tucan.Plots

  # def boxplot(data, x, y, opts) do
  #   new()
  #   |> data(data)
  #   |> Vl.mark(:boxplot, extent: "min-max")
  #   |> Vl.encode_field(:x, x, type: :nominal)
  #   |> Vl.encode_field(:y, y, type: :quantitative, scale: [zero: false])
  # end
  #
  # def histogram(data, x, opts \\ []) do
  #   Vl.new()
  #   |> data(data)
  #   |> Vl.mark(:bar, fill_opacity: 0.5)
  #   |> Vl.encode_field(:x, x, bin: [step: 0.5])
  #   |> Vl.encode_field(:y, x, aggregate: "count")
  # end

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
end
