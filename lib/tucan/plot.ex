defmodule Tucan.Plot do
  @moduledoc false
  alias VegaLite, as: Vl

  @doc """
  Creates a new tucan plot.

  A tucan plot is nothing more than a `VegaLite` plot with `__tucan__`
  metadata key at the root of the spec.
  """
  @spec new(opts :: keyword()) :: VegaLite.t()
  def new(opts) do
    {tucan_opts, opts} = Keyword.pop(opts, :tucan)

    case tucan_opts do
      nil -> Vl.new(opts)
      tucan_opts -> Vl.new(opts) |> Tucan.Utils.put_in_spec("__tucan__", tucan_opts)
    end
  end
end
