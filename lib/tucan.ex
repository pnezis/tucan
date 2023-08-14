defmodule Tucan do
  @moduledoc """
  Documentation for `Tucan`.
  """
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

  @doc """
  Draw a line plot between `x` and `y`

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
    _opts = NimbleOptions.validate!(opts, [])

    plotdata
    |> new()
    |> Vl.mark(:line)
    |> Vl.encode_field(:x, x, type: :temporal)
    |> Vl.encode_field(:y, y, type: :quantitative)
  end

  mark_general_properties = [
    tooltip: [
      type: {:custom, Tucan.Options, :tooltip, []},
      doc: """
      The tooltip text string to show upon mouse hover or an object defining which fields
      should the tooltip be derived from. Can be one of the following:

      * `:encoding` - all fields from encoding are used
      * `:data` - all fields of the highlighted data point are used
      * `true` - same as `:encoding`
      * `false`, `nil` - no tooltip is used
      """
    ]
  ]

  histogram_opts = [
    fill_opacity: [
      type: :float,
      default: 0.5,
      doc: """
      The fill opacity of the histogram bars.
      """
    ]
  ]

  @histogram_schema NimbleOptions.new!(histogram_opts)

  @doc """
  Plots a histogram.

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

  countplot_opts = [
    stacked: [
      type: :boolean,
      default: true,
      doc: """
      Whether the bars will be stacked or not. Applied only if a grouping
      has been defined.
      """
    ],
    color_by: [
      type: :string,
      doc: """
      If set a column that will be used for coloring the data.
      """
    ]
  ]

  @countplot_schema NimbleOptions.new!(countplot_opts)

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

  global_opts = [
    width: [
      type: :integer,
      doc: "Width of the image"
    ],
    height: [
      type: :integer,
      doc: "Height of the image"
    ],
    title: [
      type: :string,
      doc: "The title of the graph"
    ],
    extra: [
      type: :keyword_list,
      doc: "You can pass here any option supported by VegaLite"
    ]
  ]

  @scatter_schema NimbleOptions.new!(mark_general_properties ++ global_opts)

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
    # TODO : define schema
    opts = NimbleOptions.validate!(opts, @scatter_schema)

    plotdata
    |> new(opts)
    |> Vl.mark(:point, Keyword.take(opts, [:tooltip]))
    |> Vl.encode_field(:x, x, type: :quantitative)
    |> Vl.encode_field(:y, y, type: :quantitative)
  end

  @doc """
  ```vega-lite
  Tucan.stripplot(:weather, "precipitation")
  ```
  """
  @doc section: :plots
  def stripplot(plotdata, x, opts \\ []) do
    # TODO : define schema
    _opts = NimbleOptions.validate!(opts, [])

    plotdata
    |> new()
    |> Vl.mark(:tick)
    |> Vl.encode_field(:x, x, type: :quantitative)
  end

  @doc section: :grouping
  def color_by(vl, field, opts \\ []) do
    Vl.encode_field(vl, :color, field, opts)
  end

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

  # TODO: move into a Tucan.Axes namespace
  @doc section: :utilities
  def set_x_title(vl, title) when is_struct(vl, VegaLite) and is_binary(title) do
    merge_encoding_options!(vl, :x, title: title)
  end

  @doc section: :utilities
  def set_y_title(vl, title) when is_struct(vl, VegaLite) and is_binary(title) do
    merge_encoding_options!(vl, :y, title: title)
  end

  def merge_encoding_options!(vl, encoding, opts) do
    encoding = to_vl_key(encoding)
    validate_encoding!(vl, encoding)

    spec =
      update_in(vl.spec, ["encoding", encoding], fn encoding_opts ->
        Map.merge(encoding_opts, opts_to_vl_props(opts))
      end)

    update_vl_spec(vl, spec)
  end

  defp update_vl_spec(vl, spec), do: %VegaLite{vl | spec: spec}

  defp validate_encoding!(vl, encoding) do
    encoding_opts = get_in(vl.spec, ["encoding", encoding])

    if is_nil(encoding_opts) do
      raise ArgumentError, "encoding #{inspect(encoding)} not found in the spec"
    end
  end

  # these are copied verbatim from VegaLite
  defp opts_to_vl_props(opts) do
    opts |> Map.new() |> to_vl()
  end

  defp to_vl(value) when value in [true, false, nil], do: value

  defp to_vl(atom) when is_atom(atom), do: to_vl_key(atom)

  defp to_vl(%_{} = struct), do: struct

  defp to_vl(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {to_vl(key), to_vl(value)}
    end)
  end

  defp to_vl([{key, _} | _] = keyword) when is_atom(key) do
    Map.new(keyword, fn {key, value} ->
      {to_vl(key), to_vl(value)}
    end)
  end

  defp to_vl(list) when is_list(list) do
    Enum.map(list, &to_vl/1)
  end

  defp to_vl(value), do: value
  defp to_vl_key(key) when is_binary(key), do: key

  defp to_vl_key(key) when is_atom(key) do
    key |> to_string() |> snake_to_camel()
  end

  defp snake_to_camel(string) do
    [part | parts] = String.split(string, "_")
    Enum.join([String.downcase(part, :ascii) | Enum.map(parts, &String.capitalize(&1, :ascii))])
  end
end
