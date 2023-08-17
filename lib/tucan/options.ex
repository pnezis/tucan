defmodule Tucan.Options do
  # TODO: cleanup sections ordering & descriptions
  @sections [
    unknown: [
      order: -1
    ],
    general_mark: [
      order: 7,
      header: "Interactivity Options"
    ],
    global: [
      order: 10,
      header: "Global Options"
    ],
    density_transform: [
      order: 5,
      header: "Density Options"
    ]
  ]
  @options [
    # Global opts
    width: [
      type: :integer,
      doc: "Width of the image",
      section: :global
    ],
    height: [
      type: :integer,
      doc: "Height of the image",
      section: :global
    ],
    title: [
      type: :string,
      doc: "The title of the graph",
      section: :global
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
      section: :general_mark
    ],

    # Density transform
    groupby: [
      type: {:list, :string},
      doc: """
      The data fields to group by. If not specified, a single group containing all data
      objects will be used. 
      """,
      section: :density_transform
    ],
    cumulative: [
      type: :boolean,
      doc: """
      A boolean flag indicating whether to produce density estimates (false) or cumulative
      density estimates (true).
      """,
      default: false,
      section: :density_transform
    ],
    counts: [
      type: :boolean,
      doc: """
      A boolean flag indicating if the output values should be probability estimates
      (false) or smoothed counts (true).
      """,
      default: false,
      section: :density_transform
    ],
    bandwidth: [
      type: :float,
      doc: """
      The bandwidth (standard deviation) of the Gaussian kernel. If unspecified or set to
      zero, the bandwidth value is automatically estimated from the input data using
      Scott’s rule.
      """,
      section: :density_transform
    ],
    extent: [
      type: {:custom, Tucan.Options, :extent, []},
      doc: """
      A [min, max] domain from which to sample the distribution. If unspecified, the extent
      will be determined by the observed minimum and maximum values of the density value field.
      """,
      section: :density_transform
    ],
    minsteps: [
      type: :integer,
      doc: """
      The minimum number of samples to take along the extent domain for plotting the density.
      """,
      default: 25,
      section: :density_transform
    ],
    maxsteps: [
      type: :integer,
      doc: """
      The maximum number of samples to take along the extent domain for plotting the density.
      """,
      default: 200,
      section: :density_transform
    ],
    steps: [
      type: :integer,
      doc: """
      The exact number of samples to take along the extent domain for plotting the density. If
      specified, overrides both minsteps and maxsteps to set an exact number of uniform samples.
      Potentially useful in conjunction with a fixed extent to ensure consistent sample points
      for stacked densities.
      """,
      section: :density_transform
    ],
    alias: [
      type: {:custom, Tucan.Options, :density_alias, []},
      doc: """
      An alias for the sample value and corresponding density estimate. If not set it will
      correspond to `value`, `density`. If set the output fields will be named `{alias}_value`
      and `{alias}_density`.
      """,
      section: :density_transform
    ],

    # Uncategorized
    fill_opacity: [
      type: :float,
      default: 0.5,
      doc: """
      The fill opacity of the histogram bars.
      """
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
      If set a column that will be used for coloring the data.
      """
    ],
    orient: [
      type: {:in, [:horizontal, :vertical]},
      doc: """
      The plot's orientation, can be either `:horizontal` or `:vertical`.
      """,
      default: :horizontal
    ]
  ]

  @doc """
  Extracts the options keys of the given `sections` adding any `extra` option added.

  `Tucan` options are defined globally, and mostly follow the VegaLite options with some
  exceptions. They are splitted in various sections based on their type. This helper
  function takes as input a set of sections and an optional array of extra options and
  returns a list of valid options.

  This is mainly used for options definition for a specific plot. Since most options are
  shared this is a convenience function.

      @plot_options Tucan.Options.filter_options([:global, :general_mark, :rect], [:color_by])
      @plot_options_schema Tucan.Options.schema!(@plot_options)
    
  See also `to_nimble_options/1` and `schema!/1` in order to convert the returned
  list to a valid `NimbleOptions` schema.
  """
  @spec options(sections :: [atom()], extra :: [atom()]) :: [atom()]
  def options(sections, extra \\ []) do
    # TODO: validate that extra includes valid options

    Enum.map(sections, &section_options/1)
    |> List.flatten()
    |> Enum.concat(extra)
  end

  @doc """
  Get the options (keys) of the given `section`.

  Raises if no option exists for the given `section`.
  """
  @spec section_options(section :: atom()) :: [atom()]
  def section_options(section) do
    options =
      Enum.filter(@options, fn {_key, opts} -> opts[:section] == section end)
      |> Keyword.keys()

    if options == [] do
      raise ArgumentError, "no option defined for section: #{inspect(section)}"
    end

    options
  end

  @doc """
  Converts the given tucan options to nimble options
  """
  @spec to_nimble_options(options :: [atom()]) :: keyword()
  def to_nimble_options(options) do
    Keyword.take(@options, options)
    |> drop_tucan_opts_fields()
  end

  @tucan_opts_fields [:section]
  defp drop_tucan_opts_fields(opts) do
    Enum.map(opts, fn {key, opts} -> {key, Keyword.drop(opts, @tucan_opts_fields)} end)
  end

  @doc """
  Converts a list of options to a `NimbleOptions` schema.

  Additinally an extra schema definition can be provided, which will be merged
  with the schema defined by the selected options.
  """
  @spec schema!(options :: [atom()], extra :: keyword()) :: NimbleOptions.t()
  def schema!(options, extra \\ []) do
    extra = drop_tucan_opts_fields(extra)

    options
    |> to_nimble_options()
    |> Keyword.merge(extra)
    |> NimbleOptions.new!()
  end

  def docs(%NimbleOptions{schema: schema}) do
    schema
    |> Enum.group_by(fn {key, _opts} ->
      @options
      |> Keyword.get(key, [])
      |> Keyword.get(:section, :unknown)
    end)
    |> Enum.sort_by(fn {section, _opts} ->
      @sections
      |> Keyword.fetch!(section)
      |> Keyword.fetch!(:order)
    end)
    |> Enum.map(fn {section, opts} -> section_opts_docs(section, opts) end)
    |> Enum.join("\n\n")
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
  def density_alias(alias) do
    if is_binary(alias) do
      {:ok, ["#{alias}_value", "#{alias}_density"]}
    else
      {:error, "expected :alias to be a string, got: #{inspect(alias)}"}
    end
  end
end
