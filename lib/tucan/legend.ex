defmodule Tucan.Legend do
  @moduledoc """
  Helper utilities for configuring the plot legend.
  """
  alias Tucan.Utils

  @legend_channels [:color, :size, :shape]

  @doc """
  Sets the title of the given legend.

  You can optionally pass any title option supported by vega-lite to customize the
  style of it.

  Applicable only on plots with a legend.

  ## Examples

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length", color_by: "species")
  |> Tucan.Legend.set_title(:color, "Iris Species", title_color: "red", title_font_weight: 300)
  ```
  """
  @spec set_title(
          vl :: VegaLite.t(),
          channel :: atom(),
          title :: String.t() | nil,
          opts :: keyword()
        ) :: VegaLite.t()
  def set_title(vl, channel, title, opts \\ [])
      when is_struct(vl, VegaLite) and is_atom(channel) and is_list(opts) do
    title_opts = Keyword.merge(opts, title: title)
    put_legend_options(vl, channel, title_opts, "set_title/4")
  end

  @legend_orientations ~w(left right top bottom top-left top-right bottom-left bottom-right none)

  @doc """
  Sets the legend orientation with respect to the scene.

  You need to define the `channel` for which the legend will be configured. Orientation
  can be one of the following: `#{inspect(@legend_orientations)}`.

  Applicable only on plots with a legend.

  ## Examples

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.color_by("species")
  |> Tucan.shape_by("species")
  |> Tucan.Legend.set_orientation(:color, "bottom")
  |> Tucan.Legend.set_orientation(:shape, "top")
  ```
  """
  @spec set_orientation(vl :: VegaLite.t(), channel :: atom(), orientation :: String.t()) ::
          VegaLite.t()
  def set_orientation(vl, channel, orientation)
      when is_struct(vl, VegaLite) and is_atom(channel) and is_binary(orientation) do
    validate_inclusion!(orientation, @legend_orientations, "invalid legend orientation")
    put_legend_options(vl, channel, [orient: orientation], "set_orientation/3")
  end

  @doc """
  Enables or disables the legend of the given encoding channel.
  """
  @spec set_enabled(vl :: VegaLite.t(), channel :: atom(), enabled :: boolean()) :: VegaLite.t()
  def set_enabled(vl, channel, enabled) do
    if enabled do
      vl
    else
      Utils.put_encoding_options(vl, channel, legend: nil)
    end
  end

  @doc """
  Sets the offset in pixels by which to displace the legend from the data rectangle
  and axes.

  If not set defaults to 18 pixels.

  ## Examples

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.color_by("species")
  |> Tucan.Legend.set_offset(:color, 5)
  ```
  """
  @spec set_offset(vl :: VegaLite.t(), channel :: atom(), offset :: integer()) :: VegaLite.t()
  def set_offset(vl, channel, offset) do
    put_legend_options(vl, channel, [offset: offset], "set_offset/3")
  end

  @doc """
  Set arbitrary options to the legend of the given channel.

  The options are deep merged with existing options.

  ## Examples

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.color_by("species")
  |> Tucan.Legend.put_options(:color, fill_color: "yellow", offset: 5, padding: 2, label_font_size: 14)
  ```
  """
  @spec put_options(vl :: VegaLite.t(), channel :: atom(), opts :: keyword()) :: VegaLite.t()
  def put_options(vl, channel, opts)
      when is_struct(vl, VegaLite) and is_atom(channel) and is_list(opts) do
    put_legend_options(vl, channel, opts, "put_legend_options/3")
  end

  defp put_legend_options(vl, channel, opts, caller) do
    validate_inclusion!(channel, @legend_channels, "#{caller}: invalid legend channel")

    Utils.put_encoding_options(vl, channel, legend: opts)
  end

  defp validate_inclusion!(value, allowed, message) do
    if value not in allowed do
      raise ArgumentError, "#{message}, allowed: #{inspect(allowed)}, got: #{inspect(value)}"
    end

    :ok
  end
end
