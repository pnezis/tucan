defmodule Tucan do
  @moduledoc """
  Documentation for `Tucan`.
  """
  alias VegaLite, as: Vl

  def new, do: VegaLite.new()

  defdelegate histogram(plot, field, opts \\ []), to: Tucan.Plots
  defdelegate scatter(plot, x, y, opts \\ []), to: Tucan.Plots
  defdelegate stripplot(plot, field, opts \\ []), to: Tucan.Plots

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

  def facet_by(vl, faceting_mode, field, opts \\ [])

  def facet_by(vl, :row, field, opts) do
    Vl.encode_field(vl, :row, field, opts)
  end

  def facet_by(vl, :column, field, opts) do
    Vl.encode_field(vl, :column, field, opts)
  end
end
