defmodule Tucan.Geo do
  @moduledoc """
  Geographic plots.

  All geographic plots project longitude and latitude coordinates on the plane with a
  cartographic projection, set by the `:projection` option. Common projections are
  `:equal_earth` or `:natural_earth1` for world maps, `:albers_usa` for the United
  States and `:mercator` for small areas. Additional projection properties, like the
  `:scale`, the `:center` or the `:rotate` angles, can be set through the
  `:projection_opts` option.

  ## Geographic data

  Maps are drawn from geographic features in GeoJSON or TopoJSON format:

  * A TopoJSON file contains named objects, e.g. the `states` and the `counties` of
  the `:us_10m` dataset. Set the `:feature` option to the name of the object to draw
  its features, or the `:mesh` option to draw only the borders between them.
  * A GeoJSON file is expected to contain a feature collection, if neither `:feature`
  nor `:mesh` are set.

  The `:us_10m` and `:world_110m` datasets default to their `states` and `countries`
  objects respectively.

  The geographic features are loaded from a dataset or a URL, inline geographic data
  are not supported.

  ## Combining maps

  All plots of this module are single views with their own projection, so they can be
  combined with `Tucan.layers/1`, e.g. to draw some points on top of a base map. Use
  the same projection for all layers.
  """

  alias VegaLite, as: Vl

  @projections [
    :albers,
    :albers_usa,
    :azimuthal_equal_area,
    :azimuthal_equidistant,
    :conic_conformal,
    :conic_equal_area,
    :conic_equidistant,
    :equal_earth,
    :equirectangular,
    :gnomonic,
    :mercator,
    :natural_earth1,
    :orthographic,
    :stereographic,
    :transverse_mercator
  ]

  @projection_opts [
    projection: [
      type: {:in, @projections},
      doc: """
      The cartographic projection. One of #{Enum.map_join(@projections, ", ", &"`#{inspect(&1)}`")}.
      Defaults to `:albers_usa` for the `:us_10m` dataset and to `:equal_earth` otherwise.
      """,
      section: :style
    ],
    projection_opts: [
      type: :keyword_list,
      default: [],
      doc: """
      Additional properties of the projection, e.g. `[scale: 300, center: [20, 50]]`.
      Check the [Vega-Lite docs](https://vega.github.io/vega-lite/docs/projection.html)
      for the supported properties.
      """,
      section: :style
    ],
    width: [
      type: :pos_integer,
      default: 500,
      doc: "The width of the plot in pixels.",
      section: :style
    ],
    height: [
      type: :pos_integer,
      default: 300,
      doc: "The height of the plot in pixels.",
      section: :style
    ],
    title: [
      type: :string,
      doc: "The title of the plot.",
      section: :style
    ]
  ]

  @feature_opts [
    feature: [
      type: :string,
      doc: """
      The name of the TopoJSON object whose features are drawn. Defaults to `"states"`
      for the `:us_10m` dataset and to `"countries"` for the `:world_110m` dataset.
      """
    ],
    mesh: [
      type: :string,
      doc: """
      The name of the TopoJSON object whose borders are drawn. Set it instead of
      `:feature` to draw only the borders between the features.
      """
    ]
  ]

  @default_features %{us_10m: "states", world_110m: "countries"}

  # datasets that default to the albers usa projection
  @us_datasets [:us_10m]

  basemap_opts = [
    fill_color: [
      type: :string,
      default: "#e3e3e3",
      doc: "The fill color of the features.",
      section: :style
    ],
    line_color: [
      type: :string,
      default: "white",
      doc: "The color of the borders of the features.",
      section: :style
    ],
    stroke_width: [
      type: {:or, [:integer, :float]},
      default: 0.5,
      doc: "The width of the borders in pixels.",
      section: :style
    ],
    graticule: [
      type: :boolean,
      default: false,
      doc: "Whether a graticule, the grid of meridians and parallels, is drawn.",
      section: :style
    ],
    sphere: [
      type: :boolean,
      default: false,
      doc: "Whether the outline of the globe is drawn, filled with the `:sphere_color`.",
      section: :style
    ],
    sphere_color: [
      type: :string,
      default: "#e8f1f8",
      doc: "The fill color of the sphere, if `:sphere` is set.",
      section: :style
    ]
  ]

  @basemap_opts Tucan.Options.take!(
                  [:tooltip],
                  basemap_opts ++ @feature_opts ++ @projection_opts
                )
  @basemap_schema Tucan.Options.to_nimble_schema!(@basemap_opts)

  @doc """
  Draws a base map of geographic features.

  `geodata` is a dataset, e.g. `:us_10m` or `:world_110m`, or the URL of a GeoJSON or
  TopoJSON file. See the module documentation for the supported formats.

  ## Options

  #{Tucan.Options.docs(@basemap_opts)}

  ## Examples

  The countries of the world, with the outline of the globe and a graticule:

  ```tucan
  Tucan.Geo.basemap(:world_110m, sphere: true, graticule: true)
  ```

  The states of the US:

  ```tucan
  Tucan.Geo.basemap(:us_10m, fill_color: "#dce9d5", line_color: "#7a9a6f")
  ```

  Only the borders between the counties of the US, with a mesh:

  ```tucan
  Tucan.Geo.basemap(:us_10m, mesh: "counties", line_color: "gray", stroke_width: 0.3)
  ```

  Europe, with an orthographic projection centered on it:

  ```tucan
  Tucan.Geo.basemap(:world_110m,
    projection: :orthographic,
    projection_opts: [rotate: [-15, -50, 0], scale: 500],
    sphere: true,
    graticule: true,
    width: 400,
    height: 400
  )
  ```
  """
  @spec basemap(geodata :: atom() | String.t(), opts :: keyword()) :: VegaLite.t()
  def basemap(geodata, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @basemap_schema)

    fill = if opts[:mesh], do: nil, else: opts[:fill_color]

    mark_opts =
      [stroke: opts[:line_color], stroke_width: opts[:stroke_width]]
      |> Keyword.put(:fill, fill)
      |> Tucan.Keyword.put_not_nil(:tooltip, opts[:tooltip])

    features =
      Vl.new()
      |> geo_data(geodata, opts)
      |> Vl.mark(:geoshape, mark_opts)

    sphere =
      Vl.new()
      |> Vl.data(sphere: true)
      |> Vl.mark(:geoshape, fill: opts[:sphere_color], stroke: "#cccccc", stroke_width: 0.5)

    graticule =
      Vl.new()
      |> Vl.data(graticule: [step: [15, 15]])
      |> Vl.mark(:geoshape, fill: nil, stroke: "#cccccc", stroke_width: 0.3)

    layers =
      if(opts[:sphere], do: [sphere], else: []) ++
        if(opts[:graticule], do: [graticule], else: []) ++ [features]

    case layers do
      [single] -> geo_view(single, geodata, opts)
      layers -> layered_geo_view(layers, geodata, opts)
    end
  end

  ## Helpers

  # Sets the size, the title and the projection of a plot
  defp geo_view(vl, geodata, opts) do
    vl
    |> Tucan.Utils.put_in_spec(:width, opts[:width])
    |> Tucan.Utils.put_in_spec(:height, opts[:height])
    |> then(fn vl -> if opts[:title], do: Tucan.set_title(vl, opts[:title]), else: vl end)
    |> project(geodata, opts)
  end

  # Sets the size, the title and the projection of a layered plot. The projection is
  # also set to each layer, since `Tucan.layers/1` drops the top level projection of
  # layered plots when combining them.
  defp layered_geo_view(layers, geodata, opts) do
    layers = Enum.map(layers, &project(&1, geodata, opts))

    Vl.new()
    |> geo_view(geodata, opts)
    |> Vl.layers(layers)
  end

  defp project(vl, geodata, opts) do
    projection =
      opts[:projection] || if geodata in @us_datasets, do: :albers_usa, else: :equal_earth

    Vl.projection(vl, Keyword.merge([type: projection], opts[:projection_opts]))
  end

  # Sets the geographic data of a plot
  defp geo_data(vl, geodata, opts) do
    url = if is_atom(geodata), do: Tucan.Datasets.dataset(geodata), else: geodata
    feature = opts[:feature] || (is_atom(geodata) && @default_features[geodata]) || nil

    format =
      cond do
        opts[:mesh] -> [type: :topojson, mesh: opts[:mesh]]
        feature -> [type: :topojson, feature: feature]
        true -> [type: :json, property: "features"]
      end

    Vl.data_from_url(vl, url, format: format)
  end
end
