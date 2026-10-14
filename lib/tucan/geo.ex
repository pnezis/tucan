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

  ```tucan
  Tucan.layers([
    Tucan.Geo.basemap(:us_10m),
    Tucan.Geo.scatter(:airports, "longitude", "latitude", point_size: 4, point_color: "firebrick")
  ])
  ```
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
      Defaults to `:albers_usa` for the `:us_10m` and `:airports` datasets and to
      `:equal_earth` otherwise.
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
  @us_datasets [:us_10m, :airports]

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

  choropleth_opts = [
    feature_key: [
      type: :string,
      default: "id",
      doc: """
      The field of the geographic features that is matched with the `key` field of the
      data, e.g. `"properties.name"`. TopoJSON features usually have an `"id"`.
      """
    ],
    fields: [
      type: {:list, :string},
      default: [],
      doc: """
      Additional fields of the data that are joined to the features, e.g. to be shown
      in the tooltip.
      """
    ],
    color_scheme: [
      type: :atom,
      doc: "The color scheme to use, for supported color schemes check `Tucan.Scale`.",
      section: :style
    ],
    missing_color: [
      type: :string,
      default: "#e3e3e3",
      doc: "The fill color of the features without a value.",
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
      default: 0.3,
      doc: "The width of the borders in pixels.",
      section: :style
    ]
  ]

  @choropleth_opts Tucan.Options.take!(
                     [:tooltip],
                     choropleth_opts ++ @feature_opts ++ @projection_opts
                   )
  @choropleth_schema Tucan.Options.to_nimble_schema!(@choropleth_opts)

  @doc """
  Draws a choropleth map.

  A choropleth map colors each geographic feature, e.g. the states of a country, by a
  value. The features of `geodata` are matched with the rows of `data`, by their
  `:feature_key` and the `key` field of the data, and colored by the `value` field.
  Features without a matching row, or without a valid value, are drawn with the
  `:missing_color`.

  `geodata` is a dataset or the URL of a GeoJSON or TopoJSON file, see the module
  documentation for details, and `data` any data supported by `Tucan.new/2`.

  ## Options

  #{Tucan.Options.docs(@choropleth_opts)}

  ## Examples

  The unemployment rate of the US counties:

  ```tucan
  Tucan.Geo.choropleth(:us_10m, :us_county_unemployment, "id", "rate",
    feature: "counties",
    color_scheme: :reds
  )
  ```

  The population of the US states, with a tooltip:

  ```tucan
  Tucan.Geo.choropleth(:us_10m, :us_state_population, "id", "population",
    fields: ["state"],
    color_scheme: :blues,
    tooltip: true
  )
  ```

  With inline data, where the states without a value are drawn in gray. The states
  are identified by their FIPS codes, e.g. `6` for California:

  ```tucan
  data = [
    %{fips: 6, score: 9},
    %{fips: 53, score: 7},
    %{fips: 41, score: 6},
    %{fips: 32, score: 4},
    %{fips: 8, score: 5},
    %{fips: 36, score: 3},
    %{fips: 12, score: 2},
    %{fips: 48, score: 1}
  ]

  Tucan.Geo.choropleth(:us_10m, data, "fips", "score", color_scheme: :greens)
  ```
  """
  @spec choropleth(
          geodata :: atom() | String.t(),
          data :: Tucan.plotdata(),
          key :: String.t(),
          value :: String.t(),
          opts :: keyword()
        ) :: VegaLite.t()
  def choropleth(geodata, data, key, value, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @choropleth_schema)

    mark_opts =
      [stroke: opts[:line_color], stroke_width: opts[:stroke_width]]
      |> Tucan.Keyword.put_not_nil(:tooltip, opts[:tooltip])

    # the data spec of the lookup, e.g. the url or the inline values
    lookup_data = Tucan.new(data).spec["data"]
    fields = [value | opts[:fields]]

    # all features are drawn with the missing color, and the features with a value are
    # drawn on top of them, since features without a value are filtered out
    missing_layer =
      Vl.new()
      |> geo_data(geodata, opts)
      |> Vl.mark(:geoshape, Keyword.put(mark_opts, :fill, opts[:missing_color]))

    values_layer =
      Vl.new()
      |> geo_data(geodata, opts)
      |> Vl.transform(
        lookup: opts[:feature_key],
        from: [data: lookup_data, key: key, fields: fields]
      )
      |> Vl.mark(:geoshape, mark_opts)
      |> Vl.encode_field(:color, value, type: :quantitative)
      |> maybe_set_color_scheme(opts[:color_scheme])
      |> maybe_tooltip(opts[:tooltip], Enum.map(fields, &[field: &1]))

    layered_geo_view([missing_layer, values_layer], geodata, opts)
  end

  defp maybe_tooltip(vl, true, fields), do: Vl.encode(vl, :tooltip, fields)
  defp maybe_tooltip(vl, _tooltip, _fields), do: vl

  defp maybe_set_color_scheme(vl, nil), do: vl
  defp maybe_set_color_scheme(vl, scheme), do: Tucan.Scale.set_color_scheme(vl, scheme)

  @scatter_opts Tucan.Options.take!(
                  [
                    :color_by,
                    :size_by,
                    :point_color,
                    :point_size,
                    :point_shape,
                    :filled,
                    :fill_opacity,
                    :tooltip
                  ],
                  [filled: [default: true], fill_opacity: [default: 0.7]] ++ @projection_opts
                )
  @scatter_schema Tucan.Options.to_nimble_schema!(@scatter_opts)

  @doc """
  Draws points at geographic locations.

  `longitude` and `latitude` are the fields with the coordinates of each point in
  degrees. The points can be colored and sized by data fields, e.g. for a bubble map.

  The points are drawn without a map, combine them with a `basemap/2` using
  `Tucan.layers/1`, see the module documentation.

  > #### Points outside the projection {: .warning}
  >
  > Points that the projection cannot place are drawn at the top left corner of the
  > plot, e.g. the airports of Guam with the `:albers_usa` projection, which covers
  > only the 50 states. Filter them out of the data if needed.

  ## Options

  #{Tucan.Options.docs(@scatter_opts)}

  ## Examples

  The airports of the United States:

  ```tucan
  Tucan.Geo.scatter(:airports, "longitude", "latitude", point_size: 4)
  ```

  A bubble map of some of the largest cities of the world, sized by their approximate
  metropolitan population in millions, on top of a world map:

  ```tucan
  cities = [
    %{city: "Tokyo", lon: 139.69, lat: 35.69, population: 37.4, continent: "Asia"},
    %{city: "Delhi", lon: 77.21, lat: 28.61, population: 31.0, continent: "Asia"},
    %{city: "Shanghai", lon: 121.47, lat: 31.23, population: 27.1, continent: "Asia"},
    %{city: "São Paulo", lon: -46.63, lat: -23.55, population: 22.0, continent: "South America"},
    %{city: "Mexico City", lon: -99.13, lat: 19.43, population: 21.8, continent: "North America"},
    %{city: "Cairo", lon: 31.24, lat: 30.04, population: 21.3, continent: "Africa"},
    %{city: "Mumbai", lon: 72.88, lat: 19.08, population: 20.7, continent: "Asia"},
    %{city: "New York", lon: -74.01, lat: 40.71, population: 18.8, continent: "North America"},
    %{city: "Lagos", lon: 3.38, lat: 6.52, population: 14.9, continent: "Africa"},
    %{city: "Moscow", lon: 37.62, lat: 55.76, population: 12.6, continent: "Europe"},
    %{city: "Paris", lon: 2.35, lat: 48.86, population: 11.1, continent: "Europe"},
    %{city: "Sydney", lon: 151.21, lat: -33.87, population: 5.0, continent: "Oceania"}
  ]

  Tucan.layers([
    Tucan.Geo.basemap(:world_110m),
    Tucan.Geo.scatter(cities, "lon", "lat",
      size_by: "population",
      color_by: "continent",
      tooltip: true
    )
  ])
  ```
  """
  @spec scatter(
          plotdata :: Tucan.plotdata(),
          longitude :: String.t(),
          latitude :: String.t(),
          opts :: keyword()
        ) :: VegaLite.t()
  def scatter(plotdata, longitude, latitude, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @scatter_schema)

    mark_opts =
      opts
      |> Tucan.Options.take_options(@scatter_opts, :mark)
      |> Tucan.Keyword.put_not_nil(:color, opts[:point_color])
      |> Tucan.Keyword.put_not_nil(:size, opts[:point_size])
      |> Tucan.Keyword.put_not_nil(:shape, opts[:point_shape])

    plotdata
    |> Tucan.new()
    |> Vl.mark(:point, mark_opts)
    |> encode_coordinates(longitude, latitude)
    |> maybe_encode(:color, opts[:color_by], type: :nominal)
    |> maybe_encode(:size, opts[:size_by], type: :quantitative)
    |> geo_view(plotdata, opts)
  end

  defp encode_coordinates(vl, longitude, latitude) do
    vl
    |> Vl.encode_field(:longitude, longitude, type: :quantitative)
    |> Vl.encode_field(:latitude, latitude, type: :quantitative)
  end

  defp maybe_encode(vl, _channel, nil, _opts), do: vl
  defp maybe_encode(vl, channel, field, opts), do: Vl.encode_field(vl, channel, field, opts)

  connections_opts = [
    stroke_width: [
      type: {:or, [:integer, :float]},
      default: 1,
      doc: "The width of the lines in pixels. Ignored if `:size_by` is set."
    ],
    opacity: [default: 0.6]
  ]

  @connections_opts Tucan.Options.take!(
                      [:color_by, :size_by, :line_color, :stroke_width, :opacity, :tooltip],
                      connections_opts ++ @projection_opts
                    )
  @connections_schema Tucan.Options.to_nimble_schema!(@connections_opts)

  @doc """
  Draws lines between pairs of geographic locations, e.g. flight routes.

  `longitude` and `latitude` are the fields with the coordinates of the start of
  each line, and `longitude2` and `latitude2` the fields with the coordinates of its
  end.

  The lines are straight lines on the projected map, and not great circles.

  The lines are drawn without a map, combine them with a `basemap/2` using
  `Tucan.layers/1`, see the module documentation.

  ## Options

  #{Tucan.Options.docs(@connections_opts)}

  ## Examples

  Flights from London to some cities of the world, with made up weekly frequencies:

  ```tucan
  london = %{lon: -0.45, lat: 51.47}

  routes =
    for {city, lon, lat, weekly} <- [
          {"New York", -73.78, 40.64, 140},
          {"Dubai", 55.36, 25.25, 90},
          {"Singapore", 103.99, 1.36, 35},
          {"Johannesburg", 28.24, -26.13, 21},
          {"São Paulo", -46.47, -23.43, 14},
          {"Tokyo", 139.78, 35.55, 28},
          {"Los Angeles", -118.41, 33.94, 50}
        ] do
      %{city: city, lon: london.lon, lat: london.lat, lon2: lon, lat2: lat, weekly: weekly}
    end

  Tucan.layers([
    Tucan.Geo.basemap(:world_110m),
    Tucan.Geo.connections(routes, "lon", "lat", "lon2", "lat2",
      size_by: "weekly",
      line_color: "firebrick",
      tooltip: true
    )
  ])
  ```

  The flights from Seattle to other US airports. The coordinates of the airports are
  joined to the flights with lookup transforms:

  ```tucan
  airports = Tucan.Datasets.dataset(:airports)

  lookup = fn vl, field, as ->
    VegaLite.transform(vl,
      lookup: field,
      from: [data: [url: airports], key: "iata", fields: ["longitude", "latitude"]],
      as: as
    )
  end

  flights =
    Tucan.new(:flights_airport)
    |> VegaLite.transform(filter: "datum.origin == 'SEA'")
    |> lookup.("origin", ["origin_lon", "origin_lat"])
    |> lookup.("destination", ["dest_lon", "dest_lat"])
    |> Tucan.Geo.connections("origin_lon", "origin_lat", "dest_lon", "dest_lat",
      projection: :albers_usa,
      size_by: "count",
      line_color: "steelblue"
    )

  Tucan.layers([Tucan.Geo.basemap(:us_10m), flights])
  ```
  """
  @spec connections(
          plotdata :: Tucan.plotdata(),
          longitude :: String.t(),
          latitude :: String.t(),
          longitude2 :: String.t(),
          latitude2 :: String.t(),
          opts :: keyword()
        ) :: VegaLite.t()
  def connections(plotdata, longitude, latitude, longitude2, latitude2, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @connections_schema)

    mark_opts =
      opts
      |> Tucan.Options.take_options(@connections_opts, :mark)
      |> Tucan.Keyword.put_not_nil(:color, opts[:line_color])

    plotdata
    |> Tucan.new()
    |> Vl.mark(:rule, mark_opts)
    |> encode_coordinates(longitude, latitude)
    |> Vl.encode_field(:longitude2, longitude2)
    |> Vl.encode_field(:latitude2, latitude2)
    |> maybe_encode(:color, opts[:color_by], type: :nominal)
    |> maybe_encode(:size, opts[:size_by], type: :quantitative)
    |> geo_view(plotdata, opts)
  end

  path_opts = [
    order_by: [
      type: :string,
      doc: """
      A field used for ordering the points of each path, e.g. a timestamp. If not set
      the points are connected in the order of the data.
      """
    ],
    group_by: [
      type: :string,
      doc: "A field used for drawing a separate path for each group.",
      section: :grouping
    ],
    points: [
      type: :boolean,
      default: false,
      doc: "Whether a point is drawn at each location.",
      section: :style
    ],
    color_by: [doc: "A field used for coloring the paths. A separate path is drawn per color."],
    stroke_width: [
      type: {:or, [:integer, :float]},
      default: 2,
      doc: "The width of the paths in pixels."
    ]
  ]

  @path_opts Tucan.Options.take!(
               [:color_by, :line_color, :stroke_width, :tooltip],
               path_opts ++ @projection_opts
             )
  @path_schema Tucan.Options.to_nimble_schema!(@path_opts)

  @doc """
  Draws paths connecting geographic locations, e.g. the track of a storm or the
  route of a trip.

  `longitude` and `latitude` are the fields with the coordinates of the points of
  each path.

  The paths are drawn without a map, combine them with a `basemap/2` using
  `Tucan.layers/1`, see the module documentation.

  ## Options

  #{Tucan.Options.docs(@path_opts)}

  ## Examples

  The (approximate) tracks of two Atlantic hurricanes:

  ```tucan
  tracks =
    for {storm, points} <- [
          {"Katrina",
           [{-75.1, 23.1}, {-77.6, 24.8}, {-80.1, 26.0}, {-82.6, 25.1}, {-85.3, 25.2},
            {-87.8, 26.2}, {-89.6, 28.2}, {-89.6, 30.8}, {-88.6, 34.0}, {-86.0, 37.0}]},
          {"Ike",
           [{-37.0, 17.2}, {-50.0, 21.0}, {-60.2, 22.8}, {-68.0, 21.4}, {-74.3, 21.1},
            {-79.0, 21.8}, {-84.6, 23.1}, {-89.4, 25.6}, {-94.7, 29.3}, {-93.0, 35.4}]}
        ],
        {{lon, lat}, step} <- Enum.with_index(points) do
      %{storm: storm, lon: lon, lat: lat, step: step}
    end

  projection = [projection: :mercator, projection_opts: [scale: 420, center: [-66, 27]]]

  Tucan.layers([
    Tucan.Geo.basemap(:world_110m, projection),
    Tucan.Geo.path(tracks, "lon", "lat", [order_by: "step", color_by: "storm", points: true] ++ projection)
  ])
  ```
  """
  @spec path(
          plotdata :: Tucan.plotdata(),
          longitude :: String.t(),
          latitude :: String.t(),
          opts :: keyword()
        ) :: VegaLite.t()
  def path(plotdata, longitude, latitude, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @path_schema)

    mark_opts =
      opts
      |> Keyword.take([:tooltip])
      |> Tucan.Keyword.put_not_nil(:color, opts[:line_color])

    encode = fn vl ->
      vl
      |> encode_coordinates(longitude, latitude)
      |> Tucan.Utils.maybe_encode_order(opts[:order_by])
      |> maybe_encode(:detail, opts[:group_by], type: :nominal)
      |> maybe_encode(:color, opts[:color_by], type: :nominal)
    end

    line =
      plotdata
      |> Tucan.new()
      |> Vl.mark(:line, Keyword.put(mark_opts, :stroke_width, opts[:stroke_width]))
      |> encode.()

    # the point overlay of line marks ignores the projection, so the points are drawn
    # in a separate layer
    points =
      plotdata
      |> Tucan.new()
      |> Vl.mark(:circle, Keyword.put(mark_opts, :opacity, 1))
      |> encode.()

    if opts[:points] do
      layered_geo_view([line, points], plotdata, opts)
    else
      geo_view(line, plotdata, opts)
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
