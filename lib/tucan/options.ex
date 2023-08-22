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
    ]
  ]

  options = [
    # Global opts
    width: [
      type: :integer,
      doc: "Width of the image",
      section: :global,
      dest: :spec
    ],
    height: [
      type: :integer,
      doc: "Height of the image",
      section: :global,
      dest: :spec
    ],
    title: [
      type: :string,
      doc: "The title of the graph",
      section: :global,
      dest: :spec
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
      section: :general_mark,
      dest: :mark
    ],

    # Uncategorized
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
      The fill opacity of the plotted elemets.
      """,
      dest: :mark
    ],
    opacity: [
      type: :float,
      doc: """
      The overall opacity of the mark
      """,
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
      """
    ],
    shape_by: [
      type: :string,
      doc: """
      If set a data field that will be used for setting the shape of the data points.
      It is considered `:nominal` by default.
      """
    ],
    size_by: [
      type: :string,
      doc: """
      If set a data field that will be used for controlling the size of the data points.
      It is considered `:quantitative` by default.
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

  @options options

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
  # TODO: to be removed and replaced with the `take` below
  @spec options(sections :: [atom()], extra :: [atom()]) :: [atom()]
  def options(sections, extra \\ []) do
    # TODO: validate that extra includes valid options

    Enum.map(sections, &section_options/1)
    |> List.flatten()
    |> Enum.concat(extra)
  end

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
    |> Keyword.merge(extra)
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

  def to_nimble_schema!(opts) do
    opts
    |> drop_tucan_opts_fields()
    |> NimbleOptions.new!()
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

  @tucan_opts_fields [:section, :dest]
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
