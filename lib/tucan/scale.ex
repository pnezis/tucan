defmodule Tucan.Scale.Utils do
  @moduledoc false

  alias VegaLite, as: Vl

  @doc false
  @spec schemes_doc(schemes :: [atom()]) :: String.t()
  def schemes_doc(schemes) do
    """
    ```vega-lite
    #{schemes_to_vl(schemes)}
    ```
    """
  end

  defp schemes_to_vl(schemes) do
    plots =
      for scheme <- schemes do
        Vl.new(
          width: 300,
          title: [
            text: inspect(scheme),
            anchor: :end,
            font_weight: 700,
            font_size: 15,
            font: "Courier New",
            orient: :right,
            angle: 0,
            baseline: "line-bottom",
            offset: 3
          ]
        )
        |> Vl.data_from_values(x: 0..100)
        |> Vl.mark(:rect)
        |> Vl.encode_field(:x, "x", axis: nil)
        |> Vl.encode_field(:color, "x",
          legend: nil,
          scale: [scheme: scheme, extent: [0, 100]]
        )
      end

    Tucan.concat(plots, columns: 2)
    |> Vl.resolve(:scale, color: :independent)
    |> Vl.to_spec()
    |> Jason.encode!()
  end
end

defmodule Tucan.Scale do
  @moduledoc """
  Utilities for working with Vega-Lite scales.

  Scales are functions that transform a domain of data values (numbers, dates, strings, etc.)
  to a range of visual values (pixels, colors, sizes).

  This module exposes various helper functions for setting various scale options like
  the color scheme, the domain or the scale type.
  """

  alias Tucan.Utils

  @type color_scheme :: atom() | [String.t()]

  @categorical_schemes [
    :accent,
    :category10,
    :category20,
    :category20b,
    :category20c,
    :dark2,
    :paired,
    :pastel1,
    :pastel2,
    :set1,
    :set2,
    :set3,
    :tableau10,
    :tableau20
  ]

  @sequential_single_hue_schemes [
    :blues,
    :tealblues,
    :teals,
    :greens,
    :browns,
    :oranges,
    :reds,
    :purples,
    :warmgreys,
    :greys
  ]

  @sequential_multi_hue_schemes [
    :viridis,
    :magma,
    :inferno,
    :plasma,
    :cividis,
    :turbo,
    :bluegreen,
    :bluepurple,
    :goldgreen,
    :goldorange,
    :goldred,
    :greenblue,
    :orangered,
    :purplebluegreen,
    :purpleblue,
    :purplered,
    :redpurple,
    :yellowgreenblue,
    :yellowgreen,
    :yelloworangebrown,
    :yelloworangered
  ]

  @dark_schemes [:darkblue, :darkgold, :darkgreen, :darkmulti, :darkred]
  @light_schemes [:lightgreyred, :lightgreyteal, :lightmulti, :lightorange, :lighttealblue]

  @diverging_schemes [
    :blueorange,
    :brownbluegreen,
    :purplegreen,
    :pinkyellowgreen,
    :purpleorange,
    :redblue,
    :redgrey,
    :redyellowblue,
    :redyellowgreen,
    :spectral
  ]

  @cyclical_schemes [:rainbow, :sinebow]

  @valid_schemes List.flatten([
                   @categorical_schemes,
                   @sequential_single_hue_schemes,
                   @sequential_multi_hue_schemes,
                   @dark_schemes,
                   @light_schemes,
                   @diverging_schemes,
                   @cyclical_schemes
                 ])

  scheme_opts = [
    reverse: [
      type: :boolean,
      default: false,
      doc: "If set to `true` the selected scheme is reversed. Ignored if a range is set."
    ]
  ]

  @scheme_schema NimbleOptions.new!(scheme_opts)

  @doc """
  Sets the color scheme.

  You can either set one of the predefined schemes, or an array of colors which will
  be used as the color range.

  The input plot must be a single view with a color encoding defined.

  ## Options

  #{NimbleOptions.docs(@scheme_schema)}

  ## Supported color schemes

  All [vega supported schemes](https://vega.github.io/vega/docs/schemes/) are supported
  by `Tucan`.

  ### Categorical Schemes

  Categorical color schemes can be used to encode discrete data values, each representing
  a distinct category.

  #{Tucan.Scale.Utils.schemes_doc(@categorical_schemes)}

  ### Sequential Single-Hue Schemes

  Sequential color schemes can be used to encode quantitative values. These
  color ramps are designed to encode increasing numeric values.

  #{Tucan.Scale.Utils.schemes_doc(@sequential_single_hue_schemes)}

  ### Sequential Multi-Hue Schemes

  Sequential color schemes can be used to encode quantitative values. These color
  ramps are designed to encode increasing numeric values, but use additional
  hues for more color discrimination, which may be useful for visualizations
  such as heatmaps.

  #{Tucan.Scale.Utils.schemes_doc(@sequential_multi_hue_schemes)}

  ### Schemes for Dark Backgrounds

  #{Tucan.Scale.Utils.schemes_doc(@dark_schemes)}

  ### Schemes for Light Backgrounds

  #{Tucan.Scale.Utils.schemes_doc(@light_schemes)}

  ### Diverging Schemes

  Diverging color schemes can be used to encode quantitative values with a meaningful
  mid-point, such as zero or the average value. Color ramps with different hues
  diverge with increasing saturation to highlight the values below and above the
  mid-point.

  #{Tucan.Scale.Utils.schemes_doc(@diverging_schemes)}

  ### Cyclical Schemes

  Cyclical color schemes may be used to highlight periodic patterns in continuous
  data. However, these schemes are not well suited to accurately convey value
  differences.

  #{Tucan.Scale.Utils.schemes_doc(@cyclical_schemes)}

  ## Examples

  Setting a specific color range

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length", color_by: "species")
  |> Tucan.Scale.set_color_scheme(["yellow", "black", "#f234c1"])
  ```

  You can set any of the predefined color schemes to any plot with a color
  encoding.

  ```tucan
  Tucan.scatter(:weather, "date", "temp_max",
    x: [time_unit: :monthdate],
    y: [aggregate: :mean],
    color_by: "temp_max",
    color: [aggregate: :mean, type: :quantitative],
    width: 400
  )
  |> Tucan.Scale.set_color_scheme(:redyellowblue)

  ```

  You can reverse it by setting the `:reverse` option:

  ```tucan
  Tucan.scatter(:weather, "date", "temp_max",
    x: [time_unit: :monthdate],
    y: [aggregate: :mean],
    color_by: "temp_max",
    color: [aggregate: :mean, type: :quantitative],
    width: 400
  )
  |> Tucan.Scale.set_color_scheme(:redyellowblue, reverse: true)

  ```
  """
  @spec set_color_scheme(vl :: VegaLite.t(), scheme :: color_scheme(), opts :: keyword()) ::
          VegaLite.t()
  def set_color_scheme(vl, scheme, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @scheme_schema)
    set_color_scheme_or_range(vl, scheme, opts)
  end

  defp set_color_scheme_or_range(vl, scheme, opts) when is_atom(scheme) do
    if scheme not in @valid_schemes do
      raise ArgumentError,
            "invalid scheme #{inspect(scheme)}, check the Tucan.Scale docs for supported color schemes"
    end

    put_options(vl, :color, scheme: scheme, reverse: opts[:reverse])
  end

  defp set_color_scheme_or_range(vl, range, _opts) when is_list(range) do
    put_options(vl, :color, range: range)
  end

  @continuous_scales [:linear, :pow, :sqrt, :symlog, :log]
  @time_scales [:time, :utc]

  @valid_scales List.flatten([@continuous_scales, @time_scales])

  @doc """
  Sets the x axis scale.

  ## Options

  See `set_scale/4`.
  """
  @spec set_x_scale(vl :: VegaLite.t(), scale :: atom(), opts :: keyword()) :: VegaLite.t()
  def set_x_scale(vl, scale, opts \\ []) when is_struct(vl, VegaLite) and is_atom(scale) do
    set_scale(vl, :x, scale, opts)
  end

  @doc """
  Sets the y axis scale.

  ## Options

  See `set_scale/4`.
  """
  @spec set_y_scale(vl :: VegaLite.t(), scale :: atom(), opts :: keyword()) :: VegaLite.t()
  def set_y_scale(vl, scale, opts \\ []) when is_struct(vl, VegaLite) and is_atom(scale) do
    set_scale(vl, :y, scale, opts)
  end

  @doc """
  Sets the scale for the given encoding channel.

  Notice that only continuous scales are supported.

  See also `set_x_scale/3` and `set_y_scale/3` wrappers for setting the scale
  directly on *x* and *y* axes.

  > #### Continuous Scales {: .neutral}
  >
  > Continuous scales map a continuous domain (numbers or dates) to a continuous
  > output range (pixel locations, sizes, colors). Supported continuous scale
  > types for quantitative fields are `:linear`, `:log`, `:pow`, `:sqrt`, and
  > `:symlog`.
  >
  > Meanwhile, supported continuous scale types for temporal fields are `:time`,
  > `:utc`, and `:symlog`.
  >
  > By default, `:linear` scales are used for quantitative fields and `:time`
  > scales are used for temporal fields for all encoding channels.

  ## Options

  The supported options depend on the selected scale.

  ### `:pow` scale

  * `:exponent` (`t:number/0`) - The exponent to be used, applicable only for `:pow`
  scale.

  ### `:log` scale

  * `:base` (`t:number/0`) - The logarithm base of the `:log` scale. If not set defaults
  to 10.

  ### `:symlog` scale

  * `:constant` (`t:number/0`) - A constant determining the slope of the symlog
  function around zero. If not set defaults to 1.

  ## Examples

  Applying log scale on *x-axis*.

  ```tucan
  Tucan.scatter(:gapminder, "income", "health", width: 400)
  |> Tucan.Scale.set_scale(:x, :log)
  ```

  Applying pow scale on *x-axis* with arbitrary exponent.

  ```tucan
  Tucan.scatter(:gapminder, "income", "health", width: 400)
  |> Tucan.Scale.set_scale(:x, :pow, exponent: 0.2)
  ```
  """
  @spec set_scale(vl :: VegaLite.t(), channel :: atom(), scale :: atom(), opts :: keyword()) ::
          VegaLite.t()
  def set_scale(vl, channel, scale, opts \\ []) do
    unless scale in @valid_scales do
      raise ArgumentError,
            "scale can be one of #{inspect(@valid_scales)}, got: #{inspect(scale)}"
    end

    opts = validate_scale_options!(scale, opts)

    channel_type =
      vl
      |> Utils.encoding_options!(channel)
      |> Map.get("type")
      |> String.to_atom()

    cond do
      channel_type not in [:quantitative, :temporal] ->
        raise ArgumentError,
              "a scale can be applied only on a quantitative or temporal encoding " <>
                ", #{inspect(channel)} is defined as #{inspect(channel_type)}"

      channel_type == :temporal and scale not in @time_scales ->
        raise ArgumentError,
              "#{inspect(scale)} cannot be applied on a temporal encoding, " <>
                "valid scales: #{inspect(@time_scales)}"

      channel_type == :quantitative and scale not in @continuous_scales ->
        raise ArgumentError,
              "#{inspect(scale)} cannot be applied on a quantitative encoding, " <>
                "valid scales: #{inspect(@continuous_scales)}"

      true ->
        put_options(vl, channel, Keyword.merge(opts, type: scale))
    end
  end

  defp validate_scale_options!(:pow, opts), do: Keyword.validate!(opts, [:exponent])
  defp validate_scale_options!(:log, opts), do: Keyword.validate!(opts, [:base])
  defp validate_scale_options!(:symlog, opts), do: Keyword.validate!(opts, [:constant])
  defp validate_scale_options!(_type, opts), do: Keyword.validate!(opts, [])

  @doc """
  Sets the same `[x, y]` domain for _x-axis_ and _y-axis_ at once.
  """
  @spec set_xy_domain(vl :: VegaLite.t(), min :: number(), max :: number()) :: VegaLite.t()
  def set_xy_domain(vl, min, max) do
    vl
    |> set_x_domain(min, max)
    |> set_y_domain(min, max)
  end

  @doc """
  Sets the _x-axis_ domain.

  This is a helper wrapper around `set_domain/3` for setting the domain of continuous
  scales.
  """
  @spec set_x_domain(vl :: VegaLite.t(), min :: number(), max :: number()) :: VegaLite.t()
  def set_x_domain(vl, min, max), do: set_continuous_domain(vl, :x, min, max)

  @doc """
  Sets the _y-axis_ domain.

  This is a helper wrapper around `set_domain/3` for setting the domain of continuous
  scales.
  """
  @spec set_y_domain(vl :: VegaLite.t(), min :: number(), max :: number()) :: VegaLite.t()
  def set_y_domain(vl, min, max), do: set_continuous_domain(vl, :y, min, max)

  defp set_continuous_domain(vl, axis, min, max)
       when is_struct(vl, VegaLite) and is_number(min) and is_number(max) do
    if min >= max do
      raise ArgumentError,
            "a domain min value cannot be greater than the max value, got [#{min}, #{max}]"
    end

    set_domain(vl, axis, [min, max])
  end

  @doc """
  Sets the domain for the given encoding channel.

  `domain` can be anything Vega-Lite supports and the validity of it depends on the type
  of the encoding's data.

  Notice that no validation is performed.
  """
  # TODO: support domain validation
  @spec set_domain(vl :: VegaLite.t(), channel :: atom(), domain :: term()) :: VegaLite.t()
  def set_domain(vl, channel, domain) do
    put_options(vl, channel, domain: domain)
  end

  @doc """
  Sets an arbitrary set of options to the given `encoding`'s scale object.

  Notice that no validation is performed, any option set will be merged with
  the existing `scale` options of the given `encoding`.

  An `ArgumentError` is raised if the given encoding channel is not defined.
  """
  @spec put_options(vl :: VegaLite.t(), encoding :: atom(), options :: keyword()) ::
          VegaLite.t()
  def put_options(vl, encoding, options) do
    Utils.put_encoding_options(vl, encoding, scale: options)
  end
end
