defmodule Tucan.Plot do
  @moduledoc false
  alias VegaLite, as: Vl

  @doc """
  Creates a new tucan plot.

  A tucan plot is nothing more than a `VegaLite` plot with `__tucan__`
  metadata key at the root of the spec.
  """
  @spec new(plotdata :: Tucan.plotdata(), opts :: keyword()) :: VegaLite.t()
  def new(plotdata, opts), do: to_vega_plot(plotdata, opts)

  defp to_vega_plot(%VegaLite{} = plot, _opts), do: plot

  defp to_vega_plot(dataset, opts) when is_atom(dataset),
    do: to_vega_plot(Tucan.Datasets.dataset(dataset), opts)

  defp to_vega_plot(dataset, opts) when is_binary(dataset) do
    if opts[:only] do
      raise ArgumentError, "you are not allowed to set :only with a dataset URL"
    end

    opts
    |> new_vl()
    |> Vl.data_from_url(dataset)
  end

  defp to_vega_plot(data, opts) do
    {data_opts, spec_opts} = Keyword.split(opts, [:only])

    data = maybe_transform_data(data)

    spec_opts
    |> new_vl()
    |> Vl.data_from_values(data, data_opts)
  end

  defp new_vl(opts) do
    {tucan_opts, opts} = Keyword.pop(opts, :tucan)

    case tucan_opts do
      nil -> Vl.new(opts)
      tucan_opts -> Vl.new(opts) |> Tucan.Utils.put_in_spec("__tucan__", tucan_opts)
    end
  end

  defp maybe_transform_data(data) do
    case Keyword.keyword?(data) do
      false ->
        data

      true ->
        for {key, column} <- data do
          {key, maybe_nx_to_list(column, key)}
        end
    end
  end

  @compile {:no_warn_undefined, Nx}

  defp maybe_nx_to_list(column, name) when is_struct(column, Nx.Tensor) do
    shape = Nx.shape(column)

    unless valid_shape?(shape) do
      raise ArgumentError,
            "invalid shape for #{name} tensor, expected a 1-d tensor, got a #{inspect(shape)} tensor"
    end

    Nx.to_flat_list(column)
  end

  defp maybe_nx_to_list(column, _name), do: column

  defp valid_shape?({_x}), do: true
  defp valid_shape?({1, _x}), do: true
  defp valid_shape?({_x, 1}), do: true
  defp valid_shape?(_shape), do: false
end
