defmodule Tucan.Grid do
  @moduledoc """
  Helper utilities for customising a plot's grid.
  """

  @doc """
  Enables or disables the grid for the plot.

  Notice that the grid is enabled by default.

  See also `set_grid_enabled/3` for enabling/disabling specific axis' grid.

  ## Examples

  A scatter plot with the grid disabled:

  ```vega-lite
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Grid.set_grid_enabled(false)
  ```
  """
  @spec set_grid_enabled(vl :: VegaLite.t(), enabled :: boolean()) :: VegaLite.t()
  def set_grid_enabled(vl, enabled) when is_struct(vl, VegaLite) and is_boolean(enabled) do
    vl
    |> if_encoding(:x, fn vl ->
      Tucan.VegaLiteUtils.put_encoding_options(vl, :x, axis: [grid: enabled])
    end)
    |> if_encoding(:y, fn vl ->
      Tucan.VegaLiteUtils.put_encoding_options(vl, :y, axis: [grid: enabled])
    end)
  end

  defp if_encoding(vl, channel, fun) do
    if Tucan.VegaLiteUtils.has_encoding?(vl, channel) do
      fun.(vl)
    else
      vl
    end
  end

  @doc """
  Enable or disable the grid of a specific `channel`

  This will raise if the `channel` is not encoded.

  ## Examples

  A scatter plot with the `y-axis` grid disabled:

  ```vega-lite
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Grid.set_grid_enabled(:y, false)
  ```
  """
  @spec set_grid_enabled(vl :: VegaLite.t(), channel :: atom(), enabled :: boolean()) ::
          VegaLite.t()
  def set_grid_enabled(vl, channel, enabled) do
    Tucan.VegaLiteUtils.put_encoding_options(vl, channel, axis: [grid: enabled])
  end
end
