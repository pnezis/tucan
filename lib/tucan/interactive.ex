defmodule Tucan.Interactive do
  @moduledoc """
  Interactive plots.

  Tucan plots are rendered by Vega-Lite, which supports interaction through mouse
  gestures and input widgets. The functions of this module add interactions to
  existing plots, e.g. linking the plots of a concatenated plot with a brush.

  > #### Rendering {: .info}
  >
  > Interactions need a live renderer, e.g. Livebook, an exported HTML page or these
  > docs. Static exports, e.g. PNG or SVG files, show the initial state of the plot.

  ## Zooming and panning

  Most plots support zooming and panning by setting their `:zoomable` option. Scroll
  to zoom, drag to pan and double click to reset the view.

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length", zoomable: true)
  ```

  ## Tooltips

  Most plots show a tooltip when hovering over their marks if their `:tooltip` option
  is set. With `tooltip: true` the tooltip shows the encoded fields, and with
  `tooltip: :data` all the fields of the hovered row.

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length", color_by: "species", tooltip: :data)
  ```

  ## Linked brushing

  `brush/2` links the plots of a concatenated plot: the rows selected by dragging a
  rectangle on any of them are highlighted in all of them.

  > #### Combining interactions {: .warning}
  >
  > Zooming, panning and brushing are all controlled by dragging the mouse, so a plot
  > should use only one of them.
  """

  brush_opts = [
    unselected_opacity: [
      type: {:custom, Tucan.Options, :number_between, [0, 1]},
      type_doc: "`t:number/0`",
      default: 0.15,
      doc: "The opacity of the data that are not selected by the brush."
    ]
  ]

  @brush_schema NimbleOptions.new!(brush_opts)

  @doc """
  Links the plots of a concatenated plot with a brush.

  Dragging a rectangle, the brush, on any of the plots selects the rows under it, and
  the same rows are highlighted in all plots, while the rest are faded. This is known
  as linked brushing, or brushing and linking, and it shows how a subset of the data
  is distributed across different fields, e.g. where the outliers of one plot are in
  the others. Double click on a plot to clear the brush.

  The plots must be built from the same data, since the selection is matched by the
  fields of the rows.

  The brush is added to the plots that draw one mark per row, e.g. scatter or strip
  plots, on their continuous _x_ and _y_ axes. Plots without continuous axes are
  highlighted but they cannot be brushed.

  > #### Not brushed plots {: .info}
  >
  > Plots that aggregate the rows, e.g. histograms or density plots, are not affected,
  > since a mark of them may contain both selected and unselected rows. Layered plots
  > are not affected either.

  ## Options

  #{NimbleOptions.docs(@brush_schema)}

  ## Examples

  Select some cars on any plot to see where they are on the other:

  ```tucan
  Tucan.hconcat([
    Tucan.scatter(:cars, "Horsepower", "Miles_per_Gallon", color_by: "Origin", width: 250),
    Tucan.scatter(:cars, "Weight_in_lbs", "Acceleration", color_by: "Origin", width: 250)
  ])
  |> Tucan.Interactive.brush()
  ```

  A linked scatter plot and strip plot, with a lower opacity of the unselected rows:

  ```tucan
  Tucan.vconcat([
    Tucan.scatter(:penguins, "Beak Length (mm)", "Beak Depth (mm)", color_by: "Species"),
    Tucan.stripplot(:penguins, "Body Mass (g)", group_by: "Species", style: :jitter)
  ])
  |> Tucan.Interactive.brush(unselected_opacity: 0.05)
  ```
  """
  @spec brush(vl :: VegaLite.t(), opts :: keyword()) :: VegaLite.t()
  def brush(vl, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @brush_schema)

    key =
      Enum.find(["concat", "hconcat", "vconcat"], &Map.has_key?(vl.spec, &1)) ||
        raise ArgumentError, "brush/2 expects a concatenated plot, got: #{inspect(vl)}"

    update_in(vl.spec[key], fn views -> Enum.map(views, &brush_view(&1, opts)) end)
  end

  @brush_param "_brush"

  # transforms that do not keep the input rows
  @aggregating_transforms ["aggregate", "density", "quantile", "regression", "loess", "pivot"]

  # only single views drawing individual rows are brushed
  defp brush_view(%{"mark" => _mark, "encoding" => encoding} = view, opts) do
    if aggregated?(view, encoding) do
      view
    else
      channels =
        for channel <- ["x", "y"],
            get_in(encoding, [channel, "type"]) in ["quantitative", "temporal"],
            do: channel

      view
      |> maybe_add_brush_param(channels)
      |> put_in(["encoding", "opacity"], %{
        "condition" => %{"param" => @brush_param, "value" => 1},
        "value" => opts[:unselected_opacity]
      })
    end
  end

  defp brush_view(view, _opts), do: view

  defp aggregated?(view, encoding) do
    Enum.any?(encoding, fn {_channel, definition} ->
      is_map(definition) and
        (Map.has_key?(definition, "aggregate") or Map.has_key?(definition, "bin"))
    end) or
      Enum.any?(Map.get(view, "transform", []), fn transform ->
        Enum.any?(@aggregating_transforms, &Map.has_key?(transform, &1))
      end)
  end

  defp maybe_add_brush_param(view, []), do: view

  defp maybe_add_brush_param(view, channels) do
    param = %{
      "name" => @brush_param,
      "select" => %{"type" => "interval", "encodings" => channels}
    }

    Map.update(view, "params", [param], &(&1 ++ [param]))
  end
end
