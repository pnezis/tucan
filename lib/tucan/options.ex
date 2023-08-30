defmodule Tucan.Options do
  @moduledoc false

  # TODO: cleanup sections ordering & descriptions
  @sections [
    unknown: [
      order: -1
    ],
    grouping: [
      order: 3,
      header: "Data Grouping Options"
    ],
    encodings: [
      order: 5,
      header: "Encodings Custom Options"
    ],
    interactivity: [
      order: 7,
      header: "Interactivity Options"
    ],
    style: [
      order: 10,
      header: "Styling Options"
    ]
  ]

  options = [
    # Global opts
    width: [
      type: :integer,
      doc: "Width of the image",
      section: :style,
      dest: :spec
    ],
    height: [
      type: :integer,
      doc: "Height of the image",
      section: :style,
      dest: :spec
    ],
    title: [
      type: :string,
      doc: "The title of the graph",
      section: :style,
      dest: :spec
    ],

    # Encoding opts
    x: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:x` encoding. It can be an arbitrary keyword list.
      Notice that if set they will be merged with any option set by the plot. Since they
      have a higher precedence they may override the default settings and affect the
      generated plot. **The contents are not validated.**
      """,
      default: [],
      section: :encodings
    ],
    x2: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:x2` encoding. It can be an arbitrary keyword list.
      Notice that if set they will be merged with any option set by the plot. Since they
      have a higher precedence they may override the default settings and affect the
      generated plot. **The contents are not validated.**
      """,
      default: [],
      section: :encodings
    ],
    x_offset: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:x_offset` encoding. It can be an arbitrary keyword list.
      Notice that if set they will be merged with any option set by the plot. Since they
      have a higher precedence they may override the default settings and affect the
      generated plot. **The contents are not validated.**
      """,
      default: [],
      section: :encodings
    ],
    y: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:y` encoding. It can be an arbitrary keyword list.
      Notice that if set they will be merged with any option set by the plot. Since they
      have a higher precedence they may override the default settings and affect the
      generated plot. **The contents are not validated.**
      """,
      default: [],
      section: :encodings
    ],
    y_offset: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:y_offset` encoding. It can be an arbitrary keyword list.
      Notice that if set they will be merged with any option set by the plot. Since they
      have a higher precedence they may override the default settings and affect the
      generated plot. **The contents are not validated.**
      """,
      default: [],
      section: :encodings
    ],
    theta: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:theta` encoding. It can be an arbitrary keyword list.
      Notice that if set they will be merged with any option set by the plot. Since they
      have a higher precedence they may override the default settings and affect the
      generated plot. **The contents are not validated.**
      """,
      default: [],
      section: :encodings
    ],
    color: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:color` encoding. It can be an arbitrary keyword list.
      Notice that if set they will be merged with any option set by the plot. Since they
      have a higher precedence they may override the default settings and affect the
      generated plot. **The contents are not validated.**
      """,
      default: [],
      section: :encodings
    ],
    shape: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:shape` encoding. It can be an arbitrary keyword list.
      Notice that if set they will be merged with any option set by the plot. Since they
      have a higher precedence they may override the default settings and affect the
      generated plot. **The contents are not validated.**
      """,
      default: [],
      section: :encodings
    ],
    size: [
      type: :keyword_list,
      doc: """
      Extra vega lite options for the `:size` encoding. It can be an arbitrary keyword list.
      Notice that if set they will be merged with any option set by the plot. Since they
      have a higher precedence they may override the default settings and affect the
      generated plot. **The contents are not validated.**
      """,
      default: [],
      section: :encodings
    ],

    # Mark general properties
    tooltip: [
      type: {:custom, Tucan.Options, :tooltip, []},
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

    # Other
    clip: [
      type: :boolean,
      doc: """
      Whether a mark will be clipped to the enclosing group’s width and height.
      """,
      dest: :mark
    ],
    fill_opacity: [
      type: :float,
      default: 0.5,
      doc: """
      The fill opacity of the plotted elements.
      """,
      section: :style,
      dest: :mark
    ],
    opacity: [
      type: :float,
      doc: """
      The overall opacity of the mark
      """,
      section: :style,
      dest: :mark
    ],
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
    orient: [
      type: {:in, [:horizontal, :vertical]},
      doc: """
      The plot's orientation, can be either `:horizontal` or `:vertical`.
      """,
      default: :horizontal
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
      type: :float,
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
  # TODO remove this clause
  @spec docs(keyword()) :: binary()
  def docs(opts) when is_list(opts) do
    opts
    |> Enum.group_by(fn {_key, opts} -> Keyword.get(opts, :section, :unknown) end)
    |> Enum.sort_by(fn {section, _opts} -> section_order(section) end)
    |> Enum.map_join("\n\n", fn {section, opts} -> section_opts_docs(section, opts) end)
  end

  defp section_order(section) do
    @sections
    |> Keyword.fetch!(section)
    |> Keyword.fetch!(:order)
  end

  defp section_opts_docs(section, opts) do
    section_settings = Keyword.fetch!(@sections, section)

    [
      section_header(section, section_settings),
      Keyword.get(section_settings, :doc, nil),
      section_nimble_options_docs(%NimbleOptions{schema: opts})
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
  end

  ## Custom validations

  @doc false
  @spec tooltip(value :: term()) :: {:ok, boolean()} | {:error, binary()}
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
          "expected :tooltip to be boolean, :encoding or :data, got: #{inspect(value)}"
        }
    end
  end

  @doc false
  @spec extent(value :: term()) :: {:ok, [number()]} | {:error, binary()}
  def extent(value) do
    case value do
      [min, max] when is_number(min) and is_number(max) and min < max ->
        {:ok, [min, max]}

      other ->
        {:error,
         "expected :tooltip to be an array of the form [min, max], got: #{inspect(other)}"}
    end
  end

  @doc false
  @spec density_alias(value :: term()) :: {:ok, [binary()]} | {:error, binary()}
  def density_alias(alias) do
    if is_binary(alias) do
      {:ok, ["#{alias}_value", "#{alias}_density"]}
    else
      {:error, "expected :alias to be a string, got: #{inspect(alias)}"}
    end
  end
end
