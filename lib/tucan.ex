defmodule Tucan do
  @moduledoc """
  Documentation for `Tucan`.
  """
  alias Tucan.VegaLiteUtils
  alias VegaLite, as: Vl

  Module.register_attribute(__MODULE__, :schemas, accumulate: true)

  @type plotdata :: binary() | Table.Reader.t() | Tucan.Datasets.t() | VegaLite.t()
  @type field :: binary()

  @doc """
  Creates if needed a `VegaLite` plot and adds data to it.

  The behaviour of this function depends on the type of `plotdata`:

  * if a `VegaLite.t()` struct is passed then it is returned unchanged.
  * If it is a binary it is considered a url and the `VegaLite.data_from_url/2` is
    called on a newly created `VegaLite` struct.
  * if it is an atom then it is considered a `Tucan.Dataset` and it is translated to
    the dataset's url. If the dataset name is invalid an exception is raised.
  * in any other case it is considered a set of data values and the values are set
    as data to a newly created `VegaLite` struct.
  """
  @spec new(plotdata :: plotdata(), opts :: keyword()) :: VegaLite.t()
  def new(plotdata, opts \\ []),
    do: to_vega_plot(plotdata, opts)

  defp to_vega_plot(%VegaLite{} = plot, _opts), do: plot

  defp to_vega_plot(dataset, opts) when is_atom(dataset),
    do: to_vega_plot(Tucan.Datasets.dataset(dataset), opts)

  defp to_vega_plot(dataset, opts) when is_binary(dataset) do
    Vl.new(opts)
    |> Vl.data_from_url(dataset)
  end

  defp to_vega_plot(data, opts) do
    Vl.new(opts)
    |> Vl.data_from_values(data)
  end

  ## Plots

  # global_opts should be applicable in all plot types
  @global_opts [:width, :height, :title]
  @global_mark_opts [:clip, :fill_opacity, :tooltip]

  histogram_opts = [
    relative: [
      type: :boolean,
      doc: """
      If set a relative frequency histogram is generated.
      """,
      default: false
    ],
    orient: [
      type: {:in, [:horizontal, :vertical]},
      doc: """
      Histogram's orientation. It specifies the axis along which the field values
      are plotted.
      """,
      default: :horizontal
    ],
    color_by: [
      type: :string,
      doc: """
      The field to group observations by. This will used for coloring the histogram
      if set.
      """
    ],
    maxbins: [
      type: :integer,
      doc: """
      Maximum number of bins.
      """,
      dest: :bin
    ],
    step: [
      type: {:or, [:integer, :float]},
      doc: """
      An exact step size to use between bins. If provided, options such as `maxbins`
      will be ignored.
      """,
      dest: :bin
    ],
    extent: [
      type: {:custom, Tucan.Options, :extent, []},
      doc: """
      A two-element (`[min, max]`) array indicating the range of desired bin values.
      """,
      dest: :bin
    ],
    stacked: [
      type: :boolean,
      doc: """
      If set it will stack the group histograms instead of layering one over another. Valid
      only if a semantic grouping has been applied.
      """
    ]
  ]

  # TODO: maybe refactor with a macro
  @histogram_opts Tucan.Options.take!(
                    [@global_opts, @global_mark_opts, :x, :x2, :y, :color],
                    histogram_opts
                  )
  @histogram_schema Tucan.Options.to_nimble_schema!(@histogram_opts)
  Module.put_attribute(__MODULE__, :schemas, {:histogram, @histogram_opts})

  @doc """
  Plots a histogram.

  See also `density/3`

  ## Options

  #{Tucan.Options.docs(@histogram_schema)}

  ## Examples

  Histogram of `Horsepower`

  ```tucan
  Tucan.histogram(:cars, "Horsepower")
  ```

  You can flip the plot by setting the `:orient` option to `:vertical`:

  ```tucan
  Tucan.histogram(:cars, "Horsepower", orient: :vertical)
  ```

  By setting the `:relative` flag you can get a relative frequency histogram:

  ```tucan
  Tucan.histogram(:cars, "Horsepower", relative: true)
  ```

  You can increase the number of bins by settings the `maxbins` or the `step` options:

  ```tucan
  Tucan.histogram(:cars, "Horsepower", step: 5)
  ```

  You can draw multiple histograms by grouping the observations by a second
  *categorical* variable:


  ```tucan
  Tucan.histogram(:cars, "Horsepower", color_by: "Origin", fill_opacity: 0.5)
  ```

  By default the histograms are plotted layered, but you can also stack them:

  ```tucan
  Tucan.histogram(:cars, "Horsepower", color_by: "Origin", fill_opacity: 0.5, stacked: true)
  ```

  or you can facet it, in order to make the histograms more clear:

  ```tucan
  histograms =
    Tucan.histogram(:cars, "Horsepower", color_by: "Origin")
    |> Tucan.facet_by(:column, "Origin")

  relative_histograms =
    Tucan.histogram(:cars, "Horsepower", relative: true, color_by: "Origin", fill_opacity: 0.5, tooltip: true)
    |> Tucan.facet_by(:column, "Origin")

  VegaLite.concat(VegaLite.new(), [histograms, relative_histograms], :vertical)
  ```
  """
  @doc section: :plots
  @spec histogram(plotdata :: plotdata(), field :: binary(), opts :: keyword()) :: VegaLite.t()
  def histogram(plotdata, field, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @histogram_schema)

    spec_opts = take_options(opts, @histogram_opts, :spec)
    mark_opts = take_options(opts, @histogram_opts, :mark)

    plotdata
    |> new(spec_opts)
    |> Vl.mark(:bar, mark_opts)
    |> bin_count_transform(field, opts)
    |> maybe_add_relative_frequency_transform(field, opts)
    |> encode_field(:x, "bin_#{field}", opts, bin: [binned: true], title: field)
    |> encode_field(:x2, "bin_#{field}_end", opts)
    |> histogram_y_encoding(field, opts)
    |> maybe_encode_field(:color, fn -> opts[:color_by] != nil end, opts[:color_by], opts, [])
    |> maybe_flip_axes(opts[:orient] == :vertical)
  end

  defp bin_count_transform(vl, field, opts) do
    bin_opts =
      case take_options(opts, @histogram_opts, :bin) do
        [] -> true
        bin_opts -> bin_opts
      end

    groupby =
      case opts[:color_by] do
        nil -> ["bin_#{field}", "bin_#{field}_end"]
        color_by -> ["bin_#{field}", "bin_#{field}_end", color_by]
      end

    vl
    |> Vl.transform(bin: bin_opts, field: field, as: "bin_#{field}")
    |> Vl.transform(
      aggregate: [[op: :count, as: "count_#{field}"]],
      groupby: groupby
    )
  end

  defp maybe_add_relative_frequency_transform(vl, field, opts) do
    case opts[:relative] do
      false ->
        vl

      true ->
        groupby =
          case opts[:color_by] do
            nil -> []
            color_by -> [color_by]
          end

        vl
        |> Vl.transform(
          joinaggregate: [[op: :sum, field: "count_#{field}", as: "total_count_#{field}"]],
          groupby: groupby
        )
        |> Vl.transform(
          calculate: "datum.count_#{field}/datum.total_count_#{field}",
          as: "percent_#{field}"
        )
    end
  end

  defp histogram_y_encoding(vl, field, opts) do
    case opts[:relative] do
      false ->
        encode_field(vl, :y, "count_#{field}", opts, type: :quantitative, stack: opts[:stacked])

      true ->
        encode_field(vl, :y, "percent_#{field}", opts,
          type: :quantitative,
          axis: [format: ".1~%"],
          title: "Relative Frequency",
          stack: opts[:stacked]
        )
    end
  end

  density_opts = [
    groupby: [
      type: {:list, :string},
      doc: """
      The data fields to group by. If not specified, a single group containing all data
      objects will be used. This is applied only on the density transform.

      In most cases you only need to set `color_by` which will automatically handle the
      density transform grouping. Use `groupby` only if you want to manually post-process
      the generated specification, or if you want to apply grouping by more than one
      variable.

      If both `groupby` and `color_by` are set then only `groupby` is used for grouping
      the density transform and `color_by` is used for encoding the color.
      """,
      dest: :density_transform
    ],
    cumulative: [
      type: :boolean,
      doc: """
      A boolean flag indicating whether to produce density estimates (false) or cumulative
      density estimates (true).
      """,
      default: false,
      dest: :density_transform
    ],
    counts: [
      type: :boolean,
      doc: """
      A boolean flag indicating if the output values should be probability estimates
      (false) or smoothed counts (true).
      """,
      default: false,
      dest: :density_transform
    ],
    bandwidth: [
      type: :float,
      doc: """
      The bandwidth (standard deviation) of the Gaussian kernel. If unspecified or set to
      zero, the bandwidth value is automatically estimated from the input data using
      Scott’s rule.
      """,
      dest: :density_transform
    ],
    extent: [
      type: {:custom, Tucan.Options, :extent, []},
      doc: """
      A `[min, max]` domain from which to sample the distribution. If unspecified, the extent
      will be determined by the observed minimum and maximum values of the density value field.
      """,
      dest: :density_transform
    ],
    minsteps: [
      type: :integer,
      doc: """
      The minimum number of samples to take along the extent domain for plotting the density.
      """,
      default: 25,
      dest: :density_transform
    ],
    maxsteps: [
      type: :integer,
      doc: """
      The maximum number of samples to take along the extent domain for plotting the density.
      """,
      default: 200,
      dest: :density_transform
    ],
    steps: [
      type: :integer,
      doc: """
      The exact number of samples to take along the extent domain for plotting the density. If
      specified, overrides both minsteps and maxsteps to set an exact number of uniform samples.
      Potentially useful in conjunction with a fixed extent to ensure consistent sample points
      for stacked densities.
      """,
      dest: :density_transform
    ]
  ]

  @density_opts Tucan.Options.take!(
                  [
                    @global_opts,
                    @global_mark_opts,
                    :color_by,
                    :x,
                    :y,
                    :color
                  ],
                  density_opts
                )
  @density_schema Tucan.Options.to_nimble_schema!(@density_opts)

  @doc """
  Plot the distribution of a numeric variable.

  Density plots allow you to visualize the distribution of a numeric variable for one
  or several groups. If you want to draw the density for several groups you need to
  specify the `:color_by` option which is assumed to be a categorical variable.

  > ### Avoid calling `color_by/3` with a density plot {: .warning}
  >
  > Since the grouping variable must also be used for properly calculating the density
  > transformation you **should avoid calling the `color_by/3` grouping function** after
  > a `density/3` call. Instead use the `:color_by` option, which will ensure that the
  > proper settings are applied to the underlying transformation.
  >
  > Calling `color_by/3` would produce this graph:
  >
  > ```tucan
  > Tucan.density(:penguins, "Body Mass (g)")
  > |> Tucan.color_by("Species")
  > ```
  >
  > In the above case the density function has been calculated on the complete dataset
  > and you cannot color by the `Species`. Instead you should use the `:color_by`
  > option which would calculate the density function per group:
  >
  > ```tucan
  > Tucan.density(:penguins, "Body Mass (g)", color_by: "Species", fill_opacity: 0.2)
  > ```
  >
  > Alternatively you should use the `:groupby` option in order to group the density
  > tranform by the `Species` field and then apply the `color_by/3` function:
  >
  > ```tucan
  > Tucan.density(:penguins, "Body Mass (g)", groupby: ["Species"])
  > |> Tucan.color_by("Species")
  > ```

  See also `histogram/3`.

  ## Options

  #{Tucan.Options.docs(@density_schema)}

  ## Examples

  ```tucan
  Tucan.density(:penguins, "Body Mass (g)")
  ```

  It is a common use case to compare the density of several groups in a dataset. Several
  options exist to do so. You can plot all items on the same chart, using transparency and
  annotation to make the comparison possible.

  ```tucan
  Tucan.density(:penguins, "Body Mass (g)", color_by: "Species")
  ```

  You can also combine it with `facet_by/4` in order to draw a different plot for each value
  of the grouping variable. Notice that we need to set the `:groupby` variable in order
  to correctly calculate the density plot per field's value.

  ```tucan
  Tucan.density(:penguins, "Body Mass (g)", groupby: ["Species"])
  |> Tucan.color_by("Species")
  |> Tucan.facet_by(:column, "Species")
  ```

  You can control the smoothing by setting a specific `bandwidth` value (if not set it is
  automatically calculated by vega lite):

  ```tucan
  Tucan.density(:penguins, "Body Mass (g)", color_by: "Species", bandwidth: 20.0)
  ```

  You can plot a cumulative density distribution by setting the `:cumulative` option to `true`:

  ```tucan
  Tucan.density(:penguins, "Body Mass (g)", cumulative: true)
  ```

  or calculate a separate cumulative distribution for each group: 

  ```tucan
  Tucan.density(:penguins, "Body Mass (g)", cumulative: true, color_by: "Species")
  |> Tucan.facet_by(:column, "Species")
  ```
  """
  @doc section: :plots
  @spec density(plotdata :: plotdata(), field :: binary(), opts :: keyword()) :: VegaLite.t()
  def density(plotdata, field, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @density_schema)

    spec_opts = take_options(opts, @histogram_opts, :spec)
    mark_opts = take_options(opts, @histogram_opts, :mark)

    transform_opts =
      take_options(opts, @density_opts, :density_transform)
      |> Keyword.merge(density: field)
      |> Tucan.Keyword.put_new_conditionally(:groupby, [opts[:color_by]], fn ->
        opts[:color_by] != nil
      end)

    plotdata
    |> new(spec_opts)
    |> Vl.transform(transform_opts)
    |> Vl.mark(:area, mark_opts)
    |> encode_field(:x, "value", opts, type: :quantitative, scale: [zero: false])
    |> encode_field(:y, "density", opts, type: :quantitative)
    |> maybe_encode_field(:color, fn -> opts[:color_by] != nil end, opts[:color_by], opts, [])
  end

  stripplot_opts = [
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

  @stripplot_opts Tucan.Options.take!(
                    [@global_opts, @global_mark_opts, :orient, :x, :y, :y_offset],
                    stripplot_opts
                  )
  @stripplot_schema Tucan.Options.to_nimble_schema!(@stripplot_opts)

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

  #{Tucan.Options.docs(@stripplot_schema)}

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

  ## Examples

  Assigning a single numeric variable shows the univariate distribution. The default
  style is the `:tick`:

  ```tucan
  Tucan.stripplot(:tips, "total_bill")
  ```

  For very dense distribution it makes more sense to use the `:jitter` style in order
  to reduce overlapping points:

  ```tucan
  Tucan.stripplot(:tips, "total_bill", style: :jitter, height: 30, width: 300)
  ```

  You can set the `:group` option in order to add a second dimension. Notice that
  the field must be categorical.


  ```tucan
  Tucan.stripplot(:tips, "total_bill", group: "day", style: :jitter)
  ```

  The plot would be more clear if you also colored the points with the same field:

  ```tucan
  Tucan.stripplot(:tips, "total_bill", group: "day", style: :jitter)
  |> Tucan.color_by("day")
  ```

  Or you can color by a distinct variable to show a multi-dimensional relationship:

  ```tucan
  Tucan.stripplot(:tips, "total_bill", group: "day", style: :jitter)
  |> Tucan.color_by("sex")
  ```

  or you can color by a numerical variable:

  ```tucan
  Tucan.stripplot(:tips, "total_bill", group: "day", style: :jitter)
  |> Tucan.color_by("size", type: :ordinal)
  ```

  You could draw the same with points but without jittering:

  ```tucan
  Tucan.stripplot(:tips, "total_bill", group: "day", style: :point)
  |> Tucan.color_by("sex")
  ```

  or with ticks which is the default one:

  ```tucan
  Tucan.stripplot(:tips, "total_bill", group: "day", style: :tick)
  |> Tucan.color_by("sex")
  ```

  You can set the `:orient` flag to `:vertical` to change the orientation:

  ```tucan
  Tucan.stripplot(:tips, "total_bill", group: "day", style: :jitter, orient: :vertical)
  |> Tucan.color_by("sex")
  ```
  """
  @doc section: :plots
  @spec stripplot(plotdata :: plotdata(), field :: binary(), opts :: keyword()) :: VegaLite.t()
  def stripplot(plotdata, field, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @stripplot_schema)

    spec_opts = take_options(opts, @stripplot_opts, :spec)

    plotdata
    |> new(spec_opts)
    |> stripplot_mark(opts[:style], Keyword.take(opts, [:tooltip]))
    |> encode_field(:x, field, opts, type: :quantitative)
    |> maybe_encode_field(:y, fn -> opts[:group] != nil end, opts[:group], opts, type: :nominal)
    |> maybe_add_jitter(opts)
    |> maybe_flip_axes(opts[:orient] == :vertical)
  end

  defp stripplot_mark(vl, :tick, opts), do: Vl.mark(vl, :tick, opts)
  defp stripplot_mark(vl, _other, opts), do: Vl.mark(vl, :point, [size: 16] ++ opts)

  defp maybe_encode_field(vl, channel, condition_fn, field, opts, extra_opts) do
    case condition_fn.() do
      false ->
        vl

      true ->
        encode_field(vl, channel, field, opts, extra_opts)
    end
  end

  defp maybe_add_jitter(vl, opts) do
    case opts[:style] do
      :jitter ->
        vl
        |> Vl.transform(calculate: "sqrt(-2*log(random()))*cos(2*PI*random())", as: "jitter")
        |> encode_field(:y_offset, "jitter", opts, type: :quantitative, axis: nil)

      _other ->
        vl
    end
  end

  density_heatmap_opts = [
    z: [
      type: :string,
      doc: """
      If set corresponds to the field that will be used for calculating the color fo the
      bin using the provided aggregate. If not set (the default behaviour) the count of
      observations are used for coloring the bin.
      """
    ],
    aggregate: [
      type: :atom,
      doc: """
      The statistic that will be used for aggregating the observations within a bin. The
      `z` field must be set if `aggregate` is set.
      """
    ]
  ]

  @density_heatmap_opts Tucan.Options.take!(
                          [@global_opts, @global_mark_opts, :x, :y, :color],
                          density_heatmap_opts
                        )
  @density_heatmap_schema Tucan.Options.to_nimble_schema!(@density_heatmap_opts)

  @doc """
  Draws a density heatmap.

  A density heatmap is a bivariate histogram, e.g. the `x`, `y` data are binned
  within rectangles that tile the plot and then the count of observations within
  each rectangle is shown with the fill color.

  By default the `count` of observations within each rectangle is encoded, but you
  can calculate the statistic of any field and use it instead. 

  Density heatmaps are a powerful visualization tool that find their best use cases
  in situations where you need to explore and understand the distribution and
  concentration of data points in a two-dimensional space. They are particularly
  effective when dealing with large datasets, allowing you to uncover patterns,
  clusters, and trends that might be difficult to discern in raw data.

  ## Options

  #{Tucan.Options.docs(@density_heatmap_schema)}

  ## Examples

  Let's start with a default denisty heatmap on the penguins dataset:

  ```tucan
  Tucan.density_heatmap(:penguins, "Beak Length (mm)", "Beak Depth (mm)")
  ```

  You can summarize over another field:

  ```tucan
  Tucan.density_heatmap(:penguins, "Beak Length (mm)", "Beak Depth (mm)", z: "Body Mass (g)", aggregate: :mean)
  ```
  """
  @doc section: :plots
  @spec density_heatmap(plotdata :: plotdata(), x :: binary(), y :: binary(), opts :: keyword()) ::
          VegaLite.t()
  def density_heatmap(plotdata, x, y, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @density_heatmap_schema)

    spec_opts = take_options(opts, @density_heatmap_opts, :spec)
    mark_opts = take_options(opts, @density_heatmap_opts, :mark)

    color_fn = fn vl ->
      case opts[:z] do
        nil ->
          encode(vl, :color, opts, type: :quantitative, aggregate: opts[:aggregate] || :count)

        field ->
          encode_field(vl, :color, field, opts,
            aggregate: opts[:aggregate] || :count,
            type: :quantitative
          )
      end
    end

    plotdata
    |> new(spec_opts)
    |> Vl.mark(:rect, mark_opts)
    |> encode_field(:x, x, opts, type: :quantitative, bin: true)
    |> encode_field(:y, y, opts, type: :quantitative, bin: true)
    |> color_fn.()
  end

  @countplot_opts Tucan.Options.take!([
                    @global_opts,
                    @global_mark_opts,
                    :stacked,
                    :color_by,
                    :orient,
                    :x,
                    :y,
                    :color,
                    :x_offset
                  ])
  @countplot_schema Tucan.Options.to_nimble_schema!(@countplot_opts)

  @doc """
  Plot the counts of observations for a categorical variable.

  Takes a categorical `field` as input and generates a count plot
  visualization. By default the counts are plotted on the *y-axis*
  and the categorical `field` across the *x-axis*.

  This is similar to `histogram/3` but specifically for a categorical
  variable.

  > #### What is a countplot? {: .tip}
  > 
  > A countplot is a type of bar chart used in data visualization to
  > display the **frequency of occurrences of categorical data**. It is
  > particularly useful for visualizing the *distribution* and *frequency*
  > of different categories within a dataset.
  >
  > In a countplot, each unique category is represented by a bar, and the
  > height of the bar corresponds to the number of occurrences of that
  > category in the data.

  ## Options

  #{Tucan.Options.docs(@countplot_schema)}

  ## Examples

  We will use the `:titanic` dataset on the following examples. We can
  plot the number of passengers by ticket class:

  ```tucan
  Tucan.countplot(:titanic, "Pclass")
  ```

  You can make the bars horizontal by setting the `:orient` option:

  ```tucan
  Tucan.countplot(:titanic, "Pclass", orient: :vertical)
  ```

  You can set `:color_by` to group it by a second variable:

  ```tucan
  Tucan.countplot(:titanic, "Pclass", color_by: "Survived")
  ```

  By default the bars are stacked. You can unstack them by setting the
  `:stacked` option:

  ```tucan
  Tucan.countplot(:titanic, "Pclass", color_by: "Survived", stacked: false)
  ```
  """
  @doc section: :plots
  @spec countplot(plotdata :: plotdata(), field :: binary(), opts :: keyword()) :: VegaLite.t()
  def countplot(plotdata, field, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @countplot_schema)

    spec_opts = take_options(opts, @countplot_opts, :spec)
    mark_opts = take_options(opts, @countplot_opts, :mark)

    plotdata
    |> new(spec_opts)
    |> Vl.mark(:bar, mark_opts)
    |> encode_field(:x, field, opts, type: :nominal)
    |> encode_field(:y, field, opts, aggregate: "count")
    |> maybe_encode_field(:color, fn -> opts[:color_by] != nil end, opts[:color_by], opts, [])
    |> maybe_x_offset(opts[:color_by], opts[:stacked], opts)
    |> maybe_flip_axes(opts[:orient] == :vertical)
  end

  defp maybe_x_offset(vl, nil, _stacked, _opts), do: vl
  defp maybe_x_offset(vl, _field, true, _opts), do: vl
  defp maybe_x_offset(vl, field, false, opts), do: encode_field(vl, :x_offset, field, opts)

  @scatter_opts Tucan.Options.take!([
                  @global_opts,
                  @global_mark_opts,
                  :color_by,
                  :shape_by,
                  :size_by,
                  :x,
                  :y,
                  :color,
                  :shape,
                  :size
                ])
  @scatter_schema Tucan.Options.to_nimble_schema!(@scatter_opts)

  @doc """
  Returns the specification of a scatter plot with possibility of several semantic
  groupings.

  Both `x` and `y` must be `:quantitative`.

  > #### Semantic groupings {: .tip}
  >   
  > The relationship between `x` and `y` can be shown for different subsets of the
  > data using the `color_by`, `size_by` and `shape_by` parameters. This is equivalent
  > to calling the corresponding functions after a `scatter/4` call.
  > 
  > These parameters control what visual semantics are used to identify the different
  > subsets. It is possible to show up to three dimensions independently by using all
  > three semantic types, but this style of plot can be hard to interpret and is often
  > ineffective.
  >
  > ```tucan
  > Tucan.scatter(:tips, "total_bill", "tip",
  >   color_by: "day",
  >   shape_by: "sex",
  >   size_by: "size"
  > )
  > ```
  > 
  > The above is equivalent to calling:
  >
  > ```elixir
  > Tucan.scatter(:tips, "total_bill", "tip")
  > |> Tucan.color_by("day", type: :nominal)
  > |> Tucan.shape_by("sex", type: :nominal)
  > |> Tucan.size_by("size", type: :quantitative)
  > ```
  > 
  > Using redundant semantics (i.e. both color and shape for the same variable) can be
  > helpful for making graphics more accessible.
  >
  > ```tucan
  > Tucan.scatter(:tips, "total_bill", "tip",
  >   color_by: "day",
  >   shape_by: "day"
  > )
  > ```

  ## Options

  #{Tucan.Options.docs(@scatter_schema)}

  ## Examples

  > We will use the `:tips` dataset thoughout the following examples.

  Drawing a scatter plot betwen two variables:

  ```tucan
  Tucan.scatter(:tips, "total_bill", "tip")
  ```

  You can combine it with `color_by/3` to color code the points:

  ```tucan
  Tucan.scatter(:tips, "total_bill", "tip")
  |> Tucan.color_by("time")
  ```

  Assigning the same variable to `shape_by/3` will also vary the markers and create a
  more accessible plot:

  ```tucan
  Tucan.scatter(:tips, "total_bill", "tip", width: 400)
  |> Tucan.color_by("time")
  |> Tucan.shape_by("time")
  ```

  Assigning `color_by/3` and `shape_by/3` to different variables will vary colors and
  markers independently:

  ```tucan
  Tucan.scatter(:tips, "total_bill", "tip", width: 400)
  |> Tucan.color_by("day")
  |> Tucan.shape_by("time")
  ```

  You can also color the points by a numeric variable, the semantic mapping will be
  quantitative and will use a different default palette:

  ```tucan
  Tucan.scatter(:tips, "total_bill", "tip", width: 400)
  |> Tucan.color_by("size", type: :quantitative)
  ```

  A numeric variable can also be assigned to size to apply a semantic mapping to the
  areas of the points:

  ```tucan
  Tucan.scatter(:tips, "total_bill", "tip", width: 400, tooltip: :data)
  |> Tucan.color_by("size", type: :quantitative)
  |> Tucan.size_by("size", type: :quantitative)
  ```

  You can also combine it with `facet_by/3` in order to group within additional
  categorical variables, and plot them across multiple subplots.

  ```tucan
  Tucan.scatter(:tips, "total_bill", "tip", width: 300)
  |> Tucan.color_by("day")
  |> Tucan.shape_by("day")
  |> Tucan.facet_by(:column, "time")
  ```

  You can also apply faceting on more than one variables, both horizontally and
  vertically:

  ```tucan
  Tucan.scatter(:tips, "total_bill", "tip", width: 300)
  |> Tucan.color_by("day")
  |> Tucan.shape_by("day")
  |> Tucan.size_by("size")
  |> Tucan.facet_by(:column, "time")
  |> Tucan.facet_by(:row, "sex")
  ```
  """
  @doc section: :plots
  @spec scatter(plotdata :: plotdata(), x :: binary(), y :: binary(), opts :: keyword()) ::
          VegaLite.t()
  def scatter(plotdata, x, y, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @scatter_schema)

    spec_opts = take_options(opts, @scatter_opts, :spec)
    mark_opts = take_options(opts, @scatter_opts, :mark)

    plotdata
    |> new(spec_opts)
    |> Vl.mark(:point, mark_opts)
    |> encode_field(:x, x, opts, type: :quantitative, scale: [zero: false])
    |> encode_field(:y, y, opts, type: :quantitative, scale: [zero: false])
    |> maybe_encode_field(:color, fn -> opts[:color_by] != nil end, opts[:color_by], opts,
      type: :nominal
    )
    |> maybe_encode_field(:shape, fn -> opts[:shape_by] != nil end, opts[:shape_by], opts,
      type: :nominal
    )
    |> maybe_encode_field(:size, fn -> opts[:size_by] != nil end, opts[:size_by], opts,
      type: :quantitative
    )
  end

  @bubble_opts Tucan.Options.take!([
                 @global_opts,
                 @global_mark_opts,
                 :color_by,
                 :x,
                 :y,
                 :size,
                 :color
               ])
  @bubble_schema Tucan.Options.to_nimble_schema!(@bubble_opts)

  @doc """
  Returns the specification of a bubble plot.

  A bubble plot is a scatter plot with a third parameter defining the size of the dots.

  All `x`, `y` and `size` must be numerical data fields.

  See also `scatter/4`.

  ## Options

  #{Tucan.Options.docs(@bubble_schema)}

  ## Examples

  ```tucan
  Tucan.bubble(:gapminder, "income", "health", "population", width: 400)
  |> Tucan.Axes.set_x_title("Gdp per Capita")
  |> Tucan.Axes.set_y_title("Life expectancy")
  ```

  You could use a fourth variable to color the graph. As always you can set the `tooltip` in
  order to make the plot interactive:

  ```tucan
  Tucan.bubble(:gapminder, "income", "health", "population", color_by: "region", width: 400, tooltip: :data)
  |> Tucan.Axes.set_x_title("Gdp per Capita")
  |> Tucan.Axes.set_y_title("Life expectancy")
  ```

  It makes more sense to use a log scale for the _x axis_:

  ```tucan
  Tucan.bubble(:gapminder, "income", "health", "population", color_by: "region", width: 400, tooltip: :data)
  |> Tucan.Axes.set_x_title("Gdp per Capita")
  |> Tucan.Axes.set_y_title("Life expectancy")
  |> Tucan.Axes.set_x_scale(:log)
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
    opts = NimbleOptions.validate!(opts, @bubble_schema)

    spec_opts = take_options(opts, @bubble_opts, :spec)

    plotdata
    |> new(spec_opts)
    |> Vl.mark(:circle, Keyword.take(opts, [:tooltip]))
    |> encode_field(:x, x, opts, type: :quantitative, scale: [zero: false])
    |> encode_field(:y, y, opts, type: :quantitative, scale: [zero: false])
    |> encode_field(:size, size, opts, type: :quantitative)
    |> maybe_encode_field(:color, fn -> opts[:color_by] != nil end, opts[:color_by], opts,
      type: :nominal
    )
  end

  @lineplot_opts Tucan.Options.take!([@global_opts, @global_mark_opts, :x, :y])
  @lineplot_schema Tucan.Options.to_nimble_schema!(@lineplot_opts)
  Module.put_attribute(__MODULE__, :schemas, {:lineplot, @lineplot_opts})

  @doc """
  Draw a line plot between `x` and `y`

  ## Options

  #{Tucan.Options.docs(@lineplot_schema)}

  ## Examples

  ```tucan
  Tucan.lineplot(:flights, "year", "passengers")
  ```

  ```tucan
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
    opts = NimbleOptions.validate!(opts, @lineplot_schema)

    spec_opts = take_options(opts, @lineplot_opts, :spec)
    mark_opts = take_options(opts, @lineplot_opts, :mark)

    plotdata
    |> new(spec_opts)
    |> Vl.mark(:line, mark_opts)
    |> encode_field(:x, x, opts, type: :quantitative)
    |> encode_field(:y, y, opts, type: :quantitative)
  end

  pie_opts = [
    inner_radius: [
      type: :integer,
      doc: """
      The inner radius in pixels. `0` for a pie chart, `> 0` for a donut chart. If not
      set it defaults to 0
      """,
      dest: :mark
    ],
    # TODO: custom validation with supported types
    aggregate: [
      type: :atom,
      doc: "The statistic to use (if any) for aggregating values per pie slice (e.g. `:mean`).",
      dest: :theta
    ]
  ]

  @pie_opts Tucan.Options.take!([@global_opts, @global_mark_opts, :theta, :color], pie_opts)
  @pie_schema Tucan.Options.to_nimble_schema!(@pie_opts)

  @doc """
  Draws a pie chart.

  A pie chart is a circle divided into sectors that each represents a proportion
  of the whole. The `field` specifies the data column that contains the proportions
  of each category. The chart will be colored by the `caregory` field.

  > #### Avoid using pie charts {: .warning}
  >
  > Despite it's popularity pie charts should rarely be used. Pie charts are best
  > suited for displaying a small number of categories and can make it challenging
  > to accurately compare data. They rely on angle perception, which can lead to
  > misinterpretation, and lack the precision offered by other charts like bar
  > charts or line charts.
  >
  > Instead, opt for alternatives such as bar charts for straightforward comparisons,
  > stacked area charts for cumulative effects.
  > 
  > The following example showcases the limitations of a pie chart, compared to a
  > bar chart:
  >
  > ```tucan
  > alias VegaLite, as: Vl
  >
  > data = [
  >   %{value: 30, category: "A"},
  >   %{value: 33, category: "B"},
  >   %{value: 38, category: "C"}
  > ]
  > 
  > pie = Tucan.pie(Vl.new(), "value", "category")
  > 
  > # TODO: replace with the bar call once implemented
  > bar =
  >   Vl.new()
  >   |> Tucan.new()
  >   |> Vl.mark(:bar)
  >   |> Vl.encode_field(:y, "category")
  >   |> Vl.encode_field(:x, "value", type: :quantitative)
  >
  > Vl.new()
  > |> Vl.data_from_values(data)
  > |> Vl.concat([pie, bar], :horizontal)
  > |> Tucan.set_title("Pie vs Bar chart", anchor: :middle, offset: 15)
  > ```

  ## Options

  #{Tucan.Options.docs(@pie_schema)}

  ## Examples

  ```tucan
  Tucan.pie(:barley, "yield", "site", aggregate: :sum, tooltip: true)
  |> Tucan.facet_by(:column, "year", type: :nominal)
  ```
  """
  @doc section: :plots
  @spec pie(plotdata :: plotdata(), field :: binary(), category :: binary(), opts :: keyword()) ::
          VegaLite.t()
  def pie(plotdata, field, category, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @pie_schema)

    spec_opts = take_options(opts, @pie_opts, :spec)
    mark_opts = take_options(opts, @pie_opts, :mark)

    theta_opts =
      opts
      |> take_options(@pie_opts, :theta)
      |> Keyword.merge(type: :quantitative)

    plotdata
    |> new(spec_opts)
    |> Vl.mark(:arc, mark_opts)
    |> encode_field(:theta, field, opts, theta_opts)
    |> encode_field(:color, category, opts)
  end

  @doc """
  Draw a donut chart.

  A donut chart is a circular visualization that resembles a pie chart but
  features a hole at its center. This central hole creates a _donut_ shape,
  distinguishing it from traditional pie charts. 

  This is a wrapper around `pie/4` that sets by default the `:inner_radius`.

  ## Options

  See `pie/4`

  ## Examples

  ```tucan
  Tucan.donut(:barley, "yield", "site", aggregate: :sum, tooltip: true)
  |> Tucan.facet_by(:column, "year", type: :nominal)
  ```
  """
  @doc section: :plots
  @spec donut(plotdata :: plotdata(), field :: binary(), category :: binary(), opts :: keyword()) ::
          VegaLite.t()
  def donut(plotdata, field, category, opts \\ []) do
    opts = Keyword.put_new(opts, :inner_radius, 50)

    pie(plotdata, field, category, opts)
  end

  ## Composite plots

  pairplot_opts = [
    diagonal: [
      type: {:in, [:scatter, :density, :histogram]},
      default: :scatter,
      doc: """
      The plot type to be used for the diagonal subplots. Can be one on
      `:scatter`, `:density` and `:histogram`.
      """
    ],
    plot_fn: [
      type: {:fun, 3},
      doc: """
      An optional function for customizing the look any subplot. It expects a
      function with the following signature:

      ```elixir
      (vl :: VegaLite.t(), row :: {binary(), integer()}, column :: {binary(), integer()})
        :: VegaLite.t() 
      ```

      where both `row` and `column` are tuples containing the index and field of
      the current and row and column respectively.

      You are free to specify any function for every cell of the grid.
      """
    ]
  ]

  @pairplot_opts Tucan.Options.take!([@global_opts], pairplot_opts)
  @pairplot_schema Tucan.Options.to_nimble_schema!(@pairplot_opts)

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

  ## Options

  #{Tucan.Options.docs(@pairplot_schema)}

  Notice that if set `width` and `height` will be applied to individual sub plots. On
  the other hand `title` is applied to the composite plot.

  ## Examples

  By default a scatter plot will be drawn for all pairwise plots:

  ```tucan
  fields = ["petal_width", "petal_length", "sepal_width", "sepal_length"]

  Tucan.pairplot(:iris, fields, width: 130, height: 130)
  ```

  You can color the points by another field in to add some semantic mapping. Notice
  that you need the `recursive` option to `true` for the grouping to be applied on all
  internal subplots.

  ```tucan
  fields = ["petal_width", "petal_length", "sepal_width", "sepal_length"]

  Tucan.pairplot(:iris, fields, width: 130, height: 130)
  |> Tucan.color_by("species", recursive: true)
  ```

  By specifying the `:diagonal` option you can change the default plot for the diagonal
  elements to a histogram:

  ```tucan
  fields = ["petal_width", "petal_length", "sepal_width", "sepal_length"]

  Tucan.pairplot(:iris, fields, width: 130, height: 130, diagonal: :histogram)
  |> Tucan.color_by("species", recursive: true)
  ```

  Additionally you have the option to configure a `plot_fn` with which we can go crazy and
  modify any part of the grid based on our needs. `plot_fn` should accept as input a `VegaLite`
  struct and two tuples containing the row and column fields and indexes. In the following
  example we draw differently the diagonal, the lower and the upper grid. Notice that we don't
  call `color_by/3` since we color differently the plots based on their index positions.

  ```tucan
  Tucan.pairplot(:iris, ["petal_width", "petal_length", "sepal_width", "sepal_length"],
    width: 150,
    height: 150,
    plot_fn: fn vl, {row_field, row_index}, {col_field, col_index} ->
      cond do
        # For the first two diagonal elements we plot a histogram, no 
        row_index == col_index and row_index < 2 ->
          Tucan.histogram(vl, row_field)

        row_index == 2 and col_index == 2 ->
          Tucan.stripplot(vl, row_field, group: "species", style: :tick)
          |> Tucan.color_by("species") 
          |> Tucan.Axes.put_axis_options(:y, labels: false)  

        # For the other diagonal plots we plot a histogram colored_by the species
        row_index == col_index ->
          Tucan.histogram(vl, row_field, color_by: "species")

        # For the upper part of the diagram we apply a scatter plot
        row_index < col_index ->
          Tucan.scatter(vl, col_field, row_field)
          |> Tucan.color_by("species")

        # for anything else scatter plot with a quantitative color scale
        # and size
        true ->
          Tucan.scatter(vl, col_field, row_field)
          |> Tucan.size_by("petal_width", type: :quantitative)
          
      end
    end
  )
  ```
  """
  @doc section: :composite
  @spec pairplot(plotdata :: plotdata(), fields :: [binary()], opts :: keyword()) :: VegaLite.t()
  def pairplot(plotdata, fields, opts \\ []) when is_list(fields) do
    opts = NimbleOptions.validate!(opts, @pairplot_schema)

    children =
      for {row_field, row_index} <- Enum.with_index(fields),
          {col_field, col_index} <- Enum.with_index(fields) do
        pairplot_child_spec({row_field, row_index}, {col_field, col_index}, length(fields), opts)
      end

    spec_opts = Keyword.take(opts, [:title]) ++ [columns: length(fields)]

    plotdata
    |> new(spec_opts)
    |> Vl.concat(children, :wrappable)
  end

  defp pairplot_child_spec({row_field, row_index}, {col_field, col_index}, fields_count, opts) do
    x_axis_title = fn vl, row_index ->
      if row_index == fields_count - 1 do
        Tucan.Axes.put_axis_options(vl, :x, title: col_field)
      else
        Tucan.Axes.put_axis_options(vl, :x, title: nil)
      end
    end

    y_axis_title = fn vl, col_index ->
      if col_index == 0 do
        Tucan.Axes.put_axis_options(vl, :y, title: row_field)
      else
        Tucan.Axes.put_axis_options(vl, :y, title: nil)
      end
    end

    spec_opts = Keyword.take(opts, [:width, :height])

    Vl.new(spec_opts)
    |> pairplot_child_plot(row_field, row_index, col_field, col_index, opts)
    |> x_axis_title.(row_index)
    |> y_axis_title.(col_index)
  end

  defp pairplot_child_plot(vl, row_field, row_index, col_field, col_index, opts) do
    diagonal = opts[:diagonal] || :scatter
    plot_fn = opts[:plot_fn]

    cond do
      plot_fn != nil ->
        plot_fn.(vl, {row_field, row_index}, {col_field, col_index})

      row_index == col_index and diagonal == :histogram ->
        Tucan.histogram(vl, row_field)

      row_index == col_index and diagonal == :density ->
        Tucan.density(vl, row_field)

      true ->
        Tucan.scatter(vl, col_field, row_field)
    end
  end

  ## Grouping functions

  @doc """
  Adds a `color` encoding for the given field.

  `opts` can be an arbitrary keyword list with vega-lite supported options.

  If `:recursive` is set the encoding is applied in all subplots of the given plot.
  """
  @doc section: :grouping
  @spec color_by(vl :: VegaLite.t(), field :: binary(), opts :: keyword()) :: VegaLite.t()
  def color_by(vl, field, opts \\ []), do: group_by(vl, :color, field, opts)

  @doc """
  Adds a `shape` encoding for the given field.

  `opts` can be an arbitrary keyword list with vega-lite supported options.

  If `:recursive` is set the encoding is applied in all subplots of the given plot.
  """
  @doc section: :grouping
  @spec shape_by(vl :: VegaLite.t(), field :: binary(), opts :: keyword()) :: VegaLite.t()
  def shape_by(vl, field, opts \\ []), do: group_by(vl, :shape, field, opts)

  @doc """
  Adds a `stroke_dash` encoding for the given field.

  `opts` can be an arbitrary keyword list with vega-lite supported options.

  If `:recursive` is set the encoding is applied in all subplots of the given plot.
  """
  @doc section: :grouping
  @spec stroke_dash_by(vl :: VegaLite.t(), field :: binary(), opts :: keyword()) :: VegaLite.t()
  def stroke_dash_by(vl, field, opts \\ []), do: group_by(vl, :stroke_dash, field, opts)

  @doc """
  Adds a `fill` encoding for the given field.

  `opts` can be an arbitrary keyword list with vega-lite supported options.

  If `:recursive` is set the encoding is applied in all subplots of the given plot.
  """
  @doc section: :grouping
  @spec fill_by(vl :: VegaLite.t(), field :: binary(), opts :: keyword()) :: VegaLite.t()
  def fill_by(vl, field, opts \\ []), do: group_by(vl, :fill, field, opts)

  @doc """
  Adds a `size` encoding for the given field.

  `opts` can be an arbitrary keyword list with vega-lite supported options.

  If `:recursive` is set the encoding is applied in all subplots of the given plot.
  """
  @doc section: :grouping
  @spec size_by(vl :: VegaLite.t(), field :: binary(), opts :: keyword()) :: VegaLite.t()
  def size_by(vl, field, opts \\ []), do: group_by(vl, :size, field, opts)

  defp group_by(vl, encoding, field, opts) do
    {recursive, opts} = Keyword.pop(opts, :recursive)

    case recursive do
      true ->
        apply_recursively(vl, fn spec ->
          VegaLiteUtils.encode_field_raw(spec, encoding, field, opts)
        end)

      _ ->
        Vl.encode_field(vl, encoding, field, opts)
    end
  end

  @doc """
  Apply facetting on the input plot `vl` by the given `field`.

  This will create multiple plots either horizontally (`:column` faceting mode) or
  vertically (`:row` faceting mode), one for each distinct value of the given
  `field`, which must be a categorical variable.

  `opts` is an arbitraty keyword list that will be passed to the `:row` or `:column`
  encoding.

  > #### Facet plots {: .info}
  >
  > Facet plots, also known as trellis plots or small multiples, are figures made up
  > of multiple subplots which have the same set of axes, where each subplot shows
  > a subset of the data.

  ## Examples

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.facet_by(:column, "species")
  |> Tucan.color_by("species")
  ```
  """
  @doc section: :grouping
  @spec facet_by(
          vl :: VegaLite.t(),
          faceting_mode :: :row | :column,
          field :: binary(),
          opts :: keyword()
        ) :: VegaLite.t()
  def facet_by(vl, faceting_mode, field, opts \\ [])

  def facet_by(vl, :row, field, opts) do
    Vl.encode_field(vl, :row, field, opts)
  end

  def facet_by(vl, :column, field, opts) do
    Vl.encode_field(vl, :column, field, opts)
  end

  defp apply_recursively(%VegaLite{} = vl, fun) do
    put_in(vl.spec, apply_recursively(vl.spec, fun))
  end

  defp apply_recursively(%{"vconcat" => vconcat} = spec, fun) do
    vconcat = apply_recursively(vconcat, fun)
    Map.put(spec, "vconcat", vconcat)
  end

  defp apply_recursively(%{"hconcat" => hconcat} = spec, fun) do
    hconcat = apply_recursively(hconcat, fun)
    Map.put(spec, "hconcat", hconcat)
  end

  defp apply_recursively(%{"concat" => concat} = spec, fun) do
    concat = apply_recursively(concat, fun)
    Map.put(spec, "concat", concat)
  end

  defp apply_recursively(spec, fun) when is_map(spec) do
    fun.(spec)
  end

  defp apply_recursively(spec, fun) when is_list(spec) do
    Enum.map(spec, fn item -> apply_recursively(item, fun) end)
  end

  ## Utility functions

  @doc """
  Sets the width of the plot (in pixels).
  """
  @doc section: :utilities
  @spec set_width(vl :: VegaLite.t(), width :: pos_integer()) :: VegaLite.t()
  def set_width(vl, width) when is_struct(vl, VegaLite) and is_integer(width) and width > 0 do
    update_in(vl.spec, fn spec -> Map.merge(spec, %{"width" => width}) end)
  end

  @doc """
  Sets the width of the plot (in pixels).
  """
  @doc section: :utilities
  @spec set_height(vl :: VegaLite.t(), height :: pos_integer()) :: VegaLite.t()
  def set_height(vl, height) when is_struct(vl, VegaLite) and is_integer(height) and height > 0 do
    update_in(vl.spec, fn spec -> Map.merge(spec, %{"height" => height}) end)
  end

  @doc """
  Sets the title of the plot.

  You can optionally pass any title option supported by vega-lite to customize the
  style of it.

  ## Examples

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.set_title("My awesome plot",
      color: "red",
      subtitle: "with a subtitle",
      subtitle_color: "green",
      anchor: "start"
    )
  ```
  """
  @doc section: :utilities
  @spec set_title(vl :: VegaLite.t(), title :: binary(), opts :: keyword()) :: VegaLite.t()
  def set_title(vl, title, opts \\ [])
      when is_struct(vl, VegaLite) and is_binary(title) and is_list(opts) do
    title_opts = Keyword.merge(opts, text: title)

    VegaLiteUtils.put_in_spec(vl, :title, title_opts)
  end

  @doc """
  Sets the plot's theme.

  Check `Tucan.Themes` for more details on theming.
  """
  @spec set_theme(vl :: VegaLite.t(), theme :: atom()) :: VegaLite.t()
  def set_theme(vl, theme) do
    theme = Tucan.Themes.theme(theme)

    Vl.config(vl, theme)
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
    axis_pairs = [{:x, :y}, {:x2, :y2}, {:x_offset, :y_offset}]

    new_vl = VegaLiteUtils.drop_encoding_channels(vl, [:x, :y, :x2, :y2, :x_offset, :y_offset])

    Enum.reduce(axis_pairs, new_vl, fn {left, right}, new_vl ->
      new_vl
      |> copy_encoding(left, right, vl)
      |> copy_encoding(right, left, vl)
    end)
  end

  # copies to left channel, the right channel options from the vl_origing specification
  defp copy_encoding(vl, left, right, vl_origin) do
    case VegaLiteUtils.has_encoding?(vl_origin, left) do
      false ->
        vl

      true ->
        opts = VegaLiteUtils.encoding_options(vl_origin, left) || []
        VegaLiteUtils.encode_raw(vl, right, opts)
    end
  end

  defp maybe_flip_axes(vl, false), do: vl
  defp maybe_flip_axes(vl, true), do: flip_axes(vl)

  defp take_options(opts, schema, dest) do
    dest_opts =
      schema
      |> Enum.filter(fn {_key, opts} ->
        opts[:dest] == dest
      end)
      |> Keyword.keys()

    Keyword.take(opts, dest_opts)
  end

  # we use encode_field and encode instead of Vl.encode_field and Vl.encode in all
  # tucan plots for the following reason:
  #
  # - we want to support setting custom vega-lite options on each encoding
  # that may be included in the specification.
  # - these options are passed in the options of the plots as encoding: [options]
  # e.g. x: [...], y: []
  # - by having this custom function we can ensure that:
  #   - the encoding options are extracted by the opts on each call and merged
  #   with the extra_opts the function call may set
  #   - if they are missing the tests will raise ensuring that we have properly
  #   set all possible options for each plot type
  #   - they are set with the proper precedence and deep merged with the extra
  defp encode_field(vl, encoding, field, opts, extra_opts \\ []) do
    encoding_opts = Tucan.Keyword.deep_merge(extra_opts, Keyword.fetch!(opts, encoding))

    Vl.encode_field(vl, encoding, field, encoding_opts)
  end

  defp encode(vl, encoding, opts, extra_opts) do
    encoding_opts = Tucan.Keyword.deep_merge(extra_opts, Keyword.fetch!(opts, encoding))

    Vl.encode(vl, encoding, encoding_opts)
  end

  @doc false
  @spec __schema__(plot :: atom()) :: keyword()
  def __schema__(plot), do: Keyword.fetch!(@schemas, plot)
end
