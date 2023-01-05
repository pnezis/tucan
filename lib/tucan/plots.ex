defmodule Tucan.Plots do
  @moduledoc """
  Implementation of common plot types
  """
  alias VegaLite, as: Vl

  def data(vl, data) when is_atom(data), do: data(vl, Tucan.Datasets.dataset(data))
  def data(vl, data) when is_binary(data), do: Vl.data_from_url(vl, data)
  def data(vl, data), do: Vl.data_from_values(vl, data)

  @doc """
  Creates a scatter plot between `x` and `y` fields.

  ## Supported options

  #{NimbleOptions.docs(Tucan.Plots.Options.schema(:scatter))}
  """
  def scatter(data_or_plot, x, y, opts \\ []),
    do: plot(data_or_plot, :scatter, [x: x, y: y], opts)

  def histogram(data_or_plot, field, opts \\ []),
    do: plot(data_or_plot, :histogram, [field: field], opts)

  def stripplot(data_or_plot, field, opts \\ []),
    do: plot(data_or_plot, :stripplot, [field: field], opts)

  defp plot(data_or_plot, type, type_opts, opts) do
    schema = Tucan.Plots.Options.schema(type)

    with plot <- to_vega_plot(data_or_plot),
         {:ok, opts} <- NimbleOptions.validate(opts, schema) do
      do_plot(plot, type, type_opts, opts)
    end
  end

  defp to_vega_plot(%VegaLite{} = plot), do: plot

  defp to_vega_plot(data) do
    data(VegaLite.new(), data)
  end

  defp do_plot(plot, :scatter, type_opts, opts) do
    plot
    |> Vl.mark(:point, opts)
    |> Vl.encode_field(:x, type_opts[:x], type: :quantitative)
    |> Vl.encode_field(:y, type_opts[:y], type: :quantitative)
  end

  defp do_plot(plot, :histogram, type_opts, _opts) do
    plot
    |> Vl.mark(:bar, fill_opacity: 0.5)
    |> Vl.encode_field(:x, type_opts[:field], bin: [step: 0.5])
    |> Vl.encode_field(:y, type_opts[:field], aggregate: "count")
  end

  defp do_plot(plot, :stripplot, type_opts, _opts) do
    plot
    |> Vl.mark(:tick)
    |> Vl.encode_field(:x, type_opts[:field], type: :quantitative)
  end
end
