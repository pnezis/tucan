defmodule Tucan.Scale.Utils do
  @moduledoc false

  alias VegaLite, as: Vl

  @doc false
  @spec schemes_doc(schemes :: [atom()]) :: binary()
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

    Vl.new(columns: 2)
    |> Tucan.concat(plots)
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

  alias Tucan.VegaLiteUtils

  @type color_scheme :: atom() | [binary()]

  @type scale :: :linear | :log | :symlog | :pow | :sqrt

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
  |> Tucan.Scale.set_scheme(["yellow", "black", "#f234c1"])
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
  |> Tucan.Scale.set_scheme(:redyellowblue)

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
  |> Tucan.Scale.set_scheme(:redyellowblue, reverse: true)

  ```
  """
  @spec set_scheme(vl :: VegaLite.t(), scheme :: color_scheme(), opts :: keyword()) ::
          VegaLite.t()
  def set_scheme(vl, scheme, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @scheme_schema)
    set_scheme_or_range(vl, scheme, opts)
  end

  defp set_scheme_or_range(vl, scheme, opts) when is_atom(scheme) do
    if scheme not in @valid_schemes do
      raise ArgumentError,
            "invalid scheme #{inspect(scheme)}, check the Tucan.Scale docs for supported color schemes"
    end

    Tucan.VegaLiteUtils.put_encoding_options(vl, :color,
      scale: [scheme: scheme, reverse: opts[:reverse]]
    )
  end

  defp set_scheme_or_range(vl, range, _opts) when is_list(range) do
    Tucan.VegaLiteUtils.put_encoding_options(vl, :color, scale: [range: range])
  end

  @doc """
  Sets the x axis scale.
  """
  # TODO validate the scale based on the encoding type
  @spec set_x_scale(vl :: VegaLite.t(), scale :: scale()) :: VegaLite.t()
  def set_x_scale(vl, scale) when is_struct(vl, VegaLite) and is_atom(scale) do
    VegaLiteUtils.put_encoding_options(vl, :x, scale: [type: scale])
  end

  @doc """
  Sets the y axis scale.
  """
  @spec set_y_scale(vl :: VegaLite.t(), scale :: scale()) :: VegaLite.t()
  def set_y_scale(vl, scale) when is_struct(vl, VegaLite) and is_atom(scale) do
    VegaLiteUtils.put_encoding_options(vl, :y, scale: [type: scale])
  end

  @doc """
  Sets the x axis domain.
  """
  @spec set_x_domain(vl :: VegaLite.t(), min :: number(), max :: number()) :: VegaLite.t()
  def set_x_domain(vl, min, max), do: set_domain(vl, :x, min, max)

  @doc """
  Sets the y axis domain.
  """
  @spec set_y_domain(vl :: VegaLite.t(), min :: number(), max :: number()) :: VegaLite.t()
  def set_y_domain(vl, min, max), do: set_domain(vl, :y, min, max)

  defp set_domain(vl, axis, min, max)
       when is_struct(vl, VegaLite) and is_number(min) and is_number(max) do
    if min >= max do
      raise ArgumentError,
            "a domain min value cannot be greater than the max value, got [#{min}, #{max}]"
    end

    VegaLiteUtils.put_encoding_options(vl, axis, scale: [domain: [min, max]])
  end
end
