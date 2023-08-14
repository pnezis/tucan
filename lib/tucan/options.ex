defmodule Tucan.Options do
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
    |> Keyword.keys()
    |> Enum.concat(extra)
  end

  defp section_options(section) do
    Enum.filter(@options, fn {_key, opts} -> opts[:section] == section end)
  end

  @tucan_opts_fields [:section]

  @doc """
  Converts the given tucan options to nimble options
  """
  @spec to_nimble_options(options :: [atom()]) :: keyword()
  def to_nimble_options(options) do
    Keyword.take(@options, options)
    |> Enum.map(fn {key, opts} -> {key, Keyword.drop(opts, @tucan_opts_fields)} end)
  end

  @doc """
  Converts a list of options to a `NimbleOptions` schema.
  """
  @spec schema!(options :: [atom()]) :: NimbleOptions.t()
  def schema!(options) do
    options
    |> to_nimble_options()
    |> NimbleOptions.new!()
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
end
