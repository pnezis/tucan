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

  selectable_opts = [
    unselected_opacity: [
      type: {:custom, Tucan.Options, :number_between, [0, 1]},
      type_doc: "`t:number/0`",
      default: 0.15,
      doc: "The opacity of the data that are not selected."
    ]
  ]

  @selectable_schema NimbleOptions.new!(selectable_opts)

  @doc """
  Makes the legend of the given channel selectable.

  Clicking on an entry of the legend highlights the data of this entry and fades the
  rest. Shift-click selects multiple entries and a double click clears the selection.

  It is applicable on single view and layered plots, with a legend on a field of the
  given channel. In layered plots all layers with the same field are highlighted.

  See also `Tucan.Interactive` for more interactive plots.

  ## Options

  #{NimbleOptions.docs(@selectable_schema)}

  ## Examples

  Click on a symbol of the legend to highlight its stock:

  ```tucan
  Tucan.lineplot(:stocks, "date", "price", color_by: "symbol", x: [type: :temporal], width: 400)
  |> Tucan.Legend.set_selectable(:color)
  ```

  Legends of other channels can be selectable as well:

  ```tucan
  Tucan.scatter(:penguins, "Beak Length (mm)", "Beak Depth (mm)", shape_by: "Island")
  |> Tucan.Legend.set_selectable(:shape, unselected_opacity: 0.05)
  ```
  """
  @spec set_selectable(vl :: VegaLite.t(), channel :: atom(), opts :: keyword()) ::
          VegaLite.t()
  def set_selectable(vl, channel, opts \\ []) when channel in @legend_channels do
    opts = NimbleOptions.validate!(opts, @selectable_schema)
    channel = to_string(channel)

    views = if Utils.layered_view?(vl), do: vl.spec["layer"], else: [vl.spec]

    field =
      Enum.find_value(views, &get_in(&1, ["encoding", channel, "field"])) ||
        raise ArgumentError, "expected a plot with a legend for the #{channel} channel"

    param = %{
      "name" => "_legend",
      "select" => %{"type" => "point", "fields" => [field]},
      "bind" => "legend"
    }

    opacity = %{
      "condition" => %{"param" => "_legend", "value" => 1},
      "value" => opts[:unselected_opacity]
    }

    # the param is added to the first view with the legend field
    {views, _added?} =
      Enum.map_reduce(views, false, fn view, added? ->
        if get_in(view, ["encoding", channel, "field"]) == field do
          view = put_in(view, ["encoding", "opacity"], opacity)

          if added?,
            do: {view, true},
            else: {Map.update(view, "params", [param], &(&1 ++ [param])), true}
        else
          {view, added?}
        end
      end)

    if Utils.layered_view?(vl),
      do: put_in(vl.spec["layer"], views),
      else: %{vl | spec: hd(views)}
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
