defmodule Tucan.Options do
  @moduledoc false

  # in the sections options the various doc sections are configured. The order is
  # important since it affects the order with which these options will be displayed.
  #
  # Additionally the following options can be set per option:
  # `:header` - the options header
  # `:doc` - an extra markdown text to be rendered before the actual options definition
  #
  # All options without a set section will be grouped under `unknown` which by
  # default is ordered first.
  @sections [
    unknown: [],
    grouping: [
      header: "Data Grouping Options"
    ],
    data: [
      header: "Data Options"
    ],
    style: [
      header: "Styling Options"
    ],
    encodings: [
      header: "Encodings Custom Options",
      doc: """
      All Tucan plots are building a `VegaLite` specification based on some sane
      default parameters. Through these encodings options you are free to set any
      vega-lite supported option to any encoding channel of the plot.

      Notice that if set they will be merged with any option set by the plot. Since they
      have a higher precedence they may override the default settings and affect the
      generated plot.

      You can set an arbitrary keyword list. Notice that **the contents are not validated.**
      """
    ],
    interactivity: [
      header: "Interactivity Options"
    ]
  ]

  options = [
    # Global opts
    width: [
      type: {:or, [:pos_integer, {:in, [:container]}]},
      type_doc: "`t:pos_integer/0` or `:container`",
      doc: """
      Width of the plot. Can either be the width in pixels or `:container` to indicate that
      the width of the plot should be the same as its surrounding container.
      """,
      section: :style,
      dest: :spec
    ],
    height: [
      type: {:or, [:pos_integer, {:in, [:container]}]},
      type_doc: "`t:pos_integer/0` or `:container`",
      doc: """
      Height of the plot. Can either be the height in pixels or `:container` to indicate that
      the height of the plot should be the same as its surrounding container.
      """,
      section: :style,
      dest: :spec
    ],
    title: [
      type: :string,
      doc: "The title of the graph",
      section: :style,
      dest: :spec
    ],
    only: [
      type: {:list, {:or, [:string, :atom]}},
      doc: """
      A subset of fields to pick from the data. Applicable only if tabular data
      are provided.
      """,
      section: :data,
      dest: :spec
    ],

    # Grouping options
    color_by: [
      type: :string,
      doc: """
      If set a data field that will be used for coloring the data. It is considered
      `:nominal` by default.
      """,
      section: :grouping
    ],
    shape_by: [
      type: :string,
      doc: """
      If set a data field that will be used for setting the shape of the data points.
      It is considered `:nominal` by default.
      """,
      section: :grouping
    ],
    size_by: [
      type: :string,
      doc: """
      If set a data field that will be used for controlling the size of the data points.
      It is considered `:quantitative` by default.
      """,
      section: :grouping
    ],

    # Encoding opts
    x: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:x` encoding.
      """,
      default: [],
      section: :encodings
    ],
    x2: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:x2` encoding.
      """,
      default: [],
      section: :encodings
    ],
    x_offset: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:x_offset` encoding.
      """,
      default: [],
      section: :encodings
    ],
    y: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:y` encoding.
      """,
      default: [],
      section: :encodings
    ],
    y2: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:y2` encoding.
      """,
      default: [],
      section: :encodings
    ],
    y_offset: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:y_offset` encoding.
      """,
      default: [],
      section: :encodings
    ],
    theta: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:theta` encoding.
      """,
      default: [],
      section: :encodings
    ],
    color: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:color` encoding.
      """,
      default: [],
      section: :encodings
    ],
    shape: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:shape` encoding.
      """,
      default: [],
      section: :encodings
    ],
    size: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:size` encoding.
      """,
      default: [],
      section: :encodings
    ],
    text: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:text` encoding.
      """,
      default: [],
      section: :encodings
    ],

    # Interactivity options
    tooltip: [
      type: {:custom, Tucan.Options, :tooltip, []},
      type_doc: "`boolean() | :data | :encoding`",
      doc: """
      The tooltip text string to show upon mouse hover or an object defining which fields
      should the tooltip be derived from. Can be one of the following:

      * `:encoding` - all fields from encoding are used
      * `:data` - all fields of the highlighted data point are used
      * `true` - same as `:encoding`
      * `false`, `nil` - no tooltip is used
      """,
      section: :interactivity,
      dest: :mark
    ],

    # Style options
    clip: [
      type: :boolean,
      doc: """
      Whether a mark will be clipped to the enclosing group’s width and height.
      """,
      section: :style,
      dest: :mark
    ],
    corner_radius: [
      type: :non_neg_integer,
      doc: """
      The radius in pixels of rounded rectangles. The end radius is affected:

      - For vertical bars, top-left and top-right corner radius.
      - For horizontal bars, top-right and bottom-right corner radius.
      """,
      section: :style
    ],
    filled: [
      type: :boolean,
      doc: "Whether the mark will be filled or not",
      section: :style,
      dest: :mark
    ],
    fill_opacity: [
      type: {:custom, Tucan.Options, :number_between, [0, 1]},
      type_doc: "`t:number/0`",
      default: 1,
      doc: """
      The fill opacity of the plotted elements.
      """,
      section: :style,
      dest: :mark
    ],
    stroke_opacity: [
      type: {:custom, Tucan.Options, :number_between, [0, 1]},
      type_doc: "`t:number/0`",
      default: 1,
      doc: """
      The opacity of the stroke.
      """,
      section: :style,
      dest: :mark
    ],
    opacity: [
      type: {:custom, Tucan.Options, :number_between, [0, 1]},
      type_doc: "`t:number/0`",
      doc: """
      The overall opacity of the mark
      """,
      section: :style,
      dest: :mark
    ],
    orient: [
      type: {:in, [:horizontal, :vertical]},
      type_doc: "`t:atom/0`",
      doc: """
      The plot's orientation, can be either `:horizontal` or `:vertical`.
      """,
      section: :style,
      default: :horizontal
    ],
    stroke_dash: [
      type: {:list, :pos_integer},
      doc: """
      An array of alternating stroke, space lengths in pixels for creating dashed
      or dotted lines.
      """,
      dest: :mark,
      section: :style
    ],
    stroke_width: [
      type: :pos_integer,
      doc: "The stroke width in pixels",
      dest: :mark,
      section: :style
    ],
    line_color: [
      type: :string,
      doc: "The color of the line",
      section: :style
    ],
    fill_color: [
      type: :string,
      doc: "The fill color of the marks. This will override the `color` encoding if set.",
      section: :style
    ],
    point_color: [
      type: :string,
      doc: "The color of the points",
      section: :style
    ],
    point_shape: [
      type:
        {:in,
         [
           "circle",
           "square",
           "cross",
           "diamond",
           "triangle-up",
           "triangle-down",
           "triangle-right",
           "triangle-left"
         ]},
      doc: "Shape of the point marks. Circle by default.",
      section: :style
    ],
    point_size: [
      type: :pos_integer,
      doc: """
      The pixel area of the marks. Note that this value sets the area of the symbol;
      the side lengths will increase with the square root of this value.
      """,
      section: :style
    ],

    ## Concat options
    align: [
      type: {:in, [:none, :each, :all]},
      doc: """
      The alignment to apply to grid rows and columns. The supported values are `:all`,
      `:each`, and `:none`.

      * For `:none`, a flow layout will be used, in which adjacent subviews are simply
      placed one after the other.
      * For `:each`, subviews will be aligned into a clean grid structure, but each row or
      column may be of variable size.
      * For `:all`, subviews will be aligned and each row or column will be sized identically
      based on the maximum observed size. String values for this property will be applied to
      both grid rows and columns.

      Defaults to `:all` if not set.
      """
    ],
    bounds: [
      type: {:in, [:full, :flush]},
      doc: """
      The bounds calculation method to use for determining the extent of a sub-plot. One
      of `:full` (the default) or `:flush`.

      * If set to `:full`, the entire calculated bounds (including axes, title, and legend)
      will be used.
      * If set to `:flush`, only the specified width and height values for the sub-view
      will be used. The `:flush` setting can be useful when attempting to place sub-plots
      without axes or legends into a uniform grid structure.
      """
    ],
    spacing: [
      type: :pos_integer,
      doc: """
      The spacing in pixels between sub-views of the composition operator. If not set defaults
      to 20.
      """
    ],
    columns: [
      type: :pos_integer,
      doc: "The number of columns to include in the view composition layout."
    ],

    ## Other options
    stacked: [
      type: :boolean,
      default: true,
      doc: """
      Whether the bars will be stacked or not. Applied only if a grouping
      has been defined.
      """
    ],
    interpolate: [
      type:
        {:in,
         [
           "linear",
           "linear-closed",
           "step",
           "step-before",
           "step-after",
           "basis",
           "basis-open",
           "basis-closed",
           "cardinal",
           "cardinal-open",
           "cardinal-closed",
           "bundle",
           "monotone"
         ]},
      type_doc: "`t:binary/0`",
      doc: """
      The line interpolation method to use for line and area marks. One of the following:

      * `"linear"` - piecewise linear segments, as in a poly-line.
      * `"linear-closed"` - close the linear segments to form a polygon.
      * `"step"` - alternate between horizontal and vertical segments, as in a step function.
      * `"step-before"` - alternate between vertical and horizontal segments, as in a step function.
      * `"step-after"` - alternate between horizontal and vertical segments, as in a step function.
      * `"basis"` - a B-spline, with control point duplication on the ends.
      * `"basis-open"` - an open B-spline; may not intersect the start or end.
      * `"basis-closed"` - a closed B-spline, as in a loop.
      * `"cardinal"` - a Cardinal spline, with control point duplication on the ends.
      * `"cardinal-open"` - an open Cardinal spline; may not intersect the start or end, but will
      intersect other control points.
      * `"cardinal-closed"` - a closed Cardinal spline, as in a loop.
      * `"bundle"` - equivalent to basis, except the tension parameter is used to straighten the spline.
      * `"monotone"` - cubic interpolation that preserves monotonicity in y.
      """,
      dest: :mark
    ],
    tension: [
      type: {:or, [:integer, :float]},
      type_doc: "`t:number/0`",
      doc: "Depending on the interpolation type, sets the tension parameter",
      dest: :mark
    ]
  ]

  @options options

  @doc """
  Take the given options from the globally defined options list and optionally merge them
  with `extra`.

  This will return an options list with a subset of the global options optionally augmented
  by the extra. Notice that the result is a plain keyword list and not a `NimbleOptions`
  list since it main contain `Tucan` specific attributes per option. Use `schema/2` in order
  to convert it to a valid `NimbleOptions` schema.

  The input can be either a list of options, or a list of lists.

  This will raise if:

    * Any of the options provided in the `options` list is not a valid option
    * In case of duplicates.
  """
  @spec take!(options :: [atom() | [atom()]], extra :: keyword()) :: keyword()
  def take!(options, extra \\ []) do
    options
    |> List.flatten()
    |> ensure_no_duplicates!()
    |> Enum.map(fn option -> {option, Keyword.fetch!(@options, option)} end)
    |> Tucan.Keyword.deep_merge(extra)
  end

  defp ensure_no_duplicates!(opts) do
    duplicates =
      opts
      |> Enum.group_by(& &1)
      |> Enum.map(fn {key, items} -> {key, length(items)} end)
      |> Enum.filter(fn {_item, count} -> count > 1 end)
      |> Keyword.keys()

    case duplicates do
      [] ->
        opts

      duplicates ->
        raise ArgumentError,
              "the following options were defined more than once: #{inspect(duplicates)}"
    end
  end

  @doc false
  @spec take_options(opts :: keyword(), schema :: keyword(), dest :: atom()) :: keyword()
  def take_options(opts, schema, dest) do
    dest_opts =
      schema
      |> Enum.filter(fn {_key, opts} ->
        opts[:dest] == dest
      end)
      |> Keyword.keys()

    Keyword.take(opts, dest_opts)
  end

  @doc false
  @spec to_nimble_schema!(opts :: keyword()) :: NimbleOptions.t()
  def to_nimble_schema!(opts) do
    opts
    |> drop_tucan_opts_fields()
    |> NimbleOptions.new!()
  end

  @tucan_opts_fields [:section, :dest]

  defp drop_tucan_opts_fields(opts) do
    Enum.map(opts, fn {key, opts} -> {key, Keyword.drop(opts, @tucan_opts_fields)} end)
  end

  @doc false
  @spec docs(keyword(), keyword()) :: String.t()
  def docs(opts, section_opts \\ @sections) when is_list(opts) do
    opts
    |> Enum.group_by(fn {_key, opts} -> Keyword.get(opts, :section, :unknown) end)
    |> Enum.sort_by(fn {section, _opts} -> section_order(section, section_opts) end)
    |> Enum.map_join("\n\n", fn {section, opts} ->
      section_opts_docs(section, opts, section_opts)
    end)
  end

  defp section_order(section, section_opts) do
    section_opts
    |> Keyword.keys()
    |> Enum.with_index()
    |> Keyword.fetch!(section)
  end

  defp section_opts_docs(section, opts, section_opts) do
    section_settings = Keyword.fetch!(section_opts, section)

    [
      section_header(section, section_settings),
      Keyword.get(section_settings, :doc, nil),
      section_nimble_options_docs(%NimbleOptions{schema: Enum.sort(opts)})
    ]
    |> Enum.filter(fn item -> not is_nil(item) end)
    |> Enum.join("\n\n")
  end

  defp section_header(:unknown, _settings), do: nil
  defp section_header(_section, settings), do: "### " <> Keyword.fetch!(settings, :header)

  defp section_nimble_options_docs(schema) do
    schema
    |> NimbleOptions.docs()
    # NimbleOptions adds an extra empty line between each option definition, which I do
    # not like for documenting many options
    |> String.replace("\n\n*", "\n*")
    |> String.trim()
  end

  ## Custom validations

  @doc false
  @spec number_between(value :: term(), min :: number(), max :: number()) ::
          {:ok, number()} | {:error, String.t()}
  def number_between(value, min, max) do
    if is_number(value) and value >= min and value <= max do
      {:ok, value}
    else
      {:error, "expected a number between #{min} and #{max}, got: #{inspect(value)}"}
    end
  end

  @doc false
  @spec tooltip(value :: term()) :: {:ok, boolean() | keyword()} | {:error, String.t()}
  def tooltip(value) do
    cond do
      is_boolean(value) ->
        {:ok, value}

      value == :encoding ->
        {:ok, true}

      value == :data ->
        {:ok, [content: :data]}

      true ->
        {
          :error,
          "expected a boolean, :encoding or :data, got: #{inspect(value)}"
        }
    end
  end

  @doc false
  @spec extent(value :: term()) :: {:ok, [number(), ...]} | {:error, String.t()}
  def extent(value) do
    case value do
      [min, max] when is_number(min) and is_number(max) and min < max ->
        {:ok, [min, max]}

      [min, max] when is_number(min) and is_number(max) ->
        {:error, "expected [min, max] where max > min, got: #{inspect(value)}"}

      other ->
        {:error,
         "g expected [min, max] where min, max numbers and max > min, got: #{inspect(other)}"}
    end
  end

  @doc false
  @spec density_alias(value :: term()) :: {:ok, [String.t(), ...]} | {:error, String.t()}
  def density_alias(alias) do
    if is_binary(alias) do
      {:ok, ["#{alias}_value", "#{alias}_density"]}
    else
      {:error, "expected a string, got: #{inspect(alias)}"}
    end
  end
end
