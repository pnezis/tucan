defmodule Tucan.Grid do
  @moduledoc """
  Helper utilities for customizing a plot's grid.
  """

  @doc """
  Enables or disables the grid for the plot.

  Notice that the grid is enabled by default.

  See also `set_enabled/3` for enabling/disabling specific axis' grid.

  ## Examples

  A scatter plot with the grid disabled:

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Grid.set_enabled(false)
  ```
  """
  @spec set_enabled(vl :: VegaLite.t(), enabled :: boolean()) :: VegaLite.t()
  def set_enabled(vl, enabled) when is_struct(vl, VegaLite) and is_boolean(enabled) do
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

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Grid.set_enabled(:y, false)
  ```
  """
  @spec set_enabled(vl :: VegaLite.t(), channel :: atom(), enabled :: boolean()) ::
          VegaLite.t()
  def set_enabled(vl, channel, enabled) do
    Tucan.VegaLiteUtils.put_encoding_options(vl, channel, axis: [grid: enabled])
  end

  @doc """
  Set a specific color to the grid for the given channel.

  This will raise if the `channel` is not encoded.

  ## Examples

  A scatter plot with the `y-axis` grid colored red and `x-axis` grid with a custom RGB color:

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Grid.set_color(:y, "red")
  |> Tucan.Grid.set_color(:x, "#2A32F4")
  ```
  """
  @spec set_color(vl :: VegaLite.t(), channel :: atom(), color :: binary()) ::
          VegaLite.t()
  def set_color(vl, channel, color)
      when is_struct(vl, VegaLite) and is_atom(channel) and is_binary(color) do
    Tucan.VegaLiteUtils.put_encoding_options(vl, channel, axis: [grid_color: color])
  end

  @doc """
  Sets the opacity of the grid lines.

  If not set it defaults to 1.

  This will raise if the `channel` is not encoded.

  ## Examples

  A scatter plot with the `y-axis` grid colored red and `x-axis` grid with a custom RGB color and
  opacity values set. Also the width is increased to make the opacity changes more clear.

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Grid.set_color(:x, "red")
  |> Tucan.Grid.set_color(:y, "cyan")
  |> Tucan.Grid.set_opacity(:x, 0.1)
  |> Tucan.Grid.set_opacity(:y, 0.8)
  |> Tucan.Grid.set_width(:x, 3)
  |> Tucan.Grid.set_width(:y, 3)
  ```
  """
  @spec set_opacity(vl :: VegaLite.t(), channel :: atom(), opacity :: float()) ::
          VegaLite.t()
  def set_opacity(vl, channel, opacity)
      when is_struct(vl, VegaLite) and is_atom(channel) and is_number(opacity) and opacity >= 0 and
             opacity <= 1 do
    Tucan.VegaLiteUtils.put_encoding_options(vl, channel, axis: [grid_opacity: opacity])
  end

  @doc """
  Sets the width of the grid lines.

  If not set it defaults to 1.

  This will raise if the `channel` is not encoded.
  """
  @spec set_width(vl :: VegaLite.t(), channel :: atom(), width :: pos_integer()) ::
          VegaLite.t()
  def set_width(vl, channel, width)
      when is_struct(vl, VegaLite) and is_atom(channel) and is_integer(width) and width > 0 do
    Tucan.VegaLiteUtils.put_encoding_options(vl, channel, axis: [grid_width: width])
  end

  @doc """
  Sets the dash style of the grid.

  `stroke` and `space` are alternative lengths for the dashed grid lines in pixels.

  This will raise if the `channel` is not encoded.

  ## Examples

  A scatter plot with the different dashed styles across the two axes:

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Grid.set_dash_style(:x, 10, 2)
  |> Tucan.Grid.set_dash_style(:y, 2, 10)
  ```
  """
  @spec set_dash_style(
          vl :: VegaLite.t(),
          channel :: atom(),
          stroke :: pos_integer(),
          space :: pos_integer()
        ) ::
          VegaLite.t()
  def set_dash_style(vl, channel, stroke, space)
      when is_struct(vl, VegaLite) and is_atom(channel) and is_integer(stroke) and stroke > 0 and
             is_integer(space) and space > 0 do
    Tucan.VegaLiteUtils.put_encoding_options(vl, channel, axis: [grid_dash: [stroke, space]])
  end
end
