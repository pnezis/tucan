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

  ## Selectable legends

  `Tucan.Legend.set_selectable/3` makes the entries of a legend clickable: clicking an
  entry highlights its data and fades the rest, which helps with plots of many
  overlapping series.

  ```tucan
  Tucan.lineplot(:stocks, "date", "price", color_by: "symbol", x: [type: :temporal], width: 400)
  |> Tucan.Legend.set_selectable(:color)
  ```

  ## Hover

  `crosshair/2` follows the mouse with a vertical rule, highlighting the values of all
  series at the hovered _x_ value, e.g. for comparing several time series.

  ```tucan
  Tucan.lineplot(:stocks, "date", "price", color_by: "symbol", x: [type: :temporal], width: 400)
  |> Tucan.Interactive.crosshair()
  ```

  ## Widgets

  `slider/3` and `dropdown/3` add input widgets below the plot that filter its rows,
  e.g. to show the data of a single year or of a single category.

  ```tucan
  :stocks
  |> Tucan.lineplot("date", "price", color_by: "symbol", x: [type: :temporal], width: 400)
  |> Tucan.Interactive.dropdown("symbol", options: ["AAPL", "AMZN", "GOOG", "IBM", "MSFT"])
  ```

  ## Overview and detail

  `overview_detail/2` adds a small overview of the whole plot below it. Dragging on the
  overview selects the interval of the _x_ axis shown in the plot, which is useful for
  exploring long series.

  ```tucan
  :stocks
  |> Tucan.lineplot("date", "price", color_by: "symbol", x: [type: :temporal], width: 500)
  |> Tucan.Interactive.overview_detail()
  ```

  ## Linked brushing

  `brush/2` links the plots of a concatenated plot: the rows selected by dragging a
  rectangle on any of them are highlighted in all of them.

  > #### Combining interactions {: .warning}
  >
  > Zooming, panning and brushing are all controlled by dragging the mouse, so a plot
  > should use only one of them.
  """

  alias VegaLite, as: Vl

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

  crosshair_opts = [
    rule_color: [
      type: :string,
      default: "gray",
      doc: "The color of the vertical rule."
    ],
    point_size: [
      type: :pos_integer,
      default: 50,
      doc: "The size of the highlighted points."
    ]
  ]

  @crosshair_schema NimbleOptions.new!(crosshair_opts)

  @doc """
  Adds an interactive crosshair to a plot.

  When hovering over the plot, a vertical rule is drawn at the nearest _x_ value, and
  the points of all series at this value are highlighted, with a tooltip showing their
  values. It is useful for comparing the values of several series, e.g. of a line
  plot, at the same point in time.

  The plot must be a single view plot with an _x_ and a _y_ field encoding, e.g. a
  `Tucan.lineplot/4` or a `Tucan.area/4`. Its color encoding, if any, is used for the
  points. The plot is turned into a layered plot, with the original marks as its first
  layer.

  ## Options

  #{NimbleOptions.docs(@crosshair_schema)}

  ## Examples

  Hover over the plot to compare the prices of the stocks:

  ```tucan
  Tucan.lineplot(:stocks, "date", "price", color_by: "symbol", x: [type: :temporal], width: 400)
  |> Tucan.Interactive.crosshair()
  ```
  """
  @spec crosshair(vl :: VegaLite.t(), opts :: keyword()) :: VegaLite.t()
  def crosshair(vl, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @crosshair_schema)
    Tucan.Utils.validate_single_view!(vl, "crosshair/2")

    mark = vl.spec["mark"]
    encoding = vl.spec["encoding"] || %{}

    x = encoding["x"] || raise ArgumentError, "crosshair/2 expects a plot with an x encoding"
    y = encoding["y"] || raise ArgumentError, "crosshair/2 expects a plot with a y encoding"
    color = encoding["color"]

    hover = %{
      "name" => "_hover",
      "select" => %{
        "type" => "point",
        "fields" => [x["field"]],
        "nearest" => true,
        "on" => "pointerover",
        "clear" => "pointerout"
      }
    }

    highlighted = fn value ->
      %{"condition" => %{"param" => "_hover", "empty" => false, "value" => value}, "value" => 0}
    end

    tooltip =
      [x, y, color]
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&Map.take(&1, ["field", "type", "aggregate", "timeUnit", "title"]))

    # the params of the plot, e.g. the zoom of zoomable plots, are moved to the layer
    # of its marks, since a layered plot cannot have selection params
    plot_layer =
      Map.merge(
        %{"mark" => mark, "encoding" => encoding},
        Map.take(vl.spec, ["params"])
      )

    layers = [
      plot_layer,
      # the invisible points that select the nearest x value
      %{
        "params" => [hover],
        "mark" => %{"type" => "point", "opacity" => 0},
        "encoding" => %{"x" => x}
      },
      %{
        "mark" => %{"type" => "rule", "color" => opts[:rule_color]},
        "encoding" => %{"x" => x, "opacity" => highlighted.(1)}
      },
      %{
        "mark" => %{"type" => "point", "filled" => true, "size" => opts[:point_size]},
        "encoding" =>
          Map.merge(
            %{"x" => x, "y" => y, "opacity" => highlighted.(1), "tooltip" => tooltip},
            if(color, do: %{"color" => color}, else: %{})
          )
      }
    ]

    update_in(vl.spec, fn spec ->
      spec
      |> Map.drop(["mark", "encoding", "params"])
      |> Map.put("layer", layers)
    end)
  end

  slider_opts = [
    min: [
      type: {:or, [:integer, :float]},
      doc: """
      The minimum value of the slider. If not set it is the minimum value of the field,
      which is possible only if the data are passed inline.
      """
    ],
    max: [
      type: {:or, [:integer, :float]},
      doc: """
      The maximum value of the slider. If not set it is the maximum value of the field,
      which is possible only if the data are passed inline.
      """
    ],
    step: [
      type: {:or, [:integer, :float]},
      default: 1,
      doc: "The step of the slider."
    ],
    value: [
      type: {:or, [:integer, :float]},
      doc: "The initial value of the slider. Defaults to the minimum value."
    ],
    mode: [
      type: {:in, [:equal, :up_to]},
      default: :equal,
      doc: """
      How the data are filtered, `:equal` shows only the rows with the selected value,
      `:up_to` shows the rows up to and including the selected value.
      """
    ],
    label: [
      type: :string,
      doc: "The label of the slider. Defaults to the field."
    ]
  ]

  @slider_schema NimbleOptions.new!(slider_opts)

  @doc """
  Adds a slider that filters the data of the plot by the value of a numeric `field`.

  Moving the slider updates the plot, e.g. to show the data of a single year. The
  slider is drawn below the plot.

  The rows are filtered before any other transform of the plot, so aggregations, e.g.
  of a histogram, are computed on the filtered rows. Plots whose layers have their own
  data are not filtered.

  ## Options

  #{NimbleOptions.docs(@slider_schema)}

  ## Examples

  The famous Gapminder chart, move the slider to see how the fertility and the life
  expectancy of the countries changed over the years:

  ```tucan
  "https://vega.github.io/vega-datasets/data/gapminder.json"
  |> Tucan.bubble("fertility", "life_expect", "pop", color_by: "cluster", width: 400)
  |> Tucan.Interactive.slider("year", min: 1955, max: 2005, step: 5)
  |> Tucan.Scale.set_x_domain(0, 9)
  |> Tucan.Scale.set_y_domain(20, 85)
  ```

  Showing all the data up to the selected value:

  ```tucan
  data = for x <- 0..100, do: %{x: x, y: :math.sin(x / 10)}

  Tucan.lineplot(data, "x", "y", width: 400)
  |> Tucan.Interactive.slider("x", mode: :up_to, value: 50)
  |> Tucan.Scale.set_x_domain(0, 100)
  ```
  """
  @spec slider(vl :: VegaLite.t(), field :: String.t(), opts :: keyword()) :: VegaLite.t()
  def slider(vl, field, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @slider_schema)

    {min, max} =
      case {opts[:min], opts[:max]} do
        {min, max} when is_number(min) and is_number(max) -> {min, max}
        {min, max} -> inferred_extent!(vl, field, min, max)
      end

    name = control_param_name("slider", field)

    operator =
      case opts[:mode] do
        :equal -> "=="
        :up_to -> "<="
      end

    vl
    |> Vl.param(name,
      value: opts[:value] || min,
      bind: [
        input: :range,
        min: min,
        max: max,
        step: opts[:step],
        name: "#{opts[:label] || field} "
      ]
    )
    |> prepend_filter("datum[#{Jason.encode!(field)}] #{operator} #{name}")
  end

  defp inferred_extent!(vl, field, min, max) do
    values =
      case get_in(vl.spec, ["data", "values"]) do
        rows when is_list(rows) -> rows |> Enum.map(& &1[field]) |> Enum.filter(&is_number/1)
        _other -> []
      end

    if values == [] do
      raise ArgumentError,
            "cannot infer the range of #{inspect(field)}, set the :min and :max options"
    end

    {min || Enum.min(values), max || Enum.max(values)}
  end

  # the names of the params of the controls must be valid identifiers
  defp control_param_name(prefix, field) do
    "#{prefix}_" <> String.replace(field, ~r/[^A-Za-z0-9_]/, "_")
  end

  # the filters of the controls are applied before any other transform
  defp prepend_filter(vl, expression) do
    update_in(vl.spec, fn spec ->
      Map.update(
        spec,
        "transform",
        [%{"filter" => expression}],
        &[%{"filter" => expression} | &1]
      )
    end)
  end

  dropdown_opts = [
    options: [
      type: {:list, {:or, [:string, :integer, :float, :boolean]}},
      doc: """
      The values of the dropdown. If not set the distinct values of the field are used,
      which is possible only if the data are passed inline.
      """
    ],
    value: [
      type: {:or, [:string, :integer, :float, :boolean]},
      doc: """
      The initial value of the dropdown. If not set all data are shown if `:all` is
      enabled, otherwise the first option is selected.
      """
    ],
    all: [
      type: {:or, [:boolean, :string]},
      default: true,
      doc: """
      Whether to include an option for showing all the data. If a string is passed it
      is used as the label of this option, defaults to `"All"`.
      """
    ],
    label: [
      type: :string,
      doc: "The label of the dropdown. Defaults to the field."
    ]
  ]

  @dropdown_schema NimbleOptions.new!(dropdown_opts)

  @doc """
  Adds a dropdown that filters the data of the plot by the selected value of `field`.

  It is useful for focusing on a single category of a plot with many categories. The
  dropdown is drawn below the plot.

  As with `slider/3`, the rows are filtered before any other transform of the plot,
  and plots whose layers have their own data are not filtered.

  ## Options

  #{NimbleOptions.docs(@dropdown_schema)}

  ## Examples

  Select a stock to show only its prices:

  ```tucan
  :stocks
  |> Tucan.lineplot("date", "price", color_by: "symbol", x: [type: :temporal], width: 400)
  |> Tucan.Interactive.dropdown("symbol", options: ["AAPL", "AMZN", "GOOG", "IBM", "MSFT"])
  ```

  Without an option for showing all data, the first option is initially selected:

  ```tucan
  :penguins
  |> Tucan.scatter("Beak Length (mm)", "Beak Depth (mm)", color_by: "Island", width: 400)
  |> Tucan.Interactive.dropdown("Island", options: ["Biscoe", "Dream", "Torgersen"], all: false)
  ```
  """
  @spec dropdown(vl :: VegaLite.t(), field :: String.t(), opts :: keyword()) :: VegaLite.t()
  def dropdown(vl, field, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @dropdown_schema)

    options = opts[:options] || inferred_options!(vl, field)
    name = control_param_name("dropdown", field)

    {values, labels, initial, filter} =
      case opts[:all] do
        false ->
          {options, options, Keyword.get(opts, :value, hd(options)),
           "datum[#{Jason.encode!(field)}] == #{name}"}

        all ->
          label = if is_binary(all), do: all, else: "All"

          {[nil | options], [label | options], opts[:value],
           "#{name} == null || datum[#{Jason.encode!(field)}] == #{name}"}
      end

    vl
    |> Vl.param(name,
      value: initial,
      bind: [
        input: :select,
        options: values,
        labels: Enum.map(labels, &to_string/1),
        name: "#{opts[:label] || field} "
      ]
    )
    |> prepend_filter(filter)
  end

  defp inferred_options!(vl, field) do
    values =
      case get_in(vl.spec, ["data", "values"]) do
        rows when is_list(rows) ->
          rows |> Enum.map(& &1[field]) |> Enum.reject(&is_nil/1) |> Enum.uniq()

        _other ->
          []
      end

    if values == [] do
      raise ArgumentError,
            "cannot infer the options of #{inspect(field)}, set the :options option"
    end

    values
  end

  overview_detail_opts = [
    overview_height: [
      type: :pos_integer,
      default: 60,
      doc: "The height of the overview plot in pixels."
    ],
    spacing: [
      type: :non_neg_integer,
      default: 20,
      doc: "The spacing between the detail and the overview plots in pixels."
    ]
  ]

  @overview_detail_schema NimbleOptions.new!(overview_detail_opts)

  @overview_param "_overview"

  @doc """
  Adds an overview of the plot below it, selecting an interval on the overview zooms
  the detail plot to it.

  It is useful for long series, e.g. time series spanning many years. The overview
  is a smaller copy of the plot showing all the data. Drag on it to select the x-axis
  interval shown in the detail plot, drag the selection to move it and double click
  to reset it.

  > #### Supported plots {: .info}
  >
  > The overview is a copy of the plot, so it works with single view and layered plots
  > with a quantitative or temporal x-axis, e.g. line, area and scatter plots. It
  > raises for concatenated and faceted plots. The overview replaces the zoom of
  > zoomable plots, and the other interactions of the plot, e.g. a selectable legend,
  > are kept only on the detail plot.

  ## Options

  #{NimbleOptions.docs(@overview_detail_schema)}

  ## Examples

  Select an interval of the overview to see the prices of the stocks in detail:

  ```tucan
  :stocks
  |> Tucan.lineplot("date", "price", color_by: "symbol", x: [type: :temporal], width: 500)
  |> Tucan.Interactive.overview_detail()
  ```

  Layered plots are supported as well:

  ```tucan
  data = for x <- 0..200, do: %{x: x, y: :math.sin(x / 8) * x}

  Tucan.layers([
    Tucan.area(data, "x", "y", fill_opacity: 0.3),
    Tucan.lineplot(data, "x", "y")
  ])
  |> Tucan.set_size(500, 200)
  |> Tucan.Interactive.overview_detail(overview_height: 80)
  ```
  """
  @spec overview_detail(vl :: VegaLite.t(), opts :: keyword()) :: VegaLite.t()
  def overview_detail(vl, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @overview_detail_schema)

    if Enum.any?(["concat", "hconcat", "vconcat", "facet", "repeat"], &Map.has_key?(vl.spec, &1)) do
      raise ArgumentError,
            "overview_detail/2 expects a single view or layered plot, got: #{inspect(vl)}"
    end

    {top, view} = Map.split(vl.spec, ["$schema", "data", "title", "config"])

    # the zoom of zoomable plots binds the scales, overriding the domain selected on the
    # overview, so it is dropped from the detail as well
    detail =
      update_views(view, fn view ->
        view
        |> drop_scale_bindings()
        |> put_in_x_scale("domain", %{"param" => @overview_param})
        |> clip_mark()
      end)

    # the overview is used only for selecting the interval, so the params of the plot,
    # e.g. the zoom of zoomable plots, are dropped from it
    overview =
      view
      |> update_views(&Map.delete(&1, "params"))
      |> Map.put("height", opts[:overview_height])
      |> update_first_view(&add_overview_param/1)

    %VegaLite{
      vl
      | spec: Map.merge(top, %{"vconcat" => [detail, overview], "spacing" => opts[:spacing]})
    }
  end

  defp drop_scale_bindings(%{"params" => params} = view) do
    case Enum.reject(params, &(&1["bind"] == "scales")) do
      [] -> Map.delete(view, "params")
      params -> %{view | "params" => params}
    end
  end

  defp drop_scale_bindings(view), do: view

  defp update_views(%{"layer" => layers} = view, fun),
    do: %{view | "layer" => Enum.map(layers, &update_views(&1, fun))}

  defp update_views(view, fun), do: fun.(view)

  defp update_first_view(%{"layer" => [first | rest]} = view, fun),
    do: %{view | "layer" => [update_first_view(first, fun) | rest]}

  defp update_first_view(view, fun), do: fun.(view)

  defp put_in_x_scale(%{"encoding" => %{"x" => _x}} = view, key, value) do
    update_in(view, ["encoding", "x"], fn x ->
      Map.update(x, "scale", %{key => value}, &Map.put(&1, key, value))
    end)
  end

  defp put_in_x_scale(view, _key, _value), do: view

  # marks outside the zoomed domain should not be drawn outside the plot
  defp clip_mark(%{"mark" => mark} = view) when is_binary(mark),
    do: %{view | "mark" => %{"type" => mark, "clip" => true}}

  defp clip_mark(%{"mark" => mark} = view), do: %{view | "mark" => Map.put(mark, "clip", true)}

  defp add_overview_param(view) do
    param = %{
      "name" => @overview_param,
      "select" => %{"type" => "interval", "encodings" => ["x"]}
    }

    Map.update(view, "params", [param], &(&1 ++ [param]))
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
