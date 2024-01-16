defmodule Tucan do
  @moduledoc """
  A high level API interface for creating plots on top of `VegaLite`.

  Tucan is an Elixir plotting library built on top of `VegaLite`,
  designed to simplify the creation of interactive and visually stunning
  plots. With `Tucan`, you can effortlessly generate a wide range of plots,
  from simple bar charts to complex composite plots, all while enjoying the
  power and flexibility of a clean composable functional API.

  Tucan offers a simple API for creating most common plot types similarly
  to the widely used python packages `matplotlib` and `seaborn` without
  requiring the end user to be familiar with the Vega Lite grammar.

  ## Features

  - **Versatile Plot Types** - Tucan provides an array of plot types, including
  bar charts, line plots, scatter plots, histograms, and more, allowing you to
  effectively represent diverse data sets.
  - **Clean and consistent API** - A clean and consistent plotting API similar
  to `matplotlib` or `seaborn` is provided. You should be able to create most
  common plots with a single function call and minimal configuration.
  - **Grouping and Faceting** - Enhance your visualizations with grouping and
  faceting features, enabling you to examine patterns and trends within subgroups
  of your data.
  - **Customization** - Customize your plots with ease using Tucan's utilities
  for adjusting plot dimensions, titles, and **themes**.
  - **Thin wrapper on top of VegaLite** - All `VegaLite` functions can be used
  seamlessly with `Tucan` for advanced customizations if needed.
  - **Low level API** - A low level API with helper functions allow you to modify
  any part of a `VegaLite` specification.

  ## Basic usage

  All supported plots expect as first argument some data, a `VegaLite` specification
  or a binary which is considered a url to some data. Additionally you can use
  one of the available `Tucan.Datasets`.

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  ```

  > #### `Nx` support {: .neutral}
  >
  > If `:nx` is installed as a dependency you can additionally pass directly the data
  > columns as tensors. For example:
  >
  > ```tucan
  > x = Nx.linspace(-20, 20, n: 200)
  > y = Nx.pow(x, 2)
  >
  > Tucan.lineplot([x: x, y: y], "x", "y", width: 400)
  > ```
  >
  > For more details check `Tucan.new/2`.

  You can apply semantic grouping by a third variable by modifying the color, the
  shape or the size of the points:

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length", color_by: "species", shape_by: "species")
  ```

  Alternatively you could use the helper grouping functions:

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.color_by("species")
  |> Tucan.shape_by("species")
  ```

  > #### Use the functional API carefully {: .warning}
  >
  > For some plot types where transformations are applied on the input data it
  > is recommended to use the options instead of the functional API, since in the
  > first case any required grouping will also be applied to the transformations.

  ## Composite plots

  Tucan also provides some helper functions for generating composite plots.
  `pairplot/3` can be used to plot pairwise relationships across a dataset.

  ```tucan
  fields = ["Beak Length (mm)", "Beak Depth (mm)", "Body Mass (g)"]

  Tucan.pairplot(:penguins, fields, diagonal: :density)
  ```

  ## Customization & Themes

  Various methods and helper modules allow you to easily modify the style of
  a plot.

  ```tucan
  Tucan.bubble(:gapminder, "income", "health", "population",
    color_by: "region",
    width: 400,
    tooltip: :data
  )
  |> Tucan.Axes.set_x_title("Gdp per Capita")
  |> Tucan.Axes.set_y_title("Life expectancy")
  |> Tucan.Scale.set_x_scale(:log)
  |> Tucan.Grid.set_color(:x, "red")
  ```

  Additionally `set_theme/2` allows you to set one of the supported `Tucan.Themes`.

  ```tucan
  Tucan.density_heatmap(:penguins, "Beak Length (mm)", "Beak Depth (mm)")
  |> Tucan.set_theme(:latimes)
  ```

  ## Encoding channels options

  All Tucan plots are building a `VegaLite` specification based on some sane
  default parameters. Notice that only a tiny subset of vega-lite configuration
  options are exported in Tucan's public API. This is more than enough in most
  cases. Additionally, an optional configuration option is added for every
  encoding channel that is used, that allows you to add any vega-lite option
  or change the default options set by Tucan.

  For example:

  ```tucan
  Tucan.bar(:weather, "date", "date",
    color_by: "weather",
    tooltip: true,
    x: [type: :ordinal, time_unit: :month],
    y: [aggregate: :count]
  )
  ```
  """
  alias Tucan.Utils
  alias VegaLite, as: Vl

  @typedoc """
  The plot data.

  This represents the input to all `Tucan` plots. It can be any of the following:

  * an existing `t:VegaLite.t/0` struct
  * a string corresponding to the url of a dataset
  * a dataset implementing the `t:Table.Reader.t/0` protocol
  * an atom corresponding to one of the supported `Tucan.Datasets`
  """
  @type plotdata :: String.t() | Table.Reader.t() | Tucan.Datasets.t() | VegaLite.t()

  @typedoc "A string corresponding to a dataset's field"
  @type field :: String.t()

  ## Custom guards

  defguardp is_pos_integer(term) when is_integer(term) and term > 0

  ## Plots

  @doc """
  Creates an empty `VegaLite` plot.

  This is a simple wrapper around `VegaLite.new/0`.
  """
  @doc section: :construction
  @spec new() :: VegaLite.t()
  def new, do: Vl.new()

  @doc """
  Creates if needed a `VegaLite` plot and adds data to it.

  The behaviour of this function depends on the type of `plotdata`:

  * if a `VegaLite.t()` struct is passed then it is returned unchanged.
  * If it is a binary it is considered a url and the `VegaLite.data_from_url/2` is
    called on a newly created `VegaLite` struct.
  * if it is an atom then it is considered a `Tucan.Dataset` and it is translated to
    the dataset's url. If the dataset name is invalid an exception is raised.
  * in any other case it is considered a set of data values and the values are set
    as data to a newly created `VegaLite` struct. Any tabular data is accepted, as
    long as it adheres to the `Table.Reader` protocol.

  ## Examples

  Passing a URL to some dataset

  ```elixir
  Tucan.new("https://vega.github.io/editor/data/penguins.json")
  |> ...

  Tucan.new("https://vega.github.io/editor/data/stocks.csv", format: :csv)
  |> ...
  ```

  Using a pre-defined `Tucan.Dataset`

  ```elixir
  Tucan.new(:penguins)
  |> ...

  Tucan.new(:iris)
  |> ...
  ```

  Passing directly tabular data

  ```elixir
  data = [
    %{"category" => "A", "score" => 28},
    %{"category" => "B", "score" => 55}
  ]

  Tucan.new(data)
  |> ...
  ```

  You can also pass individual series:

  ```elixir
  xs = 1..100
  ys = 1..100

  Tucan.new(x: xs, y: ys)
  |> ...
  ```

  Any data that adheres to the `Table.Reader` protocol is accepted, for example
  you could pass an [`Explorer.DataFrame`](https://hexdocs.pm/explorer/Explorer.DataFrame.html)

  ```elixir
  mountains = Explorer.DataFrame.new(
    name: ["Everest", "K2", "Aconcagua"],
    elevation: [8848, 8611, 6962]
  )

  Tucan.new(mountains)
  |> ...
  ```

  Additionally you can pass `Nx.Tensor`s as series. These will be implicitly
  transformed to lists.

  ```elixir
  xs = Nx.linspace(0, 10, n: 100)
  ys = Nx.sin(xs)

  Tucan.new([x: xs, y: ys])
  |> ...
  ```

  > #### Valid `Nx.Tensor` shapes {: .info}
  >
  > 1-dimensional tensors are expected when you pass `Nx` tensors as series.
  > Additionally for convenience 2-dimensional tensors where one of the two
  > dimensions is `1` are also supported.
  >
  > For example the following are equivalent
  >
  > ```elixir
  > x = Nx.linspace(0, 10, n: 10)
  > y = Nx.pow(x, 2)
  >
  > plot1 = Tucan.new(x: x, y: y)
  >
  > x = Nx.reshape(x, {10, 1})
  > y = Nx.reshape(y, {1, 10})
  >
  > plot2 = Tucan.new(x: x, y: y)
  >
  > assert plot1 == plot2
  > ```
  >
  > For all other tensor shapes an `ArgumentError` will be raised.

  """
  @doc section: :construction
  @spec new(plotdata :: plotdata(), opts :: keyword()) :: VegaLite.t()
  def new(plotdata, opts \\ []),
    do: to_vega_plot(plotdata, opts)

  defp to_vega_plot(%VegaLite{} = plot, _opts), do: plot

  defp to_vega_plot(dataset, opts) when is_atom(dataset),
    do: to_vega_plot(Tucan.Datasets.dataset(dataset), opts)

  defp to_vega_plot(dataset, opts) when is_binary(dataset) do
    # TODO: maybe raise if set
    opts = Keyword.drop(opts, [:only])

    opts
    |> new_tucan_plot()
    |> Vl.data_from_url(dataset)
  end

  defp to_vega_plot(data, opts) do
    {data_opts, spec_opts} = Keyword.split(opts, [:only])

    data = maybe_transform_data(data)

    spec_opts
    |> new_tucan_plot()
    |> Vl.data_from_values(data, data_opts)
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

  defp new_tucan_plot(opts) do
    {tucan_opts, opts} = Keyword.pop(opts, :tucan)

    case tucan_opts do
      nil -> Vl.new(opts)
      tucan_opts -> Vl.new(opts) |> Utils.put_in_spec("__tucan__", tucan_opts)
    end
  end

  ## Plots

  # global_opts should be applicable in all plot types
  @global_opts [:width, :height, :title, :only]
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
      """,
      section: :grouping
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

  @histogram_opts Tucan.Options.take!(
                    [
                      @global_opts,
                      @global_mark_opts,
                      :x,
                      :x2,
                      :y,
                      :color,
                      :fill_color,
                      :corner_radius
                    ],
                    histogram_opts
                  )
  @histogram_schema Tucan.Options.to_nimble_schema!(@histogram_opts)

  @doc """
  Plots a histogram.

  See also `density/3`

  ## Options

  #{Tucan.Options.docs(@histogram_opts)}

  ## Examples

  Histogram of `Horsepower`

  ```tucan
  Tucan.histogram(:cars, "Horsepower")
  ```

  You can flip the plot by setting the `:orient` option to `:vertical`:

  ```tucan
  Tucan.histogram(:cars, "Horsepower", orient: :vertical)
  ```

  You can also modify the default color and add a radius to the histogram bars:

  ```tucan
  Tucan.histogram(:cars, "Horsepower", orient: :vertical, fill_color: "red", corner_radius: 5)
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
    Tucan.histogram(:cars, "Horsepower", color_by: "Origin", tooltip: true)
    |> Tucan.facet_by(:column, "Origin")

  relative_histograms =
    Tucan.histogram(:cars, "Horsepower", relative: true, color_by: "Origin", tooltip: true)
    |> Tucan.facet_by(:column, "Origin")

  Tucan.vconcat([histograms, relative_histograms])
  ```
  """
  @doc section: :plots
  @spec histogram(plotdata :: plotdata(), field :: String.t(), opts :: keyword()) :: VegaLite.t()
  def histogram(plotdata, field, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @histogram_schema)

    spec_opts = Tucan.Options.take_options(opts, @histogram_opts, :spec)

    mark_opts =
      Tucan.Options.take_options(opts, @histogram_opts, :mark)
      |> Tucan.Keyword.put_not_nil(:color, opts[:fill_color])
      |> Tucan.Keyword.put_not_nil(:corner_radius_end, opts[:corner_radius])

    plotdata
    |> new(spec_opts ++ [tucan: [plot: :histogram]])
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
      case Tucan.Options.take_options(opts, @histogram_opts, :bin) do
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
    filled: [
      type: :boolean,
      doc: "Whether the density plot will be filled or not, default to `true` if not set",
      section: :style
    ],
    group_by: [
      type: {:list, :string},
      doc: """
      The data fields to group by. If not specified, a single group containing all data
      objects will be used. This is applied only on the density transform.

      In most cases you only need to set `:color_by` which will automatically handle the
      density transform grouping. Use `:group_by` only if you want to manually post-process
      the generated specification, or if you want to apply grouping by more than one
      variable.

      If both `:group_by` and `:color_by` are set then only `:group_by` is used for grouping
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
    ],
    stacked: [
      type: :boolean,
      doc: """
      Whether the density plots will be stacked or not.
      """,
      default: false
    ]
  ]

  @density_opts Tucan.Options.take!(
                  [
                    @global_opts,
                    @global_mark_opts,
                    :color_by,
                    :x,
                    :y,
                    :orient,
                    :fill_color,
                    :interpolate,
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
  > Alternatively you should use the `:group_by` option in order to group the density
  > transform by the `Species` field and then apply the `color_by/3` function:
  >
  > ```elixir
  > Tucan.density(:penguins, "Body Mass (g)", group_by: ["Species"], fill_opacity: 0.2)
  > |> Tucan.color_by("Species")
  > ```

  See also `histogram/3`.

  ## Options

  #{Tucan.Options.docs(@density_opts)}

  ## Examples

  ```tucan
  Tucan.density(:penguins, "Body Mass (g)")
  ```

  It is a common use case to compare the density of several groups in a dataset. Several
  options exist to do so. You can plot all items on the same chart, using transparency and
  annotation to make the comparison possible. You can stack overlapping densities by
  setting the `:stacked` property.

  ```tucan
  unstacked =
    Tucan.density(:penguins, "Body Mass (g)", color_by: "Species", fill_opacity: 0.2)
    |> Tucan.set_title("Unstacked")

  stacked =
    Tucan.density(:penguins, "Body Mass (g)",
      color_by: "Species",
      fill_opacity: 0.8,
      stacked: true
    )
    |> Tucan.set_title("Stacked")

  Tucan.hconcat([unstacked, stacked])
  ```

  You can also combine it with `facet_by/4` in order to draw a different plot for each value
  of the grouping variable. Notice that we need to set the `:group_by` variable in order
  to correctly calculate the density plot per field's value.

  ```tucan
  Tucan.density(:penguins, "Body Mass (g)", group_by: ["Species"])
  |> Tucan.color_by("Species")
  |> Tucan.facet_by(:column, "Species")
  ```

  You can control the smoothing by setting a specific `bandwidth` value (if not set it is
  automatically calculated by vega lite):

  ```tucan
  Tucan.density(:penguins, "Body Mass (g)",
    color_by: "Species",
    bandwidth: 50.0,
    fill_opacity: 0.5
  )
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

  You can change the color of the plot by setting the `:fill_color` option and/or specify if it
  will be filled or not:

  ```tucan
  Tucan.hconcat([
    Tucan.density(:penguins, "Body Mass (g)", fill_color: "red"),
    Tucan.density(:penguins, "Body Mass (g)", filled: false)
  ])
  |> Tucan.set_theme(:ggplot2)
  ```
  """
  # TODO: if filled is set to false we could use a line mark instead
  @doc section: :plots
  @spec density(plotdata :: plotdata(), field :: String.t(), opts :: keyword()) :: VegaLite.t()
  def density(plotdata, field, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @density_schema)

    spec_opts = Tucan.Options.take_options(opts, @density_opts, :spec)

    mark =
      case opts[:filled] do
        false -> :line
        _other -> :area
      end

    mark_opts =
      Tucan.Options.take_options(opts, @density_opts, :mark)
      |> Keyword.merge(orient: :vertical)
      |> Tucan.Keyword.put_not_nil(:color, opts[:fill_color])
      |> Tucan.Keyword.put_not_nil(:filled, opts[:filled])
      |> Tucan.Keyword.merge_conditionally([fill_opacity: 0], fn -> opts[:filled] == false end)

    transform_opts =
      Tucan.Options.take_options(opts, @density_opts, :density_transform)
      |> Keyword.drop([:group_by])
      |> Keyword.merge(density: field)
      |> Tucan.Keyword.put_not_nil(:groupby, opts[:group_by])
      |> Tucan.Keyword.put_new_conditionally(:groupby, [opts[:color_by]], fn ->
        opts[:color_by] != nil
      end)

    stack =
      case opts[:stacked] do
        false -> nil
        true -> "zero"
      end

    plotdata
    |> new(spec_opts)
    |> Vl.transform(transform_opts)
    |> Vl.mark(mark, mark_opts)
    |> encode_field(:x, "value", opts,
      type: :quantitative,
      scale: [zero: false],
      axis: [title: field]
    )
    |> encode_field(:y, "density", opts, type: :quantitative, stack: stack)
    |> maybe_encode_field(:color, fn -> opts[:color_by] != nil end, opts[:color_by], opts, [])
    |> maybe_flip_axes(opts[:orient] == :vertical)
  end

  stripplot_opts = [
    group_by: [
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
    ],
    jitter_mode: [
      type: {:in, [:uniform, :normal]},
      doc: """
      The distribution from which the jitter (random offset) will be generated. One of
      `:uniform`, `:normal`. Applicable only when the `:style` is set to `:jitter`.
      """,
      default: :normal
    ],
    point_size: [default: 16]
  ]

  @stripplot_opts Tucan.Options.take!(
                    [
                      @global_opts,
                      @global_mark_opts,
                      :orient,
                      :x,
                      :y,
                      :y_offset,
                      :color_by,
                      :color,
                      :point_size,
                      :point_shape,
                      :point_color
                    ],
                    stripplot_opts
                  )
  @stripplot_schema Tucan.Options.to_nimble_schema!(@stripplot_opts)

  @doc """
  Draws a strip plot (categorical scatterplot).

  A strip plot is a single-axis scatter plot used to visualize the distribution of
  a numerical field. The values are plotted as dots or ticks along one axis, so
  the dots with the same value may overlap.

  You can use the `:jitter` mode for a better view of overlapping points. In this
  case points are randomly shifted along with other axis, which has no meaning in
  itself data-wise.

  Typically several strip plots are placed side by side to compare the distribution
  of a numerical value among several categories.

  ## Options

  #{Tucan.Options.docs(@stripplot_opts)}

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

  You can set the `:group_by` option in order to add a second dimension. Notice that
  the field must be categorical.


  ```tucan
  Tucan.stripplot(:tips, "total_bill", group_by: "day", style: :jitter)
  ```

  The plot would be more clear if you also colored the points with the same field:

  ```tucan
  Tucan.stripplot(:tips, "total_bill", group_by: "day", style: :jitter)
  |> Tucan.color_by("day")
  ```

  You can use `:uniform` distribution instead of the default (`:normal`). Below
  you can see both side by side:

  ```tucan
  normal =
    Tucan.stripplot(:movies, "IMDB Rating",
      group_by: "Major Genre",
      style: :jitter,
      point_size: 2,
      width: 300
    )
    |> Tucan.color_by("Major Genre", type: :nominal)
    |> Tucan.set_title("Gaussian jittering")
    |> Tucan.Legend.set_enabled(:color, false)

  uniform =
    Tucan.stripplot(:movies, "IMDB Rating",
      group_by: "Major Genre",
      style: :jitter,
      jitter_mode: :uniform,
      point_size: 2,
      width: 300
    )
    |> Tucan.color_by("Major Genre", type: :nominal)
    |> Tucan.set_title("Uniform jittering")
    |> Tucan.Legend.set_enabled(:color, false)
    |> Tucan.Axes.set_enabled(:y, false)

  Tucan.hconcat([normal, uniform])
  |> VegaLite.resolve(:scale, y_offset: :independent, y: :shared)
  ```

  You can also color by a distinct variable to show a multi-dimensional relationship:

  ```tucan
  Tucan.stripplot(:tips, "total_bill", group_by: "day", style: :jitter)
  |> Tucan.color_by("sex")
  ```

  or you can color by a numerical variable:

  ```tucan
  Tucan.stripplot(:tips, "total_bill", group_by: "day", style: :jitter)
  |> Tucan.color_by("size", type: :ordinal)
  ```

  You could draw the same with points but without jittering:

  ```tucan
  Tucan.stripplot(:tips, "total_bill", group_by: "day", style: :point)
  |> Tucan.color_by("sex")
  ```

  or with ticks which is the default one:

  ```tucan
  Tucan.stripplot(:tips, "total_bill", group_by: "day", style: :tick)
  |> Tucan.color_by("sex")
  ```

  You can set the `:orient` flag to `:vertical` to change the orientation:

  ```tucan
  Tucan.stripplot(:tips, "total_bill", group_by: "day", style: :jitter, orient: :vertical)
  |> Tucan.color_by("sex")
  ```
  """
  @doc section: :plots
  @spec stripplot(plotdata :: plotdata(), field :: String.t(), opts :: keyword()) :: VegaLite.t()
  def stripplot(plotdata, field, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @stripplot_schema)

    spec_opts = Tucan.Options.take_options(opts, @stripplot_opts, :spec)

    plotdata
    |> new(spec_opts)
    |> stripplot_mark(opts[:style], opts)
    |> encode_field(:x, field, opts, type: :quantitative)
    |> maybe_encode_field(:y, fn -> opts[:group_by] != nil end, opts[:group_by], opts,
      type: :nominal
    )
    |> maybe_encode_field(:color, fn -> opts[:color_by] != nil end, opts[:color_by], opts, [])
    |> maybe_add_jitter(opts)
    |> maybe_flip_axes(opts[:orient] == :vertical)
  end

  defp stripplot_mark(vl, :tick, opts), do: Vl.mark(vl, :tick, Keyword.take(opts, [:tooltip]))

  defp stripplot_mark(vl, _other, opts) do
    opts =
      Keyword.take(opts, [:tooltip])
      |> Tucan.Keyword.put_not_nil(:size, opts[:point_size])
      |> Tucan.Keyword.put_not_nil(:shape, opts[:point_shape])
      |> Tucan.Keyword.put_not_nil(:color, opts[:point_color])

    Vl.mark(vl, :point, opts)
  end

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
        |> jitter_transform(opts)
        |> encode_field(:y_offset, "jitter", opts, type: :quantitative, axis: nil)

      _other ->
        vl
    end
  end

  defp jitter_transform(vl, opts) do
    case opts[:jitter_mode] do
      :normal ->
        Vl.transform(vl, calculate: "sqrt(-2*log(random()))*cos(2*PI*random())", as: "jitter")

      :uniform ->
        Vl.transform(vl, calculate: "random()", as: "jitter")
    end
  end

  errorbar_opts = [
    group_by: [
      type: :string,
      doc: """
      A field to be used for grouping the error bars by a category. If not set the plot will
      be one dimensional.
      """
    ],
    extent: [
      type: {:in, [:ci, :stderr, :stdev, :iqr]},
      doc: """
      The extent of the rule. Can be one of the following:

      * `:ci` - Extend the rule to the confidence interval of the mean.
      * `:stderr` - The size of rule are set to the value of standard error, extending from the mean.
      * `:stdev` - The size of rule are set to the value of standard deviation, extending from the
      mean.
      * `:iqr` - Extend the rule to the q1 and q3.
      """,
      default: :stderr,
      dest: :mark
    ],
    ticks: [
      type: :boolean,
      doc: "If set ticks will be included to the error bars ends",
      dest: :mark
    ],
    points: [
      type: :boolean,
      doc: "If set the means of the error bar are also included."
    ],
    point_color: [
      type: :string,
      doc: "The color of the points if enabled. If not set defaults to the error bars color",
      section: :style
    ]
  ]

  @errorbar_opts Tucan.Options.take!(
                   [
                     @global_opts,
                     @global_mark_opts,
                     :orient,
                     :x,
                     :y,
                     :line_color,
                     :stroke_width
                   ],
                   errorbar_opts
                 )
  @errorbar_schema Tucan.Options.to_nimble_schema!(@errorbar_opts)

  @doc """
  Plots the errorbar for the given numerical variable `field`.

  Error bars sho by default the standard error. It can also be explicitly specified by setting
  `:extent` to `:stderr`. The length of lower and upper rules represent standard error. By
  default, the rule marks expand from the mean.

  ## Options

  #{Tucan.Options.docs(@errorbar_opts)}

  ## Examples

  A 1-d error bar:

  ```tucan
  Tucan.errorbar(:barley, "yield")
  ```

  By setting the `:group_by` option you can show the error range of a continuous field
  broken down by categories.

  ```tucan
  Tucan.errorbar(:barley, "yield", group_by: "variety")
  ```

  You can change the orientation by setting the `:orient` option:

  ```tucan
  Tucan.errorbar(:barley, "yield", group_by: "variety", orient: :vertical)
  ```

  By setting `:ticks` to `true` you can enable errorbar end ticks. Also you can overlay the
  means by setting `:points` to `true`.

   ```tucan
  Tucan.errorbar(:barley, "yield", group_by: "variety", ticks: true, points: true)
  ```

  You can change the `:extent` value in order to configure how the error bars are extended. Below
  you can see all supported options:

  ```tucan
  valid_extent_values = [:ci, :stderr, :stdev, :iqr]

  plots =
    for extent <- valid_extent_values do
      Tucan.errorbar(:barley, "yield", group_by: "variety", extent: extent)
      |> Tucan.set_title(inspect(extent) <> " extent")
      |> Tucan.Axes.set_enabled(:y, extent == :ci)
      |> Tucan.set_size(160, 160)
    end

  Tucan.hconcat(plots)
  ```

  You can use `:line_color` and `:stroke_width` to modify the look of the error bars:

  ```tucan
  Tucan.errorbar(:barley, "yield", group_by: "variety", line_color: "red", stroke_width: 3, ticks: true, points: true)
  ```

  You can color categories by combining it with `Tucan.color_by/3`.

  ```tucan
  Tucan.errorbar(:barley, "yield", group_by: "variety", points: true)
  |> Tucan.color_by("variety")
  ```
  """
  # TODO: options for configuring tick color and width
  @doc section: :plots
  @spec errorbar(plotdata :: plotdata(), field :: String.t(), opts :: keyword()) :: VegaLite.t()
  def errorbar(plotdata, field, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @errorbar_schema)
    spec_opts = Tucan.Options.take_options(opts, @errorbar_opts, :spec)

    mark_opts =
      Tucan.Options.take_options(opts, @errorbar_opts, :mark)
      |> Tucan.Keyword.put_not_nil(:color, opts[:line_color])
      |> Tucan.Keyword.put_new_conditionally(:rule, [stroke_width: opts[:stroke_width]], fn ->
        opts[:stroke_width] != nil
      end)
      |> Keyword.delete(:stroke_width)

    errorbar_layer =
      Vl.new()
      |> Vl.mark(:errorbar, mark_opts)
      |> encode_field(:x, field, opts, type: :quantitative, scale: [zero: false])
      |> maybe_encode_field(:y, fn -> opts[:group_by] != nil end, opts[:group_by], opts,
        type: :nominal
      )
      |> maybe_flip_axes(opts[:orient] == :vertical)

    points_layer =
      if opts[:points] do
        points_spec_opts =
          Tucan.Keyword.put_not_nil(
            [filled: true],
            :color,
            opts[:point_color] || opts[:line_color]
          )

        [
          Vl.new()
          |> Vl.mark(:point, points_spec_opts)
          |> Vl.encode_field(:x, field, type: :quantitative, aggregate: "mean")
          |> maybe_encode_field(:y, fn -> opts[:group_by] != nil end, opts[:group_by], opts,
            type: :nominal
          )
          |> maybe_flip_axes(opts[:orient] == :vertical)
        ]
      else
        []
      end

    plotdata
    |> new(spec_opts ++ [tucan: [multilayer: true]])
    |> layers([errorbar_layer] ++ points_layer)
  end

  errorband_opts = [
    borders: [
      type: :boolean,
      doc: """
      If set to `true` the error band's border will be added.
      """,
      default: false,
      dest: :mark
    ],
    extent: [
      type: {:in, [:ci, :stderr, :stdev, :iqr]},
      doc: """
      The extent of the rule. Can be one of the following:

      * `:ci` - Extend the rule to the confidence interval of the mean.
      * `:stderr` - The size of rule are set to the value of standard error, extending from the mean.
      * `:stdev` - The size of rule are set to the value of standard deviation, extending from the
      mean.
      * `:iqr` - Extend the rule to the q1 and q3.
      """,
      default: :stderr,
      dest: :mark
    ]
  ]

  @errorband_opts Tucan.Options.take!(
                    [
                      @global_opts,
                      @global_mark_opts,
                      :x,
                      :y,
                      :interpolate,
                      :fill_color,
                      :line_color,
                      :stroke_width,
                      :stroke_dash
                    ],
                    errorband_opts
                  )
  @errorband_schema Tucan.Options.to_nimble_schema!(@errorband_opts)

  @doc """
  Draws an error band (confidence interval).

  An error band summarizes an error range of quantitative values using a set of summary statistics,
  represented by area. Both `x` and `y` should be quantitative variables.

  ## Options

  #{Tucan.Options.docs(@errorband_opts)}

  ## Examples

  ```tucan
  Tucan.errorband(:cars, "Year", "Miles_per_Gallon", x: [time_unit: "year", type: :temporal])
  ```

  You can modify the look of the error band, change the `:extent` and include the borders if needed.

  ```tucan
  Tucan.errorband(:cars, "Year", "Miles_per_Gallon",
    extent: :ci,
    fill_color: "red",
    borders: true,
    x: [time_unit: "year", type: :temporal]
  )
  ```

  You can also change the look of the borders:

  ```tucan
  Tucan.errorband(:cars, "Year", "Miles_per_Gallon",
    extent: :ci,
    fill_color: "black",
    borders: true,
    line_color: "red",
    stroke_width: 3,
    stroke_dash: [7, 5],
    x: [time_unit: "year", type: :temporal]
  )
  ```

  Usually you want to combine the errorband with the mean trend line. You can use
  `Tucan.layers/2` to combine it with a lineplot.

  ```tucan
  errorband = Tucan.errorband(:cars, "Year", "Miles_per_Gallon",
    extent: :ci,
    fill_color: "green",
    x: [time_unit: "year", type: :temporal]
  )

  trendline = Tucan.lineplot(:cars, "Year", "Miles_per_Gallon",
    x: [time_unit: "year", type: :temporal],
    y: [aggregate: :mean]
  )

  Tucan.layers([errorband, trendline])
  ```

  Similar to other Tucan plots you can apply semantic grouping:

  ```tucan
  errorband = Tucan.errorband(:cars, "Year", "Miles_per_Gallon",
    extent: :ci,
    x: [time_unit: "year", type: :temporal]
  )

  trendline = Tucan.lineplot(:cars, "Year", "Miles_per_Gallon",
    x: [time_unit: "year", type: :temporal],
    y: [aggregate: :mean]
  )

  Tucan.layers([errorband, trendline])
  |> Tucan.color_by("Origin")
  |> Tucan.set_width(400)
  ```
  """
  @doc section: :plots
  @spec errorband(plotdata :: plotdata(), x :: String.t(), y :: String.t(), opts :: keyword()) ::
          VegaLite.t()
  def errorband(plotdata, x, y, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @errorband_schema)
    spec_opts = Tucan.Options.take_options(opts, @errorband_opts, :spec)

    border_opts =
      case opts[:borders] do
        true ->
          []
          |> Tucan.Keyword.put_not_nil(:stroke_width, opts[:stroke_width])
          |> Tucan.Keyword.put_not_nil(:stroke_dash, opts[:stroke_dash])
          |> Tucan.Keyword.put_not_nil(:color, opts[:line_color])

        false ->
          false
      end

    mark_opts =
      Tucan.Options.take_options(opts, @errorband_opts, :mark)
      |> Tucan.Keyword.put_not_nil(:color, opts[:fill_color])
      |> Keyword.merge(borders: border_opts)
      |> Keyword.drop([:stroke_width, :stroke_dash])

    new(plotdata, spec_opts)
    |> Vl.mark(:errorband, mark_opts)
    |> encode_field(:x, x, opts, type: :quantitative, scale: [zero: false])
    |> encode_field(:y, y, opts, type: :quantitative, scale: [zero: false])
  end

  boxplot_opts = [
    group_by: [
      type: :string,
      doc: """
      A field to be used for grouping the boxplot. It is used for adding a second dimension to
      the plot. If not set the plot will be one dimensional. Notice that a grouping is automatically
      applied if the `:color_by` option is set.
      """,
      section: :grouping
    ],
    mode: [
      type: {:in, [:tukey, :min_max]},
      doc: """
      The type of the box plot. Either a Tukey box plot (`:tukey`) or a min-max plot (`:min_max`)
      will be created.
      """,
      default: :tukey
    ],
    k: [
      type: :float,
      doc: """
      The constant used for calculating the extent of the whiskers in a Tukey boxplot. Applicable
      only if `:mode` is set to `:tukey`.
      """,
      default: 1.5
    ]
  ]

  @boxplot_opts Tucan.Options.take!(
                  [@global_opts, @global_mark_opts, :orient, :color_by, :x, :y, :color],
                  boxplot_opts
                )
  @boxplot_schema Tucan.Options.to_nimble_schema!(@boxplot_opts)

  @doc """
  Returns the specification of a box plot.

  By default a one dimensional box plot of the `:field` - which must be a numerical variable - is
  generated. You can add a second dimension across a categorical variable by either setting the
  `:group_by` or `:color_by` options.

  By default a Tukey box plot will be generated. In the Tukey box plot the whisker spans from
  the smallest data to the largest data within the range `[Q1 - k * IQR, Q3 + k * IQR]` where
  `Q1`and `Q3` are the first and third quartiles while `IQR` is the interquartile range
  `(Q3-Q1)`. You can specify if needed the constant `k` which defaults to 1.5.

  Additionally you can set the `mode` to `:min_max`  where the lower and upper whiskers are
  defined as the min and max respectively. No points will be considered as outliers for this
  type of box plots. In this case the `k` value is ignored.

  > #### What is a box plot {: .info}
  >
  > A box plot (box and whisker plot) displays the five-number summary of a set of data. The
  > five-number summary is the minimum, first quartile, median, third quartile, and maximum.
  > In a box plot, we draw a box from the first quartile to the third quartile. A vertical
  > line goes through the box at the median.

  ## Options

  #{Tucan.Options.docs(@boxplot_opts)}

  ## Examples

  A one dimensional Tukey boxplot:

  ```tucan
  Tucan.boxplot(:penguins, "Body Mass (g)")
  ```

  You can set `:group_by` or `:color_by` in order to set a second dimension:

  ```tucan
  Tucan.boxplot(:penguins, "Body Mass (g)", color_by: "Species")
  ```

  You can set the mode to `:min_max` in order to extend the whiskers to the min and max values:

  ```tucan
  Tucan.boxplot(:penguins, "Body Mass (g)", color_by: "Species", mode: :min_max)
  ```

  By setting the `:orient` to `:vertical` you can change the default horizontal orientation:

  ```tucan
  Tucan.boxplot(:penguins, "Body Mass (g)", color_by: "Species", orient: :vertical)
  ```
  """
  @doc section: :plots
  @spec boxplot(plotdata :: plotdata(), field :: String.t(), opts :: keyword()) :: VegaLite.t()
  def boxplot(plotdata, field, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @boxplot_schema)

    extent =
      case opts[:mode] do
        :tukey -> opts[:k]
        :min_max -> "min-max"
      end

    spec_opts = Tucan.Options.take_options(opts, @boxplot_opts, :spec)

    mark_opts =
      Tucan.Options.take_options(opts, @boxplot_opts, :mark)
      |> Keyword.merge(extent: extent)

    group_field = opts[:group_by] || opts[:color_by]

    plotdata
    |> new(spec_opts)
    |> Vl.mark(:boxplot, mark_opts)
    |> encode_field(:x, field, opts, type: :quantitative, scale: [zero: false])
    |> maybe_encode_field(:y, fn -> group_field != nil end, group_field, opts, type: :nominal)
    |> maybe_encode_field(:color, fn -> opts[:color_by] != nil end, opts[:color_by], opts, [])
    |> maybe_flip_axes(opts[:orient] == :vertical)
  end

  heatmap_opts = [
    aggregate: [
      type: :atom,
      doc: """
      The statistic that will be used for aggregating the observations within a heatmap
      tile. Defaults to `:mean` which in case of single data will encode the value of
      the `color` data field.

      Ignored if `:color` is set to `nil`.
      """
    ],
    color_scheme: [
      type: :atom,
      doc: """
      The color scheme to use, for supported color schemes check `Tucan.Scale`. Notice that
      this is just a helper option for easily setting color schemes. If you need to set
      specific colors or customize the scheme, use `Tucan.Scale.set_color_scheme/3`.
      """,
      section: :style
    ],
    annotate: [
      type: :boolean,
      default: false,
      doc: """
      If set to `true` then the values of each cell will be included in the plot.
      """
    ],
    text_color: [
      type:
        {:or,
         [
           :string,
           {:list,
            {:tuple, [{:or, [:integer, :float, nil]}, {:or, [:integer, :float, nil]}, :string]}}
         ]},
      doc: """
      The color to be used for the textual annotations. Valid only if `:annotate` is set
      to `true`. Can be one of the following:
      * a `string` with the color to be used, e.g. `"white"`
      * a list of tuples of the form `{low_threshold, upper_threshold, color}` for
      conditionally setting the color based on the value of the annotated variable.
      `low_threshold` and `upper_threshold` can either be a number or `nil`. For example
      `[{nil, 0, "green"}, {0, 5, "red"}, {5, nil, "white"}]` will apply the following
      colors:
        * `green` for all items with `value < 0`
        * `red` for all items with `value >= 0 && value < 5`
        * `white` for all items with `value >= 5`
      Notice that the `low_threshold`, `upper_threshold` correspond to the
      `[low_threshold, upper_threshold)` range.
      """,
      section: :style
    ]
  ]

  @heatmap_opts Tucan.Options.take!(
                  [
                    @global_opts,
                    @global_mark_opts,
                    :x,
                    :y,
                    :color,
                    :text
                  ],
                  heatmap_opts
                )
  @heatmap_schema Tucan.Options.to_nimble_schema!(@heatmap_opts)

  @doc """
  Returns the specification of a heatmap.

  A heatmap is a graphical representation of data where the individual values
  contained in a matrix are represented as colors.

  It expects two categorical fields `x`, `y` which will be used for the axes
  and a numerical field `color`. If `color` is `nil` then the color represents
  the count of the observations for each `x, y`.

  If an `:aggregate` is set this statistic will be used for encoding the color.
  If no `:aggregate` is set the color encodes by default the `:mean` of the
  data.

  ## Options

  #{Tucan.Options.docs(@heatmap_opts)}

  ## Examples

  A simple heatmap of two categorical variables, using a third one for the
  color values.

  ```tucan
  data = [
    %{"x" => "A", "y" => "K", "value" => 0.5},
    %{"x" => "A", "y" => "L", "value" => 1.5},
    %{"x" => "A", "y" => "M", "value" => 4.5},
    %{"x" => "B", "y" => "K", "value" => 1.5},
    %{"x" => "B", "y" => "L", "value" => 2.5},
    %{"x" => "B", "y" => "M", "value" => 0.5},
    %{"x" => "C", "y" => "K", "value" => -1.5},
    %{"x" => "C", "y" => "L", "value" => 5.5},
    %{"x" => "C", "y" => "M", "value" => 1.5},
  ]

  Tucan.heatmap(data, "x", "y", "value", width: 200, height: 200)
  ```

  You can change the color scheme:

  ```tucan
  Tucan.heatmap(:glue, "Task", "Model", "Score", color_scheme: :redyellowgreen, tooltip: true)
  ```

  Heatmaps are also useful for visualizing temporal data. Let's use a heatmap to examine
  how Seattle's max temperature changes over the year. On the _x-axis_ we will encode the
  days of the month along the x-axis, and the months on the _y-axis_. We will aggregate
  over the max temperature for the color field. (example borrowed from
  [here](https://observablehq.com/@jonfroehlich/basic-time-series-plots-in-vega-lite?collection=@jonfroehlich/intro-to-vega-lite))

  ```tucan
  Tucan.heatmap(:weather, "date", "date", "temp_max",
    x: [type: :ordinal, time_unit: :date],
    y: [type: :ordinal, time_unit: :month],
    tooltip: true
  )
  |> Tucan.Scale.set_color_scheme(:redyellowblue, reverse: true)
  |> Tucan.Axes.set_x_title("Day")
  |> Tucan.Axes.set_y_title("Month")
  |> Tucan.Legend.set_title(:color, "Avg Max Temp")
  |> Tucan.set_title("Heatmap of Avg Max Temperatures in Seattle (2012-2015)")
  ```

  You can enable annotations by setting the `:annotate` flag. Notice that you can conditionally
  color the annotation text by setting the `:text_color` option. It expects a list of tuples
  corresponding to `{lower_threshold, upper_threshold, color}`. Below we color white everything
  below 0 and black everything with a value `>=0`.

  ```tucan
  Tucan.heatmap(:weather, "date", "date", "temp_max",
    annotate: true,
    text_color: [{nil, 5, "white"}, {5, 25, "black"}, {25, nil, "white"}],
    x: [type: :ordinal, time_unit: :date],
    y: [type: :ordinal, time_unit: :month],
    text: [format: ".1f"],
    tooltip: true,
    width: 800
  )
  |> Tucan.Scale.set_color_scheme(:redyellowblue, reverse: true)
  |> Tucan.Axes.set_x_title("Day")
  |> Tucan.Axes.set_y_title("Month")
  |> Tucan.Legend.set_title(:color, "Avg Max Temp")
  |> Tucan.set_title("Heatmap of Avg Max Temperatures in Seattle (2012-2015)")
  ```
  """
  @doc section: :plots
  @spec heatmap(
          plotdata :: plotdata(),
          x :: String.t(),
          y :: String.t(),
          color :: nil | String.t(),
          opts :: keyword()
        ) ::
          VegaLite.t()
  def heatmap(plotdata, x, y, color, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @heatmap_schema)
    heatmap_specification(plotdata, x, y, color, :color, :rect, opts, @heatmap_opts)
  end

  @punchcard_opts Tucan.Options.take!(
                    [
                      @global_opts,
                      @global_mark_opts,
                      :x,
                      :y,
                      :size
                    ],
                    heatmap_opts
                  )
  @punchcard_schema Tucan.Options.to_nimble_schema!(@punchcard_opts)

  @doc """
  Returns the specification of a punch card plot.

  A punch card plot is similar to a heatmap but instead of color the third
  dimension is encoded by the size of bubbles.

  See also `heatmap/5`.

  ## Options

  #{Tucan.Options.docs(@punchcard_opts)}

  ## Examples

  ```tucan
  Tucan.punchcard(:weather, "date", "date", "temp_max",
    tooltip: true,
    x: [type: :ordinal, time_unit: :date],
    y: [type: :ordinal, time_unit: :month]
  )
  |> Tucan.Axes.set_x_title("Day")
  |> Tucan.Axes.set_y_title("Month")
  |> Tucan.set_title("Punch card of Avg Max Temperatures in Seattle (2012-2015)")
  ```

  You can add a fourth dimension by coloring the plot by a fourth variable. Notice how
  we use `Tucan.Scale.set_color_scheme/3` to apply a semantically reasonable coloring and
  `Tucan.Legend.set_orientation/3` to change the default position of the two legends.

  ```tucan
  Tucan.punchcard(:weather, "date", "date", "precipitation",
    tooltip: true,
    x: [type: :ordinal, time_unit: :date],
    y: [type: :ordinal, time_unit: :month]
  )
  # we need to set recursive to true since this is a layered plot
  |> Tucan.color_by("temp_max", aggregate: :mean, recursive: true)
  |> Tucan.Scale.set_color_scheme(:redyellowblue, reverse: true)
  |> Tucan.Axes.set_x_title("Day")
  |> Tucan.Axes.set_y_title("Month")
  |> Tucan.Legend.set_orientation(:color, "bottom")
  |> Tucan.Legend.set_orientation(:size, "bottom")
  ```
  """
  @doc section: :plots
  @spec punchcard(
          plotdata :: plotdata(),
          x :: String.t(),
          y :: String.t(),
          size :: nil | String.t(),
          opts :: keyword()
        ) ::
          VegaLite.t()
  def punchcard(plotdata, x, y, size, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @punchcard_schema)
    heatmap_specification(plotdata, x, y, size, :size, :circle, opts, @punchcard_opts)
  end

  defp heatmap_specification(plotdata, x, y, z, z_encoding, mark, opts, plot_opts) do
    spec_opts = Tucan.Options.take_options(opts, plot_opts, :spec)
    mark_opts = Tucan.Options.take_options(opts, plot_opts, :mark)

    opts =
      if opts[:color_scheme] do
        Keyword.update!(opts, :color, fn color_opts ->
          Tucan.Keyword.deep_merge([scale: [scheme: opts[:color_scheme]]], color_opts)
        end)
      else
        opts
      end

    z_aggregate =
      case z do
        nil -> :count
        _field -> opts[:aggregate] || :mean
      end

    z_fn = fn vl, encoding ->
      case z do
        nil ->
          encode(vl, encoding, opts, type: :quantitative, aggregate: z_aggregate)

        field ->
          encode_field(vl, encoding, field, opts,
            aggregate: z_aggregate,
            type: :quantitative
          )
      end
    end

    base_layer =
      [
        Vl.new()
        |> Vl.mark(mark, mark_opts)
        |> encode_field(:x, x, opts, type: :nominal)
        |> encode_field(:y, y, opts, type: :nominal)
        |> z_fn.(z_encoding)
      ]

    text_layer =
      if opts[:annotate] do
        [
          Vl.new()
          |> Vl.mark(:text)
          |> encode_field(:x, x, opts, type: :nominal)
          |> encode_field(:y, y, opts, type: :nominal)
          |> z_fn.(:text)
          |> maybe_color_annotation(opts[:text_color], z, z_aggregate)
        ]
      else
        []
      end

    plotdata
    |> new(spec_opts ++ [tucan: [multilayer: true]])
    |> layers(base_layer ++ text_layer)
  end

  defp maybe_color_annotation(vl, nil, _field, _aggregate), do: vl

  defp maybe_color_annotation(vl, color, _field, _aggregate) when is_binary(color) do
    Vl.encode(vl, :color, value: color)
  end

  defp maybe_color_annotation(vl, conditions, field, aggregate) do
    conditions =
      Enum.map(conditions, &to_vl_condition(&1, field, aggregate)) ++
        [[test: "true", value: "black"]]

    case field do
      nil ->
        Vl.encode(vl, :color, type: :quantitative, aggregate: :count, condition: conditions)

      field ->
        Vl.encode_field(vl, :color, field,
          aggregate: aggregate,
          type: :quantitative,
          condition: conditions
        )
    end
  end

  defp to_vl_condition({nil, nil, _value} = condition, field, _aggregate),
    do: raise(ArgumentError, "invalid condition #{inspect(condition)} for field #{field}")

  defp to_vl_condition({nil, upper, value}, field, aggregate),
    do: [value: value, test: "datum['#{datum_field_name(field, aggregate)}'] < #{upper}"]

  defp to_vl_condition({lower, nil, value}, field, aggregate),
    do: [value: value, test: "datum['#{datum_field_name(field, aggregate)}'] >= #{lower}"]

  defp to_vl_condition({lower, upper, value}, field, aggregate),
    do: [
      value: value,
      test:
        "datum['#{datum_field_name(field, aggregate)}'] >= #{lower} && datum['#{datum_field_name(field, aggregate)}'] < #{upper}"
    ]

  # We manually construct the datum field name using the default naming convention of
  # vega lite since we are using aggregations by default
  defp datum_field_name(_field, :count), do: "__count"
  defp datum_field_name(field, aggregate), do: "#{aggregate}_#{field}"

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
                          [
                            @global_opts,
                            @global_mark_opts,
                            :x,
                            :y,
                            :color
                          ],
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

  #{Tucan.Options.docs(@density_heatmap_opts)}

  ## Examples

  Let's start with a default density heatmap on the penguins dataset:

  ```tucan
  Tucan.density_heatmap(:penguins, "Beak Length (mm)", "Beak Depth (mm)")
  ```

  You can summarize over another field:

  ```tucan
  Tucan.density_heatmap(:penguins, "Beak Length (mm)", "Beak Depth (mm)", z: "Body Mass (g)", aggregate: :mean)
  ```
  """
  @doc section: :plots
  @spec density_heatmap(
          plotdata :: plotdata(),
          x :: String.t(),
          y :: String.t(),
          opts :: keyword()
        ) ::
          VegaLite.t()
  def density_heatmap(plotdata, x, y, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @density_heatmap_schema)

    spec_opts = Tucan.Options.take_options(opts, @density_heatmap_opts, :spec)
    mark_opts = Tucan.Options.take_options(opts, @density_heatmap_opts, :mark)

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

  bar_opts = [
    mode: [
      type: {:in, [:stacked, :normalize, :grouped]},
      doc: """
      The stacking mode, applied only if `:color_by` is set. Can be one of the
      following:
        * `:stacked` - the default one, bars are stacked
        * `:normalize` - the bars are stacked are normalized
        * `:grouped` - no stacking is applied, a separate bar for each category
      """,
      default: :stacked
    ],
    # override default value for orient
    orient: [
      default: :vertical
    ]
  ]

  @bar_opts Tucan.Options.take!(
              [
                @global_opts,
                @global_mark_opts,
                :color_by,
                :orient,
                :x,
                :y,
                :color,
                :fill_color,
                :corner_radius,
                :x_offset
              ],
              bar_opts
            )
  @bar_schema Tucan.Options.to_nimble_schema!(@bar_opts)

  @doc """
  Draws a bar chart.

  A bar chart is consisted by a categorical `field` and a numerical `value` field that
  defines the height of the bars. You can create a grouped bar chart by setting
  the `:color_by` option.

  Additionally you should specify the aggregate for the `y` values, if your dataset contains
  more than one values per category.

  See also `lollipop/4`.

  ## Options

  #{Tucan.Options.docs(@bar_opts)}

  ## Examples

  A simple bar chart:

  ```tucan
  data = [
    %{"a" => "A", "b" => 28}, %{"a" => "B", "b" => 55}, %{"a" => "C", "b" => 43},
    %{"a" => "D", "b" => 91}, %{"a" => "E", "b" => 81}, %{"a" => "F", "b" => 53},
    %{"a" => "G", "b" => 19}, %{"a" => "H", "b" => 87}, %{"a" => "I", "b" => 52}
  ]

  Tucan.bar(data, "a", "b", fill_color: "#33245A", corner_radius: 5)
  ```

  You can set a `color_by` option that will create a stacked bar chart:

  ```tucan
  Tucan.bar(:weather, "date", "date",
    color_by: "weather",
    tooltip: true,
    x: [type: :ordinal, time_unit: :month],
    y: [aggregate: :count]
  )
  ```

  If you set the mode option to `:grouped` you will instead have a different bar
  per group, you can also change the orientation by setting the `:orient` flag.
  Similarly you can set the mode to `:normalize` in order to have normalized
  stacked bars.

  ```tucan
  data = [
      %{"category" => "A", "group" => "x", "value" => 0.1},
      %{"category" => "A", "group" => "y", "value" => 0.6},
      %{"category" => "A", "group" => "z", "value" => 0.9},
      %{"category" => "B", "group" => "x", "value" => 0.7},
      %{"category" => "B", "group" => "y", "value" => 0.2},
      %{"category" => "B", "group" => "z", "value" => 1.1},
      %{"category" => "C", "group" => "x", "value" => 0.6},
      %{"category" => "C", "group" => "y", "value" => 0.1},
      %{"category" => "C", "group" => "z", "value" => 0.2}
  ]

  grouped =
    Tucan.bar(
      data, "category", "value",
      color_by: "group",
      mode: :grouped,
      orient: :horizontal
    )

  normalized =
    Tucan.bar(
      data, "category", "value",
      color_by: "group",
      mode: :normalize
    )

  Tucan.hconcat([grouped, normalized])
  ```
  """
  @doc section: :plots
  @spec bar(plotdata :: plotdata(), field :: String.t(), value :: String.t(), opts :: keyword()) ::
          VegaLite.t()
  def bar(plotdata, field, value, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @bar_schema)

    spec_opts = Tucan.Options.take_options(opts, @bar_opts, :spec)

    mark_opts =
      Tucan.Options.take_options(opts, @bar_opts, :mark)
      |> Tucan.Keyword.put_not_nil(:color, opts[:fill_color])
      |> Tucan.Keyword.put_not_nil(:corner_radius_end, opts[:corner_radius])

    y_opts =
      case opts[:mode] do
        :normalize -> [stack: :normalize]
        _other -> []
      end
      |> Keyword.merge(type: :quantitative)

    plotdata
    |> new(spec_opts)
    |> Vl.mark(:bar, mark_opts)
    |> encode_field(:x, field, opts, type: :nominal, axis: [label_angle: 0])
    |> encode_field(:y, value, opts, y_opts)
    |> maybe_encode_field(:color, fn -> opts[:color_by] != nil end, opts[:color_by], opts, [])
    |> maybe_x_offset(opts[:color_by], opts[:mode] == :grouped, opts)
    |> maybe_flip_axes(opts[:orient] == :horizontal)
  end

  lollipop_opts = [
    group_by: [
      type: :string,
      doc: """
      A categorical field to group the lollipops by. It is used for adding a second dimension to
      the plot. When set, the groups are also color coded by the same categorical variable.
      """,
      section: :grouping
    ],
    line_color: [default: "black"],
    point_color: [default: "black"],
    point_size: [default: 60],
    orient: [default: :vertical]
  ]

  @lollipop_opts Tucan.Options.take!(
                   [
                     @global_opts,
                     :tooltip,
                     :color_by,
                     :orient,
                     :x,
                     :y,
                     :x_offset,
                     :color,
                     :point_color,
                     :point_shape,
                     :point_size,
                     :line_color
                   ],
                   lollipop_opts
                 )
  @lollipop_schema Tucan.Options.to_nimble_schema!(@lollipop_opts)

  @doc """
  Draws a lollipop plot.

  A lollipop plot is nothing more than a bar plot, where the bar is transformed in a line and a dot. It shows
  the relationship between a numeric and a categoric variable.

  > #### Comparison to `bar/4` {: .tip}
  >
  > The lollipop plot is used exactly in the same situation as a bar plot. However it is somewhat more
  > appealing and convey as well the information. It is especially useful when you have several bars of the
  > same height.
  >
  > ```tucan
  > data = [
  >   category: ["A", "B", "C", "D", "E"],
  >   value: [99, 97, 94, 90, 88]
  > ]
  >
  > bar = Tucan.bar(data, "category", "value", orient: :horizontal)
  > lollipop = Tucan.lollipop(data, "category", "value", orient: :horizontal)
  >
  > Tucan.hconcat([bar, lollipop])
  > ```

  See also `bar/4`.

  ## Options

  #{Tucan.Options.docs(@lollipop_opts)}

  ## Examples

  A lollipop chart for some synthetic data:

  ```tucan
  data =
    for category <- ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"] do
      %{category: category, value: 9 + :rand.uniform(90)}
    end

  Tucan.lollipop(data, "category", "value", width: 400)
  ```

  You can make the lollipops horizontal by setting the `:orient` flag:

  ```tucan
  data =
    for category <- ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"] do
      %{category: category, value: 9 + :rand.uniform(90)}
    end

  Tucan.lollipop(data, "category", "value", width: 400, orient: :horizontal)
  ```

  You can change the points shape and the default colors if needed:

  ```tucan
  data =
    for category <- ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"] do
      %{category: category, value: 9 + :rand.uniform(90)}
    end

  Tucan.lollipop(data, "category", "value",
    point_color: "red",
    point_shape: "square",
    point_size: 80,
    line_color: "blue",
    width: 400
  )
  ```

  If you need to group by a second categorical variable you can use the `:group_by` option:

  ```tucan
  data =
    for category <- ["A", "B", "C", "D", "E", "F", "G"],
        country <- ["US", "GR", "UK", "IT"] do
      %{category: category, country: country, value: 9 + :rand.uniform(90)}
    end

  Tucan.lollipop(data, "category", "value", group_by: "country", orient: :horizontal)
  |> Tucan.set_size(400, 300)
  ```
  """
  @doc section: :plots
  @spec lollipop(
          plotdata :: plotdata(),
          field :: String.t(),
          value :: String.t(),
          opts :: keyword()
        ) :: VegaLite.t()
  def lollipop(plotdata, field, value, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @lollipop_schema)

    spec_opts = Tucan.Options.take_options(opts, @lollipop_opts, :spec)
    mark_opts = Tucan.Options.take_options(opts, @lollipop_opts, :mark)

    y_opts = [type: :quantitative]

    rule_mark_opts = Tucan.Keyword.put_not_nil(mark_opts, :color, opts[:line_color])

    rule_layer =
      Vl.new()
      |> Vl.mark(:rule, rule_mark_opts)
      |> encode_field(:x, field, opts, type: :nominal, axis: [label_angle: 0])
      |> encode_field(:y, value, opts, y_opts)
      |> maybe_encode_field(:color, fn -> opts[:group_by] != nil end, opts[:group_by], opts,
        type: :nominal
      )
      |> maybe_encode_field(
        :x_offset,
        fn -> opts[:group_by] != nil end,
        opts[:group_by],
        opts,
        type: :nominal
      )
      |> maybe_flip_axes(opts[:orient] == :horizontal)

    point_mark_opts =
      mark_opts
      |> Tucan.Keyword.put_not_nil(:color, opts[:point_color])
      |> Tucan.Keyword.put_not_nil(:shape, opts[:point_shape])
      |> Tucan.Keyword.put_not_nil(:size, opts[:point_size])

    points_layer =
      Vl.new()
      |> Vl.mark(:point, point_mark_opts ++ [filled: true, opacity: 1])
      |> encode_field(:x, field, opts, type: :nominal, axis: [label_angle: 0])
      |> encode_field(:y, value, opts, y_opts)
      |> maybe_encode_field(:color, fn -> opts[:group_by] != nil end, opts[:group_by], opts,
        type: :nominal
      )
      |> maybe_encode_field(
        :x_offset,
        fn -> opts[:group_by] != nil end,
        opts[:group_by],
        opts,
        type: :nominal
      )
      |> maybe_flip_axes(opts[:orient] == :horizontal)

    plotdata
    |> new(spec_opts ++ [tucan: [multilayer: true]])
    |> layers([rule_layer, points_layer])
  end

  @doc """
  Plot the counts of observations for a categorical variable.

  Takes a categorical `field` as input and generates a count plot
  visualization. By default the counts are plotted on the *y-axis*
  and the categorical `field` across the *x-axis*.

  This is similar to `histogram/3` but specifically for a categorical
  variable.

  This is a simple wrapper around `bar/4` where by default the count of
  observations is mapped to the `y` variable.

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

  See `bar/4`

  ## Examples

  We will use the `:titanic` dataset on the following examples. We can
  plot the number of passengers by ticket class:

  ```tucan
  Tucan.countplot(:titanic, "Pclass")
  ```

  You can make the bars horizontal by setting the `:orient` option:

  ```tucan
  Tucan.countplot(:titanic, "Pclass", orient: :horizontal)
  ```

  You can set `:color_by` to group it by a second variable:

  ```tucan
  Tucan.countplot(:titanic, "Pclass", color_by: "Survived")
  ```

  By default the bars are stacked. You can unstack them by setting the
  `:mode` to `:grouped`

  ```tucan
  Tucan.countplot(:titanic, "Pclass", color_by: "Survived", mode: :grouped)
  ```
  """
  @doc section: :plots
  @spec countplot(plotdata :: plotdata(), field :: String.t(), opts :: keyword()) :: VegaLite.t()
  def countplot(plotdata, field, opts \\ []) do
    y_opts =
      Keyword.get(opts, :y, [])
      |> Keyword.merge(aggregate: :count)

    opts = Keyword.put(opts, :y, y_opts)

    bar(plotdata, field, field, opts)
  end

  defp maybe_x_offset(vl, nil, _stacked, _opts), do: vl
  defp maybe_x_offset(vl, _field, false, _opts), do: vl
  defp maybe_x_offset(vl, field, true, opts), do: encode_field(vl, :x_offset, field, opts)

  @scatter_opts Tucan.Options.take!([
                  @global_opts,
                  @global_mark_opts,
                  :filled,
                  :color_by,
                  :shape_by,
                  :size_by,
                  :x,
                  :y,
                  :color,
                  :shape,
                  :size,
                  :point_color,
                  :point_size,
                  :point_shape
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

  #{Tucan.Options.docs(@scatter_opts)}

  ## Examples

  > We will use the `:tips` dataset throughout the following examples.

  Drawing a scatter plot between two variables:

  ```tucan
  Tucan.scatter(:tips, "total_bill", "tip")
  ```

  You can modify the look of the plot by setting various styling options:

  ```tucan
  Tucan.scatter(:tips, "total_bill", "tip",
    point_color: "red",
    point_shape: "triangle-up",
    point_size: 10
  )
  ```

  You can combine it with `color_by/3` to color code the points with respect to
  another variable:

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
  @spec scatter(plotdata :: plotdata(), x :: String.t(), y :: String.t(), opts :: keyword()) ::
          VegaLite.t()
  def scatter(plotdata, x, y, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @scatter_schema)

    spec_opts = Tucan.Options.take_options(opts, @scatter_opts, :spec)

    mark_opts =
      Tucan.Options.take_options(opts, @scatter_opts, :mark)
      |> Tucan.Keyword.put_not_nil(:color, opts[:point_color])
      |> Tucan.Keyword.put_not_nil(:shape, opts[:point_shape])
      |> Tucan.Keyword.put_not_nil(:size, opts[:point_size])

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

  #{Tucan.Options.docs(@bubble_opts)}

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
  |> Tucan.Scale.set_x_scale(:log)
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

    spec_opts = Tucan.Options.take_options(opts, @bubble_opts, :spec)

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

  lineplot_opts = [
    group_by: [
      type: :string,
      doc: "A field to group by the lines without affecting the style of it.",
      section: :grouping
    ],
    points: [
      type: :boolean,
      doc: "Whether points will be included in the chart.",
      default: false,
      section: :style
    ],
    point_color: [
      type: :string,
      doc: "The color of the points, if `:points` is set to `true`.",
      section: :style
    ],
    filled: [
      type: :boolean,
      doc: "Whether the points will be filled or not. Valid only if `:points` is set.",
      default: true,
      section: :style
    ]
  ]

  @lineplot_opts Tucan.Options.take!(
                   [
                     @global_opts,
                     @global_mark_opts,
                     :interpolate,
                     :tension,
                     :color_by,
                     :x,
                     :y,
                     :color,
                     :stroke_width,
                     :stroke_dash,
                     :line_color
                   ],
                   lineplot_opts
                 )
  @lineplot_schema Tucan.Options.to_nimble_schema!(@lineplot_opts)

  @doc """
  Draw a line plot between `x` and `y`

  Both `x` and `y` are considered numerical variables.

  ## Options

  #{Tucan.Options.docs(@lineplot_opts)}

  ## Examples

  Plotting a simple line chart of Google stock price over time. Notice how we change the
  `x` axis type from the default (`:quantitative`) to `:temporal` using the generic
  `:x` channel configuration option:

  ```tucan
  Tucan.lineplot(:stocks, "date", "price", x: [type: :temporal])
  |> VegaLite.transform(filter: "datum.symbol==='GOOG'")
  ```

  You could plot all stocks of the dataset with different colors by setting the `:color_by`
  option. If you do not want to color lines differently, you can pass the `:group_by` option
  instead of `:color_by`:

  ```tucan
  left = Tucan.lineplot(:stocks, "date", "price", x: [type: :temporal], color_by: "symbol")
  right = Tucan.lineplot(:stocks, "date", "price", x: [type: :temporal], group_by: "symbol")

  Tucan.hconcat([left, right])
  ```

  You can also overlay the points by setting the `:points` and `:filled` opts. Notice
  that below we plot by year and aggregating the `y` values:

  ```tucan
  filled_points =
    Tucan.lineplot(:stocks, "date", "price",
      x: [type: :temporal, time_unit: :year],
      y: [aggregate: :mean],
      color_by: "symbol",
      points: true,
      tooltip: true,
      width: 300
    )

  stroked_points =
    Tucan.lineplot(:stocks, "date", "price",
      x: [type: :temporal, time_unit: :year],
      y: [aggregate: :mean],
      color_by: "symbol",
      points: true,
      filled: false,
      tooltip: true,
      width: 300
    )

  Tucan.hconcat([filled_points, stroked_points])
  ```

  You can configure the style of the lines using `:stroke_dash`, `:stroke_width`
  and `:line_color` options.

  ```tucan
  data =
    for i <- 0..100, x = 0.1*i do
      %{x: x, cos: :math.cos(x), sin: :math.sin(x)}
    end

  Tucan.layers([
    Tucan.lineplot(data, "x", "cos", stroke_width: 3, stroke_dash: [5, 2], line_color: "red"),
    Tucan.lineplot(data, "x", "sin", stroke_width: 2, stroke_dash: [5, 3, 2], line_color: "green")
  ])
  |> Tucan.set_width(300)
  ```

  You can use various interpolation methods. Some examples follow:

  ```tucan
  plots =
    for interpolation <- ["linear", "step", "cardinal", "monotone"] do
      Tucan.lineplot(:stocks, "date", "price",
        x: [type: :temporal, time_unit: :year],
        y: [aggregate: :mean],
        color_by: "symbol",
        interpolate: interpolation
      )
      |> Tucan.set_title(interpolation)
    end

  Tucan.concat(plots, columns: 2)
  ```
  """
  @doc section: :plots
  @spec lineplot(plotdata :: plotdata(), x :: field(), y :: field(), opts :: keyword()) ::
          VegaLite.t()
  def lineplot(plotdata, x, y, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @lineplot_schema)

    spec_opts = Tucan.Options.take_options(opts, @lineplot_opts, :spec)

    mark_opts =
      Tucan.Options.take_options(opts, @lineplot_opts, :mark)
      |> maybe_add_point_opts(opts[:points], opts)
      |> Tucan.Keyword.put_not_nil(:color, opts[:line_color])

    plotdata
    |> new(spec_opts)
    |> Vl.mark(:line, mark_opts)
    |> encode_field(:x, x, opts, type: :quantitative)
    |> encode_field(:y, y, opts, type: :quantitative)
    |> maybe_encode_field(:color, fn -> opts[:color_by] != nil end, opts[:color_by], opts, [])
    |> maybe_encode_field(
      :detail,
      fn -> opts[:group_by] != nil end,
      opts[:group_by],
      [detail: []],
      type: :nominal
    )
  end

  defp maybe_add_point_opts(mark_opts, false, _opts), do: mark_opts

  defp maybe_add_point_opts(mark_opts, true, opts) do
    point_opts =
      case opts[:filled] do
        true -> []
        false -> [filled: false, fill: "white"]
      end
      |> Tucan.Keyword.put_not_nil(:color, opts[:point_color])

    Keyword.merge(mark_opts, point: point_opts)
  end

  @doc """
  Returns the specification of a step chart.

  This is a simple wrapper around `lineplot/4` with `:interpolate` set by default
  to `"step"`. If `:interpolate` is set to any of `step, step-before, step-after` it
  will be used. In any other case defaults to `step`.

  ## Options

  Check `lineplot/4`

  ## Examples

  ```tucan
  Tucan.step(:stocks, "date", "price", color_by: "symbol", width: 300, x: [type: :temporal])
  |> Tucan.Scale.set_y_scale(:log)
  ```
  """
  @doc section: :plots
  @spec step(plotdata :: plotdata(), x :: field(), y :: field(), opts :: keyword()) ::
          VegaLite.t()
  def step(plotdata, x, y, opts \\ []) do
    interpolate =
      case opts[:interpolate] do
        step when step in ["step", "step-before", "step-after"] -> step
        _other -> "step"
      end

    opts = Keyword.merge(opts, interpolate: interpolate)
    lineplot(plotdata, x, y, opts)
  end

  area_opts = [
    points: [
      type: :boolean,
      doc: "Whether points will be included in the chart.",
      default: false
    ],
    line: [
      type: :boolean,
      doc: "Whether the line will be included in the chart",
      default: false,
      dest: :mark
    ],
    mode: [
      type: {:in, [:stacked, :normalize, :streamgraph, :no_stack]},
      doc: """
      The stacking mode, applied only if `:color_by` is set. Can be one of the
      following:
        * `:stacked` - the default one, areas are stacked
        * `:normalize` - the stacked charts are normalized
        * `:streamgraph` - the chart is displaced around a central axis
        * `:no_stack` - no stacking is applied
      """,
      default: :stacked
    ]
  ]

  @area_opts Tucan.Options.take!(
               [
                 @global_opts,
                 @global_mark_opts,
                 :interpolate,
                 :tension,
                 :color_by,
                 :x,
                 :y,
                 :color
               ],
               area_opts
             )
  @area_schema Tucan.Options.to_nimble_schema!(@area_opts)

  @doc """
  Returns the specification of an area plot.

  ## Options

  #{Tucan.Options.docs(@area_opts)}

  ## Examples

  A simple area chart of Google stock price over time. Notice how we change the
  `x` axis type from the default (`:quantitative`) to `:temporal` using the generic
  `:x` channel configuration option:

  ```tucan
  Tucan.area(:stocks, "date", "price", x: [type: :temporal])
  |> VegaLite.transform(filter: "datum.symbol==='GOOG'")
  ```

  You can overlay the points and/or the line:

  ```tucan
  Tucan.area(:stocks, "date", "price", x: [type: :temporal], points: true, line: true)
  |> VegaLite.transform(filter: "datum.symbol==='GOOG'")
  ```

  If you add the `:color_by` property then the area charts are stacked by default. Below
  you can see how the generic encoding options can be used in order to modify any part
  of the underlying `VegaLite` specification:

  ```tucan
  Tucan.area(:unemployment, "date", "count",
    color_by: "series",
    x: [type: :temporal, time_unit: :yearmonth, axis: [format: "%Y"]],
    y: [aggregate: :sum],
    color: [scale: [scheme: "category20b"]],
    width: 300,
    height: 200
  )
  ```

  You could change the mode to `:normalize` or `:streamgraph`:

  ```tucan
  left =
    Tucan.area(:unemployment, "date", "count",
      color_by: "series",
      mode: :normalize,
      x: [type: :temporal, time_unit: :yearmonth, axis: [format: "%Y"]],
      y: [aggregate: :sum]
    )
    |> Tucan.set_title("normalize")

  right =
    Tucan.area(:unemployment, "date", "count",
      color_by: "series",
      mode: :streamgraph,
      x: [type: :temporal, time_unit: :yearmonth, axis: [format: "%Y"]],
      y: [aggregate: :sum]
    )
    |> Tucan.set_title("streamgraph")

  Tucan.hconcat([left, right])
  ```

  Or you could disable the stacking at all:

  ```tucan
  Tucan.area(:stocks, "date", "price",
    color_by: "symbol",
    mode: :no_stack,
    x: [type: :temporal],
    width: 400,
    fill_opacity: 0.4
  )
  |> Tucan.Scale.set_y_scale(:log)
  ```
  """
  @doc section: :plots
  @spec area(plotdata :: plotdata(), x :: field(), y :: field(), opts :: keyword()) ::
          VegaLite.t()
  def area(plotdata, x, y, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @area_schema)

    spec_opts = Tucan.Options.take_options(opts, @area_opts, :spec)

    mark_opts =
      Tucan.Options.take_options(opts, @area_opts, :mark)
      |> Keyword.put(:point, Keyword.get(opts, :points, false))

    stack =
      case opts[:mode] do
        :stacked -> true
        :normalize -> "normalize"
        :streamgraph -> "center"
        :no_stack -> false
      end

    plotdata
    |> new(spec_opts)
    |> Vl.mark(:area, mark_opts)
    |> encode_field(:x, x, opts, type: :quantitative)
    |> encode_field(:y, y, opts, type: :quantitative, stack: stack)
    |> maybe_encode_field(:color, fn -> opts[:color_by] != nil end, opts[:color_by], opts, [])
  end

  @doc """
  Returns the specification of a streamgraph.

  This is a simple wrapper around `area/4` with `:mode` set by default
  to `:streamgraph`. Any value set to the `:mode` option will be ignored.

  A grouping field must also be provided which will be set as `:color_by` to
  the area chart.

  ## Options

  Check `area/4`

  ## Examples

  ```tucan
  Tucan.streamgraph(:stocks, "date", "price", "symbol",
    width: 300,
    x: [type: :temporal],
    tooltip: true
  )
  ```
  """
  @doc section: :plots
  @spec streamgraph(
          plotdata :: plotdata(),
          x :: field(),
          y :: field(),
          group :: field(),
          opts :: keyword()
        ) ::
          VegaLite.t()
  def streamgraph(plotdata, x, y, group, opts \\ []) do
    opts = Keyword.merge(opts, mode: :streamgraph, color_by: group)
    area(plotdata, x, y, opts)
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
  of each category. The chart will be colored by the `category` field.

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
  > pie = Tucan.pie(data, "value", "category")
  > bar = Tucan.bar(data, "category", "value", orient: :horizontal)
  >
  > Tucan.hconcat([pie, bar])
  > |> Tucan.set_title("Pie vs Bar chart", anchor: :middle, offset: 15)
  > ```

  ## Options

  #{Tucan.Options.docs(@pie_opts)}

  ## Examples

  ```tucan
  Tucan.pie(:barley, "yield", "site", aggregate: :sum, tooltip: true)
  |> Tucan.facet_by(:column, "year", type: :nominal)
  ```
  """
  @doc section: :plots
  @spec pie(
          plotdata :: plotdata(),
          field :: String.t(),
          category :: String.t(),
          opts :: keyword()
        ) ::
          VegaLite.t()
  def pie(plotdata, field, category, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @pie_schema)

    spec_opts = Tucan.Options.take_options(opts, @pie_opts, :spec)
    mark_opts = Tucan.Options.take_options(opts, @pie_opts, :mark)

    theta_opts =
      opts
      |> Tucan.Options.take_options(@pie_opts, :theta)
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
  @spec donut(
          plotdata :: plotdata(),
          field :: String.t(),
          category :: String.t(),
          opts :: keyword()
        ) ::
          VegaLite.t()
  def donut(plotdata, field, category, opts \\ []) do
    opts = Keyword.put_new(opts, :inner_radius, 50)

    pie(plotdata, field, category, opts)
  end

  ## Image

  imshow_opts = [
    color_scheme: [
      type: :atom,
      doc: """
      The color scheme to be used for the image. Should be one of the supported
      color schemes of `Tucan.Scale.set_color_scheme/3`.
      """,
      default: :viridis
    ],
    reverse: [
      type: :boolean,
      doc: "Whether the color scheme will be reversed or not.",
      default: false
    ],
    origin: [
      type: {:in, [:upper, :lower]},
      doc: """
      Place the `[0, 0]` index of the array in the upper left or lower left corner of the Axes. The
      convention (the default) `:upper` is typically used for matrices and images.

      Note that the vertical axis points upward for `:lower` but downward for `:upper`.

      ```tucan
      data = Nx.tensor([[1, 2, 3], [4, 5, 6], [7, 8, 9]], type: {:f, 32})

      Tucan.hconcat([
        Tucan.imshow(data, width: 200, height: 200, origin: :upper, show_scale: true, tooltip: true)
        |> Tucan.set_title(":upper origin (default)"),
        Tucan.imshow(data, width: 200, height: 200, origin: :lower, show_scale: true, tooltip: true)
        |> Tucan.set_title(":lower origin")
      ])
      ```
      """,
      default: :upper
    ],
    show_scale: [
      type: :boolean,
      doc: "If set the color scale is displayed.",
      default: false,
      section: :style
    ]
  ]

  @imshow_opts Tucan.Options.take!(
                 [
                   :width,
                   :height,
                   :title,
                   :tooltip
                 ],
                 imshow_opts
               )
  @imshow_schema Tucan.Options.to_nimble_schema!(@imshow_opts)

  @doc """
  Display data as an image.

  The input is expected to be an `Nx.Tensor` containing 2D scalar data, which will be
  rendered as a pseudo-color image. The origin is set at the upper left hand corner and
  rows (first dimension of the array) are displayed horizontally. By setting `:origin`
  to `:lower` you can set the origin to the lower left hand corner.

  ## Options

  #{Tucan.Options.docs(@imshow_opts)}

  ## Examples

  > In the following examples we use a subset of the [MNIST dataset](https://en.wikipedia.org/wiki/MNIST_database).
  > The data are stored as a serialized `Nx.Tensor` with shape `{images, height, width, 1}`.

  ```tucan
  mnist_path = Path.expand("../../assets/mnist_sample.bin", __DIR__)
  images = File.read!(mnist_path) |> Nx.deserialize()

  Tucan.imshow(images[[images: 5]], width: 200, height: 200)
  ```

  Below we use `Tucan.concat/2` to plot a grid of 40 images of the MNIST dataset. We
  also set a grayscale color scheme.

  ```tucan
  mnist_path = Path.expand("../../assets/mnist_sample.bin", __DIR__)
  images = File.read!(mnist_path) |> Nx.deserialize()

  images =
    for i <- 1..40 do
      image = images[[images: i]]
      Tucan.imshow(image, width: 60, height: 60, color_scheme: :greys, reverse: true)
    end

  Tucan.concat(images, columns: 10)
  ```

  You can use any of the supported color schemes. Below we draw the same image with 10
  different color schemes with and without `:reverse` set. (Notice how we use `VegaLite.resolve/3`
  to ensure that each sub-plot will have an independent color scale.)

  ```tucan
  mnist_path = Path.expand("../../assets/mnist_sample.bin", __DIR__)
  images = File.read!(mnist_path) |> Nx.deserialize()
  image = images[[images: 2]]

  schemes = [:viridis, :inferno, :plasma, :turbo, :greenblue, :darkgold, :rainbow, :redblue, :greens, :greys]

  non_reversed =
    for scheme <- schemes do
      Tucan.imshow(image, color_scheme: scheme, width: 60, height: 60, title: Atom.to_string(scheme))
    end

  reversed =
    for scheme <- schemes do
      Tucan.imshow(image, color_scheme: scheme, reverse: true, width: 60, height: 60)
    end

  Tucan.vconcat([
    Tucan.hconcat(non_reversed)
    |> VegaLite.resolve(:scale, color: :independent),
    Tucan.hconcat(reversed)
    |> VegaLite.resolve(:scale, color: :independent)
  ])
  ```

  > #### 3d plots visualization {: .tip}
  >
  > You can also use `imshow/2` to "visualize" 3d plots. Below we create a meshgrid
  > and calculate the value of a function across the grid. We then use `imshow/2` to
  > visualize `z` using the color:
  >
  > ```tucan
  > nx = 121
  > ny = 121
  >
  > x = Nx.linspace(-20, 20, n: nx)
  > y = Nx.linspace(-20, 20, n: ny)
  >
  > defmodule Foo do
  >  import Nx.Defn
  >
  >  defn f(x, y) do
  >    Nx.sqrt(Nx.pow(x - 5, 2) + Nx.pow(y - 5, 2))
  >  end
  >
  >  def meshgrid(x, y, nx, ny) do
  >    xx = Nx.broadcast(x, {ny, nx}, axes: [1])
  >    yy = Nx.broadcast(y, {ny, nx}, axes: [0])
  >
  >    {xx, yy}
  >  end
  > end
  >
  > {xx, yy} = Foo.meshgrid(x, y, nx, ny)
  >
  > zz = Foo.f(xx, yy)
  >
  > Tucan.imshow(zz, width: 300, height: 300, origin: :lower, show_scale: true)
  > ```
  """
  @doc section: :images
  @spec imshow(data :: Nx.Tensor.t(), opts :: keyword()) :: VegaLite.t()
  def imshow(data, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @imshow_schema)

    Tucan.Image.show(data, opts)
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
      (vl :: VegaLite.t(), row :: {String.t(), integer()}, column :: {String.t(), integer()})
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
  where each numeric variable in `fields` will be shared across the y-axes across
  a single row and the x-axes across a single column.

  > #### Numerical field types {: .warning}
  >
  > Notice that currently `pairplot/3` works only with numerical (`:quantitative`)
  > variables. If you need to create a pair plot containing other variable types
  > you need to manually build the grid using the `VegaLite` concatenation operations.

  ## Options

  #{Tucan.Options.docs(@pairplot_opts)}

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
          Tucan.stripplot(vl, row_field, group_by: "species", style: :tick)
          |> Tucan.color_by("species")
          |> Tucan.Axes.put_options(:y, labels: false)

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
  @spec pairplot(plotdata :: plotdata(), fields :: [String.t()], opts :: keyword()) ::
          VegaLite.t()
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
        Tucan.Axes.put_options(vl, :x, title: col_field)
      else
        Tucan.Axes.put_options(vl, :x, title: nil)
      end
    end

    y_axis_title = fn vl, col_index ->
      if col_index == 0 do
        Tucan.Axes.put_options(vl, :y, title: row_field)
      else
        Tucan.Axes.put_options(vl, :y, title: nil)
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

  jointplot_opts = [
    width: [
      type: :integer,
      default: 200,
      doc: """
      The dimension of the central (joint) plot. The same value is used for
      both the width and height of the plot.
      """
    ],
    ratio: [
      type: :float,
      default: 0.45,
      doc: """
      The ratio of the marginal plots secondary dimension with respect to
      the joint plot dimension.
      """
    ],
    joint: [
      type: {:in, [:scatter, :density_heatmap]},
      default: :scatter,
      doc: """
      The plot type to be used for the main (joint) plot. Can be one of
      `:scatter` and `:density_heatmap`.
      """
    ],
    joint_opts: [
      type: :keyword_list,
      default: [],
      doc: """
      Arbitrary options list for the joint plot. The supported options
      depend on the selected `:joint` type.
      """
    ],
    marginal: [
      type: {:in, [:histogram, :density]},
      default: :histogram,
      doc: """
      The plot type to be used for the marginal plots. Can be one of
      `:histogram` and `:density`.
      """
    ],
    marginal_opts: [
      type: :keyword_list,
      default: [],
      doc: """
      Arbitrary options list for the marginal plots. The supported options
      depend on the selected `:marginal` type.
      """
    ],
    spacing: [
      type: :pos_integer,
      doc: "The spacing between the marginals and the joint plot.",
      default: 15,
      section: :style
    ]
  ]

  @jointplot_opts Tucan.Options.take!([:width, :title, :color_by, :fill_opacity], jointplot_opts)
  @jointplot_schema Tucan.Options.to_nimble_schema!(@jointplot_opts)

  @doc """
  Returns the specification of a jointplot.

  A jointplot is a plot of two numerical variables along with marginal univariate
  graphs. If no options are set the joint is a scatter plot and the marginal are
  the histograms of the two variables.

  > #### Marginal plots dimensions {: .info}
  >
  > By default a jointplot will have a square shape, e.g. it will have the same
  > width and height. The `:width` option affects the width of the central (joint)
  > plot.
  >
  > For the marginal distributions you can the `:ratio` option which specifies
  > the ratio of joint axes height to marginal axes height.

  ## Options

  #{Tucan.Options.docs(@jointplot_opts)}

  ## Examples

  A simple joint plot between two variables.

  ```tucan
  Tucan.jointplot(:iris, "petal_width", "petal_length", width: 200)
  ```

  You can also pass `:color_by` to apply a semantic grouping. If set it will be
  applied both to the joint and the marginal plots.

  ```tucan
  Tucan.jointplot(
    :iris, "petal_width", "petal_length",
    color_by: "species",
    fill_opacity: 0.5,
    width: 200
  )
  ```

  You can change the type of the join plot and the marginal distributions:

  ```tucan
  Tucan.jointplot(
    :penguins, "Beak Length (mm)", "Beak Depth (mm)",
    joint: :density_heatmap,
    marginal: :density,
    ratio: 0.3
  )
  ```
  """
  @doc section: :composite
  @spec jointplot(plotdata :: plotdata(), x :: field(), y :: field(), opts :: keyword()) ::
          VegaLite.t()
  def jointplot(plotdata, x, y, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @jointplot_schema)

    # TODO: maybe enable this in the future (we need to properly set the legends for this)
    if opts[:joint] == :density_heatmap and opts[:color_by] do
      raise ArgumentError,
            "combining a density_heatmap with the :color_by option is not supported"
    end

    joint_opts =
      opts
      |> Keyword.take([:color_by, :fill_opacity])
      |> Keyword.merge(opts[:joint_opts])

    joint_plot = Vl.new(width: opts[:width], height: opts[:width])

    joint_plot =
      case opts[:joint] do
        :scatter ->
          scatter(joint_plot, x, y, joint_opts)

        :density_heatmap ->
          joint_opts = Keyword.drop(joint_opts, [:color_by])
          density_heatmap(joint_plot, x, y, joint_opts)
      end

    marginal_dimension = ceil(opts[:ratio] * opts[:width])

    marginal_opts =
      Keyword.take(opts, [:color_by, :fill_opacity])
      |> Tucan.Keyword.deep_merge(x: [axis: nil])
      |> Tucan.Keyword.deep_merge(opts[:marginal_opts])

    {marginal_x, marginal_y} =
      marginal_plots(x, y, marginal_dimension, opts[:marginal], marginal_opts)

    plotdata
    |> new(spacing: opts[:spacing], bounds: "flush")
    |> Vl.concat(
      [
        marginal_x,
        Vl.concat(
          Vl.new(spacing: opts[:spacing], bounds: "flush"),
          [joint_plot, marginal_y],
          :horizontal
        )
      ],
      :vertical
    )
  end

  defp marginal_plots(x, y, dimension, type, opts) do
    marginal_x =
      Vl.new(height: dimension)
      |> marginal_plot(x, type, opts)

    marginal_y =
      Vl.new(width: dimension)
      |> marginal_plot(y, type, opts ++ [orient: :vertical])

    {marginal_x, marginal_y}
  end

  defp marginal_plot(vl, x, :histogram, opts), do: histogram(vl, x, opts)
  defp marginal_plot(vl, x, :density, opts), do: density(vl, x, opts)

  ## Grouping functions

  grouping_options = [
    recursive: [
      type: :boolean,
      default: false,
      doc: """
      If set the grouping function will be applied recursively in all valid sub plots. This
      includes both layers and concatenated plots.
      """
    ]
  ]

  @grouping_opts Keyword.keys(grouping_options)
  @grouping_schema NimbleOptions.new!(grouping_options)

  @doc """
  Adds a `color` encoding for the given field.

  ## Options

  #{NimbleOptions.docs(@grouping_schema)}

  `opts` can also contain an arbitrary set of vega-lite supported options that
  will be passed to the underlying encoding.
  """
  @doc section: :grouping
  @spec color_by(vl :: VegaLite.t(), field :: String.t(), opts :: keyword()) :: VegaLite.t()
  def color_by(vl, field, opts \\ []), do: group_by(vl, :color, field, opts)

  @doc """
  Adds a `shape` encoding for the given field.

  ## Options

  #{NimbleOptions.docs(@grouping_schema)}

  `opts` can also contain an arbitrary set of vega-lite supported options that
  will be passed to the underlying encoding.
  """
  @doc section: :grouping
  @spec shape_by(vl :: VegaLite.t(), field :: String.t(), opts :: keyword()) :: VegaLite.t()
  def shape_by(vl, field, opts \\ []), do: group_by(vl, :shape, field, opts)

  @doc """
  Adds a `stroke_dash` encoding for the given field.

  ## Options

  #{NimbleOptions.docs(@grouping_schema)}

  `opts` can also contain an arbitrary set of vega-lite supported options that
  will be passed to the underlying encoding.
  """
  @doc section: :grouping
  @spec stroke_dash_by(vl :: VegaLite.t(), field :: String.t(), opts :: keyword()) :: VegaLite.t()
  def stroke_dash_by(vl, field, opts \\ []), do: group_by(vl, :stroke_dash, field, opts)

  @doc """
  Adds a `fill` encoding for the given field.

  ## Options

  #{NimbleOptions.docs(@grouping_schema)}

  `opts` can also contain an arbitrary set of vega-lite supported options that
  will be passed to the underlying encoding.
  """
  @doc section: :grouping
  @spec fill_by(vl :: VegaLite.t(), field :: String.t(), opts :: keyword()) :: VegaLite.t()
  def fill_by(vl, field, opts \\ []), do: group_by(vl, :fill, field, opts)

  @doc """
  Adds a `size` encoding for the given field.

  By default the type of the `field` is set to `:quantitative`. You can override it in the
  `opts` by setting another `:type`.

  ## Options

  #{NimbleOptions.docs(@grouping_schema)}

  `opts` can also contain an arbitrary set of vega-lite supported options that
  will be passed to the underlying encoding.
  """
  @doc section: :grouping
  @spec size_by(vl :: VegaLite.t(), field :: String.t(), opts :: keyword()) :: VegaLite.t()
  def size_by(vl, field, opts \\ []),
    do: group_by(vl, :size, field, [type: :quantitative] ++ opts)

  defp group_by(vl, encoding, field, opts) do
    {group_opts, opts} = Keyword.split(opts, @grouping_opts)

    group_opts = NimbleOptions.validate!(group_opts, @grouping_schema)

    case group_opts[:recursive] do
      true ->
        apply_recursively(vl, fn spec ->
          Utils.encode_field_raw(spec, encoding, field, opts)
        end)

      _ ->
        Utils.validate_single_view!(vl, "#{encoding}_by", [
          :layers,
          :concat,
          :vconcat,
          :hconcat
        ])

        Vl.encode_field(vl, encoding, field, opts)
    end
  end

  @doc """
  Apply facetting on the input plot `vl` by the given `field`.

  This will create multiple plots either horizontally (`:column` faceting mode),
  vertically (`:row` faceting mode) or arbitrarily (`:wrapped` mode). One plot will
  be created for each distinct value of the given `field`, which must be a
  categorical variable.

  In the case of `:wrapped` a `:columns` option should also be provided which
  will determine the number of columns of the composite plot.

  `opts` is an arbitrary keyword list that will be passed to the `:row` or `:column`
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

  With `:wrapped` mode and custom sorting:

  ```tucan
  Tucan.density(:movies, "IMDB Rating", color_by: "Major Genre")
  |> Tucan.facet_by(:wrapped, "Major Genre", columns: 4, sort: [op: :mean, field: "IMDB Rating"])
  |> Tucan.Legend.set_enabled(:color, false)
  |> Tucan.set_title("Density of IMDB rating by Genre", offset: 20)
  ```
  """
  @doc section: :grouping
  @spec facet_by(
          vl :: VegaLite.t(),
          faceting_mode :: :row | :column | :wrapped,
          field :: String.t(),
          opts :: keyword()
        ) :: VegaLite.t()
  def facet_by(vl, faceting_mode, field, opts \\ [])

  def facet_by(vl, :row, field, opts) do
    Vl.encode_field(vl, :row, field, opts)
  end

  def facet_by(vl, :column, field, opts) do
    Vl.encode_field(vl, :column, field, opts)
  end

  def facet_by(vl, :wrapped, field, opts) do
    Vl.encode_field(vl, :facet, field, opts)
  end

  defp apply_recursively(%VegaLite{} = vl, fun) do
    put_in(vl.spec, do_apply_recursively(vl.spec, fun))
  end

  defp do_apply_recursively(%{"layer" => layers} = spec, fun) do
    layers = do_apply_recursively(layers, fun)
    Map.put(spec, "layer", layers)
  end

  defp do_apply_recursively(%{"vconcat" => vconcat} = spec, fun) do
    vconcat = do_apply_recursively(vconcat, fun)
    Map.put(spec, "vconcat", vconcat)
  end

  defp do_apply_recursively(%{"hconcat" => hconcat} = spec, fun) do
    hconcat = do_apply_recursively(hconcat, fun)
    Map.put(spec, "hconcat", hconcat)
  end

  defp do_apply_recursively(%{"concat" => concat} = spec, fun) do
    concat = do_apply_recursively(concat, fun)
    Map.put(spec, "concat", concat)
  end

  defp do_apply_recursively(spec, fun) when is_map(spec) do
    fun.(spec)
  end

  defp do_apply_recursively(spec, fun) when is_list(spec) do
    Enum.map(spec, fn item -> do_apply_recursively(item, fun) end)
  end

  ## Auxiliary plots

  ruler_opts = [
    line_color: [default: "black"],
    stroke_width: [default: 1],
    aggregate: [
      type: :atom,
      doc: "The aggregate to used for calculating the line's coordinate",
      default: :mean
    ]
  ]

  @ruler_opts Tucan.Options.take!([:color_by, :color, :stroke_dash, :stroke_width], ruler_opts)
  @ruler_schema Tucan.Options.to_nimble_schema!(@ruler_opts)

  @doc """
  Adds a vertical or horizontal ruler at the given position.

  `position` can either be a number representing a coordinate of the _x/y-axis_ or a
  binary representing a field. In the latter case an aggregation can also
  be provided which will be used for aggregating the field distribution
  to a single number. If not set defaults to `:mean`.

  `axis` specifies the orientation of the line. Use `:x` for a vertical
  line and `:y` for a horizontal one.

  See also `vruler/3`, `hruler/3`.

  ## Options

  #{Tucan.Options.docs(@ruler_opts)}

  ## Examples

  You can add a vertical ruler to any _x-axis_ point:

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.ruler(:x, 1.1, stroke_width: 3, line_color: "blue")
  |> Tucan.ruler(:x, 1.4, line_color: "green")
  ```

  Additionally you can can add a vertical line to an aggregated value of
  a data field. For example:

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.ruler(:x, "petal_width", line_color: "red")
  ```

  You can add multiple lines for each group of the data if you pass the
  `color_by` option. Also you can combine vertical with horizontal
  lines.

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length", color_by: "species")
  |> Tucan.ruler(:x, "petal_width", color_by: "species", stroke_width: 3)
  |> Tucan.ruler(:y, "petal_length", color_by: "species", stroke_dash: [5, 5])
  ```
  """
  @doc section: :auxiliary_plots
  @spec ruler(
          vl :: VegaLite.t(),
          axis :: :x | :y,
          position :: number() | String.t(),
          opts :: keyword()
        ) :: VegaLite.t()
  def ruler(vl, axis, position, opts) when axis in [:x, :y] do
    opts = NimbleOptions.validate!(opts, @ruler_schema)

    mark_opts =
      Tucan.Options.take_options(opts, @ruler_opts, :mark)
      |> Keyword.merge(color: opts[:line_color])

    ruler =
      Vl.new()
      |> Vl.mark(:rule, mark_opts)
      |> encode_ruler(axis, position, opts)
      |> maybe_encode_field(
        :color,
        fn -> opts[:color_by] != nil and is_binary(position) end,
        opts[:color_by],
        opts,
        []
      )

    Tucan.Layers.append(vl, ruler)
  end

  @doc """
  Adds a vertical line at the given `x` position.

  For supported options check `ruler/4`.
  """
  @doc section: :auxiliary_plots
  @spec vruler(vl :: VegaLite.t(), position :: number() | String.t(), opts :: keyword()) ::
          VegaLite.t()
  def vruler(vl, x, opts \\ []) do
    ruler(vl, :x, x, opts)
  end

  @doc """
  Adds a horizontal line at the given `h` position.

  For supported options check `ruler/4`.
  """
  @doc section: :auxiliary_plots
  @spec hruler(vl :: VegaLite.t(), position :: number() | String.t(), opts :: keyword()) ::
          VegaLite.t()
  def hruler(vl, y, opts \\ []) do
    ruler(vl, :y, y, opts)
  end

  defp encode_ruler(vl, channel, number, _opts) when is_number(number),
    do: Vl.encode(vl, channel, datum: number)

  defp encode_ruler(vl, channel, field, opts) when is_binary(field) do
    Vl.encode_field(vl, channel, field, type: :quantitative, aggregate: opts[:aggregate])
  end

  @doc """
  Adds a `text` annotation to the given `x, y` position.

  ## Options

  You can pass any of the supported [vega-lite text mark properties](https://vega.github.io/vega-lite/docs/text.html#properties).

  ## Examples

  Multiple annotations on the same plot

  ```tucan
  Tucan.new()
  |> Tucan.annotate(15, 45, "Dennis", size: 25, font: "Courier New")
  |> Tucan.annotate(40, 35, "José", size: 30, color: :purple, font_weight: :bold)
  |> Tucan.annotate(20, 25, "Joe", size: 25, color: :red)
  |> Tucan.annotate(30, 15, "Guido", size: 20, color: :blue)
  |> Tucan.annotate(5, 5, "James", size: 10, color: :orange, angle: 30)
  |> Tucan.Scale.set_x_domain(0, 50)
  |> Tucan.Scale.set_y_domain(0, 50)
  ```
  """
  @doc section: :auxiliary_plots
  @spec annotate(
          vl :: VegaLite.t(),
          x :: number(),
          y :: number(),
          text :: String.t(),
          opts :: keyword()
        ) ::
          VegaLite.t()
  def annotate(vl, x, y, text, opts \\ []) when is_struct(vl, VegaLite) do
    annotation =
      Vl.new()
      |> Vl.data_from_values(%{x: [x], y: [y]})
      |> Vl.mark(:text, opts ++ [text: text])
      |> Vl.encode_field(:x, "x", type: :quantitative)
      |> Vl.encode_field(:y, "y", type: :quantitative)

    Tucan.Layers.append(vl, annotation)
  end

  @doc false
  @deprecated "Use Tucan.Geometry.circle/3 instead"
  @spec circle(
          vl :: VegaLite.t(),
          center :: {number(), number()},
          radius :: number(),
          opts :: keyword()
        ) ::
          VegaLite.t()
  def circle(vl, {x, y}, radius, opts \\ []) do
    circle = Tucan.Geometry.circle({x, y}, radius, opts)

    Tucan.Layers.append(vl, circle)
  end

  ## Layout plots

  @hv_concat_opts Tucan.Options.take!([:width, :height, :title, :align, :bounds, :spacing])
  @hv_concat_schema Tucan.Options.to_nimble_schema!(@hv_concat_opts)

  @doc """
  Concatenates horizontally the given plots.

  ## Options

  #{Tucan.Options.docs(@hv_concat_opts)}
  """
  @doc section: :layout
  @spec hconcat(plots :: [VegaLite.t()], opts :: keyword()) :: VegaLite.t()
  def hconcat(plots, opts \\ []) when is_list(plots) do
    opts = NimbleOptions.validate!(opts, @hv_concat_schema)

    VegaLite.concat(Vl.new(opts), plots, :horizontal)
  end

  @doc """
  Concatenates vertically the given plots.

  ## Options

  #{Tucan.Options.docs(@hv_concat_opts)}
  """
  @doc section: :layout
  @spec vconcat(plots :: [VegaLite.t()], opts :: keyword()) :: VegaLite.t()
  def vconcat(plots, opts \\ []) when is_list(plots) do
    opts = NimbleOptions.validate!(opts, @hv_concat_schema)

    VegaLite.concat(Vl.new(opts), plots, :vertical)
  end

  @concat_opts Tucan.Options.take!([:width, :height, :title, :align, :bounds, :spacing, :columns])
  @concat_schema Tucan.Options.to_nimble_schema!(@concat_opts)

  @doc """
  Concatenates the given plots.

  This corresponds to the general concatenation of vega-lite (wrappable).

  ## Options

  #{Tucan.Options.docs(@concat_opts)}
  """
  @doc section: :layout
  @spec concat(plots :: [VegaLite.t()], opts :: keyword()) :: VegaLite.t()
  def concat(plots, opts \\ []) when is_list(plots) do
    opts = NimbleOptions.validate!(opts, @concat_schema)

    VegaLite.concat(Vl.new(opts), plots, :wrappable)
  end

  @doc """
  Creates a layered plot.

  This is a simple wrapper around `VegaLite.layers/2` which by default adds
  the layers under an empty plot. If a multi-layer plot is passed to `plots`
  then it's layers will be extracted and merged with the rest layers as long
  as the plot has not a top level data item defined.
  """
  @doc section: :layout
  @spec layers(vl :: VegaLite.t(), plots :: [VegaLite.t()]) :: VegaLite.t()
  def layers(vl \\ Vl.new(), plots) do
    plots =
      Enum.reduce(plots, [], fn plot, acc ->
        Tucan.Utils.validate_single_or_layered_view!(plot, "Tucan.layers/2")

        cond do
          Tucan.Utils.single_view?(plot) ->
            acc ++ [plot]

          Map.has_key?(plot.spec, "data") ->
            raise ArgumentError,
                  """
                  Tucan.layers/2 expects either single view plots or multi layer plots without global
                  data, got:

                    #{inspect(plot)}
                  """

          true ->
            vl = Vl.new()

            layers =
              for layer <- plot.spec["layer"] do
                %VegaLite{vl | spec: Map.merge(vl.spec, layer)}
              end

            acc ++ layers
        end
      end)

    VegaLite.layers(vl, plots)
  end

  ## Utility plots

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

    new_vl = Utils.drop_encoding_channels(vl, [:x, :y, :x2, :y2, :x_offset, :y_offset])

    Enum.reduce(axis_pairs, new_vl, fn {left, right}, new_vl ->
      new_vl
      |> copy_encoding(left, right, vl)
      |> copy_encoding(right, left, vl)
    end)
    |> maybe_flip_mark_orient()
  end

  defp maybe_flip_mark_orient(%VegaLite{spec: %{"mark" => %{"orient" => orient}}} = vl),
    do:
      update_in(vl.spec, fn spec ->
        new_orient =
          case orient do
            "vertical" -> "horizontal"
            "horizontal" -> "vertical"
          end

        mark_opts = Map.merge(spec["mark"], %{"orient" => new_orient})
        Map.put(spec, "mark", mark_opts)
      end)

  defp maybe_flip_mark_orient(vl), do: vl

  # copies to left channel, the right channel options from the vl_origin specification
  defp copy_encoding(vl, left, right, vl_origin) do
    case Utils.has_encoding?(vl_origin, left) do
      false ->
        vl

      true ->
        opts = Utils.encoding_options(vl_origin, left) || []
        Utils.encode_raw(vl, right, opts)
    end
  end

  @doc """
  Adds a background image to the current plot.

  ## Examples

  ```tucan
  # generate some random samples
  shots =
    for _index <- 1..30 do
      %{x: Enum.random(10..90), y: Enum.random(10..90), team: Enum.random([:home, :away])}
    end

  pitch_image_url = "https://raw.githubusercontent.com/pnezis/tucan/main/assets/soccer-field.jpeg"

  Tucan.scatter(shots, "x", "y", color_by: "team", filled: true, point_size: 80, tooltip: true)
  |> Tucan.Scale.set_xy_domain(0, 100)
  |> Tucan.Scale.set_color_scheme(["blue", "red"])
  |> Tucan.background_image(pitch_image_url)
  |> Tucan.Axes.set_enabled(false)
  |> Tucan.set_size(700, 350)
  |> Tucan.set_title("Shots")
  ```
  """
  @doc section: :utilities
  @spec background_image(vl :: VegaLite.t(), image_url :: String.t()) :: VegaLite.t()
  def background_image(vl, image_url) do
    vl
    |> Tucan.Layers.to_layered()
    |> Tucan.Layers.prepend(
      Vl.new()
      |> Vl.data_from_values([%{image: image_url}])
      |> Vl.mark(:image, aspect: false, align: :right)
      |> Vl.encode_field(:url, "image", type: :nominal)
    )
  end

  @doc """
  Adds a hyperlink encoding.

  The `field` should be the URL that will be loaded upon mouse click.
  """
  @doc section: :utilities
  @spec href_by(vl :: VegaLite.t(), field :: String.t()) :: VegaLite.t()
  def href_by(vl, field) do
    Utils.validate_single_view!(vl, "href_by/2")

    Vl.encode_field(vl, :href, field)
  end

  ## Styling functions

  @doc """
  Sets the plot size.

  This sets both width and height at once.
  """
  @doc section: :styling
  @spec set_size(vl :: VegaLite.t(), width :: pos_integer(), height :: pos_integer()) ::
          VegaLite.t()
  def set_size(vl, width, height)
      when is_struct(vl, VegaLite) and is_pos_integer(width) and is_pos_integer(height) do
    vl
    |> set_width(width)
    |> set_height(height)
  end

  @doc """
  Sets the width of the plot (in pixels).
  """
  @doc section: :styling
  @spec set_width(vl :: VegaLite.t(), width :: pos_integer()) :: VegaLite.t()
  def set_width(vl, width) when is_struct(vl, VegaLite) and is_pos_integer(width) do
    update_in(vl.spec, fn spec -> Map.merge(spec, %{"width" => width}) end)
  end

  @doc """
  Sets the height of the plot (in pixels).
  """
  @doc section: :styling
  @spec set_height(vl :: VegaLite.t(), height :: pos_integer()) :: VegaLite.t()
  def set_height(vl, height) when is_struct(vl, VegaLite) and is_pos_integer(height) do
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

  If you need to set a multi-line title you can pass a multiline string.

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.set_title("My multiline\\ntitle")
  ```
  """
  @doc section: :styling
  @spec set_title(vl :: VegaLite.t(), title :: String.t(), opts :: keyword()) :: VegaLite.t()
  def set_title(vl, title, opts \\ [])
      when is_struct(vl, VegaLite) and is_binary(title) and is_list(opts) do
    title =
      case String.split(title, "\n") do
        [title] -> title
        title -> title
      end

    title_opts = Keyword.merge(opts, text: title)

    Utils.put_in_spec(vl, :title, title_opts)
  end

  @doc """
  Sets the plot's theme.

  Check `Tucan.Themes` for more details on theming.
  """
  @doc section: :styling
  @spec set_theme(vl :: VegaLite.t(), theme :: atom()) :: VegaLite.t()
  def set_theme(vl, theme) do
    theme = Tucan.Themes.theme(theme)

    Vl.config(vl, theme)
  end

  ## Private functions

  defp maybe_flip_axes(vl, false), do: vl
  defp maybe_flip_axes(vl, true), do: flip_axes(vl)

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
end
