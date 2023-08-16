defmodule Tucan do
  @moduledoc """
  Documentation for `Tucan`.
  """
  alias Tucan.VegaLiteUtils
  alias VegaLite, as: Vl

  @type plotdata :: binary() | Table.Reader.t() | Tucan.Datasets.t() | VegaLite.t()
  @type field :: binary()

  @spec new() :: VegaLite.t()
  def new(), do: VegaLite.new()

  @spec new(plotdata :: plotdata(), opts :: keyword()) :: VegaLite.t()
  def new(plotdata, opts \\ []), do: to_vega_plot(plotdata, opts)

  defp to_vega_plot(%VegaLite{} = plot, _opts), do: plot

  defp to_vega_plot(dataset, opts) when is_atom(dataset),
    do: to_vega_plot(Tucan.Datasets.dataset(dataset), opts)

  defp to_vega_plot(dataset, opts) when is_binary(dataset) do
    Vl.new(width: opts[:width], height: opts[:height], title: opts[:title])
    |> Vl.data_from_url(dataset)
  end

  defp to_vega_plot(data, opts) do
    Vl.new(width: opts[:width], height: opts[:height])
    |> Vl.data_from_values(data)
  end

  ## Plots

  @lineplot_opts Tucan.Options.options([:global, :general_mark])
  @lineplot_schema Tucan.Options.schema!(@lineplot_opts)

  @doc """
  Draw a line plot between `x` and `y`

  ## Options

  #{NimbleOptions.docs(@lineplot_schema)}

  ## Examples

  ```vega-lite
  Tucan.lineplot(:flights, "year", "passengers")
  ```

  ```vega-lite
  months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ]

  Tucan.lineplot(:flights, "year", "passengers")
  |> Tucan.color_by("month", sort: months, type: :nominal)
  |> Tucan.stroke_dash_by("month", sort: months)
  ```
  """
  @doc section: :plots
  @spec lineplot(plotdata :: plotdata(), x :: field(), y :: field(), opts :: keyword()) ::
          VegaLite.t()
  def lineplot(plotdata, x, y, opts \\ []) do
    _opts = NimbleOptions.validate!(opts, @lineplot_schema)

    plotdata
    |> new()
    |> Vl.mark(:line)
    |> Vl.encode_field(:x, x, type: :temporal)
    |> Vl.encode_field(:y, y, type: :quantitative)
  end

  @histogram_opts Tucan.Options.options([:global, :general_mark], [:fill_opacity])
  @histogram_schema Tucan.Options.schema!(@histogram_opts)

  @doc """
  Plots a histogram.

  See also `density/3`

  ## Options

  #{NimbleOptions.docs(@histogram_schema)}

  ## Examples

  ```vega-lite
  Tucan.histogram(:iris, "petal_width")
  ```
  """
  @doc section: :plots
  def histogram(plotdata, field, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @histogram_schema)

    plotdata
    |> new()
    |> Vl.mark(:bar, fill_opacity: opts[:fill_opacity], color: nil)
    |> Vl.encode_field(:x, field, bin: [step: 0.5])
    |> Vl.encode_field(:y, field, aggregate: "count")
  end

  @density_opts Tucan.Options.options([:global, :general_mark, :density_transform], [
                  :color_by,
                  :fill_opacity
                ])
  @density_schema Tucan.Options.schema!(@density_opts)

  @doc """
  Plot the distribution of a numeric variable.

  Density plots allow you to visualize the distribution of a numeric variable for one
  or several groups. If `:color_by` is set then the given field will be used for both
  the coloring of the various groups as well in the density estimation.

  > ### Avoid calling `color_by/3` with a density plot {: .warning}
  >
  > Since the grouping variable must also be used for properly calculating the density
  > transformation you **should avoid calling the `color_by/3` grouping function** after
  > a `density/3` call. Instead use the `:color_by` option, which will ensure that the
  > proper settings are applied to the underlying transformation.
  >
  > Calling `color_by/3` would produce this graph:
  >
  > ```vega-lite
  > Tucan.density(:penguins, "Body Mass (g)")
  > |> Tucan.color_by("Species")
  > ```
  >
  > In the above case the density function has been calculated on the complete dataset
  > and you cannot color by the `Species`. Instead you should use the `:color_by`
  > option which would calculate the density function per group:
  >
  > ```vega-lite
  > Tucan.density(:penguins, "Body Mass (g)", color_by: "Species", fill_opacity: 0.2)
  > ```
  >
  > Alternatively you should use the `:groupby` option in order to group the density
  > tranform by the `Species` field and then apply the `color_by/3` function:
  >
  > ```vega-lite
  > Tucan.density(:penguins, "Body Mass (g)", groupby: ["Species"])
  > |> Tucan.color_by("Species")
  > ```

  See also `histogram/3`.

  ## Options

  #{NimbleOptions.docs(@density_schema)}

  ## Examples

  ```vega-lite
  Tucan.density(:penguins, "Body Mass (g)")
  ```

  It is a common use case to compare the density of several groups in a dataset. Several
  options exist to do so. You can plot all items on the same chart, using transparency and
  annotation to make the comparison possible.

  ```vega-lite
  Tucan.density(:penguins, "Body Mass (g)", color_by: "Species")
  ```

  You can also combine it with `facet_by/4` in order to draw a different plot for each value
  of the grouping variable. Notice that we need to set the `:groupby` variable in order
  to correctly calculate the density plot per field's value.

  ```vega-lite
  Tucan.density(:penguins, "Body Mass (g)", groupby: ["Species"])
  |> Tucan.color_by("Species")
  |> Tucan.facet_by(:column, "Species")
  ```

  You can plot a cumulative density distribution by setting the `:cumulative` option to `true`:

  ```vega-lite
  Tucan.density(:penguins, "Body Mass (g)", cumulative: true)
  ```
  """
  @doc section: :plots
  def density(plotdata, field, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @density_schema)

    transform_opts = Keyword.take(opts, Tucan.Options.section_options(:density_transform))

    transform_opts =
      [density: field]
      |> Keyword.merge(transform_opts)
      |> maybe_put(:groupby, [opts[:color_by]], fn -> opts[:color_by] != nil end)

    plotdata
    |> new(opts)
    |> Vl.transform(transform_opts)
    |> Vl.mark(:area, fill_opacity: opts[:fill_opacity])
    |> Vl.encode_field(:x, "value", type: :quantitative, scale: [zero: false])
    |> Vl.encode_field(:y, "density", type: :quantitative)
    |> maybe_color_by(opts[:color_by])
  end

  defp maybe_put(opts, key, value, condition_fn) do
    case condition_fn.() do
      true -> Keyword.put(opts, key, value)
      false -> opts
    end
  end

  @countplot_opts Tucan.Options.options([:global, :general_mark], [:stacked, :color_by])
  @countplot_schema Tucan.Options.schema!(@countplot_opts)

  @doc """
  Plot the counts of observations for a categorical variable.

  This is similar to `histogram/3` but specifically for a categorical
  variable.

  ## Options

  #{NimbleOptions.docs(@countplot_schema)}

  ## Examples

  We will use the `:titanic` dataset on the following examples.

  Number of passengers by ticket class:

  ```vega-lite
  Tucan.countplot(:titanic, "Pclass")
  ```

  > #### Stacked and grouped bars {: .tip}
  >
  > You can set color_by to group it by a second variable:
  >
  > ```vega-lite
  > Tucan.countplot(:titanic, "Pclass", color_by: "Survived")
  > ```
  >
  > By default the bars are stacked. You can unstack them by setting the
  > stacked option:
  >
  > ```vega-lite
  > Tucan.countplot(:titanic, "Pclass", color_by: "Survived", stacked: false)
  > ```
  """
  @doc section: :plots
  def countplot(plotdata, field, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @countplot_schema)

    plotdata
    |> new()
    |> Vl.mark(:bar, fill_opacity: 0.5)
    |> Vl.encode_field(:x, field, type: :nominal)
    |> Vl.encode_field(:y, field, aggregate: "count")
    |> maybe_color_by(opts[:color_by])
    |> maybe_x_offset(opts[:color_by], opts[:stacked])
  end

  defp maybe_color_by(vl, nil), do: vl
  defp maybe_color_by(vl, field), do: color_by(vl, field)

  defp maybe_x_offset(vl, nil, _stacked), do: vl
  defp maybe_x_offset(vl, _field, true), do: vl
  defp maybe_x_offset(vl, field, false), do: Vl.encode_field(vl, :x_offset, field)

  @scatter_opts Tucan.Options.options([:global, :general_mark])
  @scatter_schema Tucan.Options.schema!(@scatter_opts)

  @doc """
  A scatter plot.

  ## Options

  #{NimbleOptions.docs(@scatter_schema)}

  ## Examples

  > We will use the `:tips` dataset thoughout the following examples.

  Drawing a scatter plot betwen two variables:

  ```vega-lite
  Tucan.scatter(:tips, "total_bill", "tip")
  ```

  You can combine it with `color_by/3` to color code the points:

  ```vega-lite
  Tucan.scatter(:tips, "total_bill", "tip")
  |> Tucan.color_by("time")
  ```

  Assigning the same variable to `shape_by/3` will also vary the markers and create a
  more accessible plot:

  ```vega-lite
  Tucan.scatter(:tips, "total_bill", "tip", width: 400)
  |> Tucan.color_by("time")
  |> Tucan.shape_by("time")
  ```

  Assigning `color_by/3` and `shape_by/3` to different variables will vary colors and
  markers independently:

  ```vega-lite
  Tucan.scatter(:tips, "total_bill", "tip", width: 400)
  |> Tucan.color_by("day")
  |> Tucan.shape_by("time")
  ```

  You can also color the points by a numeric variable, the semantic mapping will be
  quantitative and will use a different default palette:

  ```vega-lite
  Tucan.scatter(:tips, "total_bill", "tip", width: 400)
  |> Tucan.color_by("size", type: :quantitative)
  ```

  A numeric variable can also be assigned to size to apply a semantic mapping to the
  areas of the points:

  ```vega-lite
  Tucan.scatter(:tips, "total_bill", "tip", width: 400, tooltip: :data)
  |> Tucan.color_by("size", type: :quantitative)
  |> Tucan.size_by("size", type: :quantitative)
  ```

  You can also combine it with `facet_by/3` in order to group within additional
  categorical variables, and plot them across multiple subplots.

  ```vega-lite
  Tucan.scatter(:tips, "total_bill", "tip", width: 300)
  |> Tucan.color_by("day")
  |> Tucan.shape_by("day")
  |> Tucan.facet_by(:column, "time")
  ```

  You can also apply faceting on more than one variables, both horizontally and
  vertically:

  ```vega-lite
  Tucan.scatter(:tips, "total_bill", "tip", width: 300)
  |> Tucan.color_by("day")
  |> Tucan.shape_by("day")
  |> Tucan.size_by("size")
  |> Tucan.facet_by(:column, "time")
  |> Tucan.facet_by(:row, "sex")
  ```
  """
  @doc section: :plots
  def scatter(plotdata, x, y, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @scatter_schema)

    plotdata
    |> new(opts)
    |> Vl.mark(:point, Keyword.take(opts, [:tooltip]))
    |> Vl.encode_field(:x, x, type: :quantitative, scale: [zero: false])
    |> Vl.encode_field(:y, y, type: :quantitative, scale: [zero: false])
  end

  @doc """
  A bubble plot is a scatter plot with a third parameter defining the size of the dots required
  by default.

  All `x`, `y` and `size` must be quantitative fields of the dataset.

  See also `scatter/4`.

  ## Examples

  ```vega-lite
  Tucan.bubble(:gapminder, "income", "health", "population", width: 400)
  |> Tucan.Axes.set_x_title("Gdp per Capita")
  |> Tucan.Axes.set_y_title("Life expectancy")
  ```

  You could use a fourth variable to color the graph and set `tooltip` to `:data` in
  order to make it interactive:

  ```vega-lite
  Tucan.bubble(:gapminder, "income", "health", "population", width: 400, tooltip: :data)
  |> Tucan.color_by("region")
  |> Tucan.Axes.set_x_title("Gdp per Capita")
  |> Tucan.Axes.set_y_title("Life expectancy")
  ```
  """
  @doc section: :plots
  @spec bubble(
          plotdata :: plotdata(),
          x :: field(),
          y :: field(),
          size :: field(),
          opts :: keyword()
        ) :: VegaLite.t()
  def bubble(plotdata, x, y, size, opts \\ []) do
    # TODO: validate only bubble options here
    # opts = NimbleOptions.validate!(opts, @scatter_schema)

    scatter(plotdata, x, y, opts)
    |> size_by(size, type: :quantitative)
  end

  stripplot_schema = [
    group: [
      type: :string,
      doc: """
      A field to be used for grouping the strip plot. If not set the plot will
      be one dimensional.
      """
    ],
    style: [
      type: {:in, [:tick, :point, :jitter]},
      doc: """
      The style of the plot. Can be one of the following:
        * `:tick` - use ticks for each data point
        * `:point` - use points for each data point
        * `:jitter` - use points but also apply some jittering across the other
        axis

      Use `:jitter` in case of many data points in order to avoid overlaps.
      """,
      default: :tick
    ]
  ]

  @stripplot_opts Tucan.Options.options([:global, :general_mark], [:orient])
  @stripplot_schema Tucan.Options.schema!(@stripplot_opts, stripplot_schema)

  @doc """
  Draws a strip plot (categorical scatterplot).

  A strip plot is a single-axis scatter plot used to visualize the distribution of
  a numerical field. The values are plotted as dots or ticks along one axis, so
  the dots with the same value may overlap.

  You can use the `:jitter` mode for a better view of overlapping points. In this
  case points are randomnly shifted along with other axis, which has no meaning in
  itself data-wise.

  Typically several strip plots are placed side by side to compare the distribution
  of a numerical value among several categories.

  ## Options

  #{NimbleOptions.docs(@stripplot_schema)}

  > ### Internal `VegaLite` representation {: .info}
  > 
  > If style is set to `:tick` the following `VegaLite` represenation is generated:
  >
  > ```elixir
  > Vl.new()
  > |> Vl.mark(:tick)
  > |> Vl.encode_field(:x, field, type: :quantitative)
  > |> Vl.encode_field(:y, opts[:group], type: :nominal)
  > ```
  >
  > If style is set to `:jitter` then a transform is added to generate Gaussian jitter
  > using the Box-Muller transform, and the `y_offset` is also encoded based on this:
  >
  > ```elixir
  > Vl.new()
  > |> Vl.mark(:point)
  > |> Vl.transform(calculate: "sqrt(-2*log(random()))*cos(2*PI*random())", as: "jitter")
  > |> Vl.encode_field(:x, field, type: :quantitative)
  > |> Vl.encode_field(:y, opts[:group], type: :nominal)
  > |> Vl.encode_field(:y_offset, "jitter", type: :quantitative)
  > ```
  > 

  ## Examples

  Assigning a single numeric variable shows the univariate distribution. The default
  style is the `:tick`:

  ```vega-lite
  Tucan.stripplot(:tips, "total_bill")
  ```

  For very dense distribution it makes more sense to use the `:jitter` style in order
  to reduce overlapping points:

  ```vega-lite
  Tucan.stripplot(:tips, "total_bill", style: :jitter, height: 30, width: 300)
  ```

  You can set the `:group` option in order to add a second dimension. Notice that
  the field must be categorical.


  ```vega-lite
  Tucan.stripplot(:tips, "total_bill", group: "day", style: :jitter)
  ```

  The plot would be more clear if you also colored the points with the same field:

  ```vega-lite
  Tucan.stripplot(:tips, "total_bill", group: "day", style: :jitter)
  |> Tucan.color_by("day")
  ```

  Or you can color by a distinct variable to show a multi-dimensional relationship:

  ```vega-lite
  Tucan.stripplot(:tips, "total_bill", group: "day", style: :jitter)
  |> Tucan.color_by("sex")
  ```

  or you can color by a numerical variable:

  ```vega-lite
  Tucan.stripplot(:tips, "total_bill", group: "day", style: :jitter)
  |> Tucan.color_by("size", type: :ordinal)
  ```

  You could draw the same with points but without jittering:

  ```vega-lite
  Tucan.stripplot(:tips, "total_bill", group: "day", style: :point)
  |> Tucan.color_by("sex")
  ```

  or with ticks which is the default one:

  ```vega-lite
  Tucan.stripplot(:tips, "total_bill", group: "day", style: :tick)
  |> Tucan.color_by("sex")
  ```

  You can set the `:orient` flag to `:vertical` to change the orientation:

  ```vega-lite
  Tucan.stripplot(:tips, "total_bill", group: "day", style: :jitter, orient: :vertical)
  |> Tucan.color_by("sex")
  ```
  """
  @doc section: :plots
  def stripplot(plotdata, x, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @stripplot_schema)

    mark =
      case opts[:style] do
        :tick -> :tick
        _other -> :point
      end

    plot =
      plotdata
      |> new(opts)
      |> Vl.mark(mark, size: 16)
      |> Vl.encode_field(:x, x, type: :quantitative)
      |> maybe_encode_field(:y, fn -> opts[:group] != nil end, opts[:group], type: :nominal)

    case opts[:style] do
      :jitter ->
        plot
        |> Vl.transform(calculate: "sqrt(-2*log(random()))*cos(2*PI*random())", as: "jitter")
        |> Vl.encode_field(:y_offset, "jitter", type: :quantitative, axis: nil)

      _other ->
        plot
    end
    |> maybe_flip_axes(opts[:orient])
  end

  defp maybe_encode_field(vl, channel, condition_fn, field, opts) do
    case condition_fn.() do
      false ->
        vl

      true ->
        Vl.encode_field(vl, channel, field, opts)
    end
  end

  defp maybe_encode(vl, channel, condition_fn, opts) do
    case condition_fn.() do
      false ->
        vl

      true ->
        if is_list(opts) do
          Vl.encode(vl, channel, opts)
        else
          VegaLiteUtils.encode_raw(vl, channel, opts)
        end
    end
  end

  ## Composite plots

  @doc """
  Plot pairwise relationships in a dataset.

  This function expects an array of fields to be provided. A grid will be created
  where each numeric variable in `fields` will be shared acrosss the y-axes across
  a single row and the x-axes across a single column.

  > #### Numerical field types {: .warning}
  >
  > Notice that currently `pairplot/3` works only with numerical (`:quantitative`)
  > variables. If you need to create a pair plot containing other variable types
  > you need to manually build the grid using the `VegaLite` concatenation operations.

  ## Examples

  By default a scatter plot will be drawn for all pairwise plots:

  ```vega-lite
  fields = ["petal_width", "petal_length", "sepal_width", "sepal_length"]

  Tucan.pairplot(:iris, fields, width: 130, height: 130)
  ```
  """
  @doc section: :composite
  def pairplot(plotdata, fields, opts \\ []) when is_list(fields) do
    children =
      for {row_field, row_index} <- Enum.with_index(fields),
          {col_field, col_index} <- Enum.with_index(fields) do
        pairplot_child_spec({row_field, row_index}, {col_field, col_index}, length(fields), opts)
      end

    plotdata
    |> new(title: opts[:title])
    |> Vl.concat(children, :wrappable)
    |> put_spec_field("columns", length(fields))

    # This is a bit hacky but it works for aligning the plots in case
    # of both integer and float axis values
    # |> Vl.config(axis_y: [min_extent: 30])
  end

  defp put_spec_field(vl, name, value) do
    update_in(vl.spec, fn spec -> Map.put(spec, name, value) end)
  end

  defp pairplot_child_spec({row_field, row_index}, {col_field, col_index}, fields_count, opts) do
    x_axis_title = fn vl, row_index ->
      cond do
        row_index == fields_count - 1 ->
          vl

        true ->
          Tucan.Axes.put_axis_options(vl, :x, title: nil)
      end
    end

    y_axis_title = fn vl, col_index ->
      cond do
        col_index == 0 ->
          vl

        true ->
          Tucan.Axes.put_axis_options(vl, :y, title: nil)
      end
    end

    Vl.new(width: opts[:width], height: opts[:height])
    |> Tucan.scatter(col_field, row_field)
    |> x_axis_title.(row_index)
    |> y_axis_title.(col_index)
  end

  ## Grouping functions

  @doc section: :grouping
  def color_by(vl, field, opts \\ []) do
    Vl.encode_field(vl, :color, field, opts)
  end

  # defp encode_recursively(vl, )

  @doc section: :grouping
  def shape_by(vl, field, opts \\ []) do
    Vl.encode_field(vl, :shape, field, opts)
  end

  @doc section: :grouping
  def stroke_dash_by(vl, field, opts \\ []) do
    Vl.encode_field(vl, :stroke_dash, field, opts)
  end

  @doc section: :grouping
  def fill_by(vl, field, opts \\ []) do
    Vl.encode_field(vl, :fill, field, opts)
  end

  @doc section: :grouping
  def size_by(vl, field, opts \\ []) do
    Vl.encode_field(vl, :size, field, opts)
  end

  @doc section: :grouping
  def facet_by(vl, faceting_mode, field, opts \\ [])

  def facet_by(vl, :row, field, opts) do
    Vl.encode_field(vl, :row, field, opts)
  end

  def facet_by(vl, :column, field, opts) do
    Vl.encode_field(vl, :column, field, opts)
  end

  ## Utility functions

  @doc section: :utilities
  def set_width(vl, width) when is_struct(vl, VegaLite) do
    update_in(vl.spec, fn spec -> Map.merge(spec, %{"width" => width}) end)
  end

  @doc section: :utilities
  def set_height(vl, height) when is_struct(vl, VegaLite) do
    update_in(vl.spec, fn spec -> Map.merge(spec, %{"height" => height}) end)
  end

  @doc section: :utilities
  def set_title(vl, title) when is_struct(vl, VegaLite) and is_binary(title) do
    update_in(vl.spec, fn spec -> Map.merge(spec, %{"title" => title}) end)
  end

  @doc """
  Flips the axes of the provided chart.

  This works for both one dimensional and two dimensional charts. All positional channels
  that are defined will be flipped.

  This is used internally by plots that support setting orientation.
  """
  @doc section: :utilities
  @spec flip_axes(vl :: VegaLite.t()) :: VegaLite.t()
  def flip_axes(vl) when is_struct(vl, VegaLite) do
    x = VegaLiteUtils.encoding_options(vl, :x)
    y = VegaLiteUtils.encoding_options(vl, :y)
    x_offset = VegaLiteUtils.encoding_options(vl, :x_offset)
    y_offset = VegaLiteUtils.encoding_options(vl, :y_offset)

    vl
    |> VegaLiteUtils.drop_encoding_channels([:x, :y, :x_offset, :y_offset])
    |> maybe_encode(:x, fn -> !is_nil(y) end, y)
    |> maybe_encode(:x_offset, fn -> !is_nil(y_offset) end, y_offset)
    |> maybe_encode(:y, fn -> !is_nil(x) end, x)
    |> maybe_encode(:y_offset, fn -> !is_nil(x_offset) end, x_offset)
  end

  defp maybe_flip_axes(vl, :horizontal), do: vl
  defp maybe_flip_axes(vl, :vertical), do: flip_axes(vl)
end
