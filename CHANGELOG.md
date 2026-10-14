# Changelog

## [Unreleased]

### Added

- Add `:tick_color` and `:tick_width` options to `Tucan.errorbar/3` for styling the
error bar end ticks.

  ```tucan
  Tucan.errorbar(:barley, "yield", group_by: "variety", tick_color: "orange", tick_width: 3)
  ```

- `Tucan.Scale.set_domain/3` accepts a `{min, max}` tuple and `:unaggregate`.

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Scale.set_domain(:x, {0, 4})
  ```

- Support combining a `:density_heatmap` joint plot with `:color_by` in `Tucan.jointplot/4`.

  ```tucan
  Tucan.jointplot(
    :penguins, "Beak Length (mm)", "Beak Depth (mm)",
    joint: :density_heatmap,
    marginal: :density,
    color_by: "Species",
    marginal_opts: [fill_opacity: 0.5]
  )
  ```

- Support RGB and RGBA images in `Tucan.imshow/2`.

  ```tucan
  height = 60
  width = 120

  red = Nx.iota({height, width}, axis: 1) |> Nx.divide(width - 1)
  green = Nx.iota({height, width}, axis: 0) |> Nx.divide(height - 1)
  blue = Nx.broadcast(0.6, {height, width})

  image = Nx.stack([red, green, blue], axis: -1) |> Nx.as_type({:f, 32})

  Tucan.imshow(image, width: 240, height: 120)
  ```

- Add `Tucan.violin/3` for drawing violin plots, optionally grouped and colored by a
categorical field.

  ```tucan
  Tucan.violin(:penguins, "Body Mass (g)", group_by: "Species", color_by: "Species")
  ```

- Add `Tucan.radial/4` for radial plots, where both the angle and the radius of each
wedge are proportional to the value.

  ```tucan
  Tucan.radial(:barley, "yield", "site", aggregate: :sum, inner_radius: 30)
  ```

- Add experimental `Tucan.Polar` module for plots in polar coordinates, with
`Tucan.Polar.lineplot/4`, `Tucan.Polar.scatter/4`, `Tucan.Polar.area/4`,
`Tucan.Polar.radar/4`, `Tucan.Polar.bar/4`, `Tucan.Polar.histogram/3`,
`Tucan.Polar.windrose/4` and `Tucan.Polar.heatmap/5`. The polar grid is drawn in the data coordinates, and
the maximum radius is inferred from inline data. Angle marks can be labeled in
degrees, as compass points or with custom labels. Cyclic data, e.g. the days of
a year, are supported through the `:period` option.

  ```tucan
  theta = Enum.to_list(0..720//5)
  r = Enum.map(theta, &(&1 / 360))

  Tucan.Polar.lineplot([r: r, theta: theta], "r", "theta")
  ```

- Warn if a column with non-numeric values is encoded in a quantitative channel,
e.g. `Tucan.scatter(data, "category", "value")`, instead of silently rendering an
empty plot. Set the channel type explicitly to silence the warning.

- Support connected scatter plots in `Tucan.lineplot/4` through the `:order_by`
option, which orders the points of the lines by a field other than `x`.

  ```tucan
  data =
    for {year, unemployment, inflation} <- [
          {2019, 3.7, 1.8}, {2020, 8.1, 1.2}, {2021, 5.4, 4.7}, {2022, 3.6, 8.0}, {2023, 3.6, 4.1}
        ] do
      %{year: year, unemployment: unemployment, inflation: inflation}
    end

  Tucan.lineplot(data, "unemployment", "inflation", order_by: "year", points: true)
  ```

- Add `Tucan.Geometry.line/3` for drawing line segments.

  ```tucan
  data = for i <- 1..50, do: %{actual: i, predicted: i + 8 * :math.sin(i)}

  Tucan.layers([
    Tucan.scatter(data, "actual", "predicted"),
    Tucan.Geometry.line({0, 0}, {50, 50}, line_color: "gray", stroke_dash: [4, 4])
  ])
  ```

- Add `Tucan.Geometry.arrow/3` for drawing arrows, e.g. to point to a part of a plot.
The arrow head follows the direction of the arrow on the screen, even if the x and y
scales differ.

  ```tucan
  Tucan.scatter(:cars, "Horsepower", "Miles_per_Gallon")
  |> Tucan.Layers.append(Tucan.Geometry.arrow({180, 35}, {225, 16}, line_color: "red"))
  |> Tucan.annotate(180, 37, "The most powerful car", color: "red")
  ```

- Add `Tucan.Geometry.regular_polygon/4` for drawing regular polygons.

  ```tucan
  Tucan.Geometry.regular_polygon({0, 0}, 1, 6, fill_color: "teal")
  |> Tucan.set_size(200, 200)
  ```

- Add `Tucan.Geometry.function/3` for drawing the curves of functions. The curve is
broken where the function is not defined.

  ```tucan
  Tucan.layers([
    Tucan.Geometry.function(&:math.sin/1, {-2 * :math.pi(), 2 * :math.pi()}),
    Tucan.Geometry.function(&:math.sqrt(&1 * &1 - 4), {-6, 6}, line_color: "red")
  ])
  |> Tucan.set_width(400)
  ```

- Add the `:airports`, `:flights_airport`, `:us_10m`, `:us_county_unemployment`,
`:us_state_population` and `:world_110m` geographic datasets.

- Add `Tucan.Geo` module for geographic plots, starting with `Tucan.Geo.basemap/2` for
drawing maps of geographic features.

  ```tucan
  Tucan.Geo.basemap(:world_110m, sphere: true, graticule: true)
  ```

- Add `Tucan.Geo.choropleth/5` for coloring geographic features by a value. The
features are joined with the rows of any data supported by `Tucan.new/2`.

  ```tucan
  Tucan.Geo.choropleth(:us_10m, :us_county_unemployment, "id", "rate",
    feature: "counties",
    color_scheme: :reds
  )
  ```

- Add `Tucan.Geo.scatter/4` for drawing points at geographic locations, e.g. bubble
maps on top of a `Tucan.Geo.basemap/2`.

  ```tucan
  Tucan.layers([
    Tucan.Geo.basemap(:us_10m),
    Tucan.Geo.scatter(:airports, "longitude", "latitude", point_size: 4, point_color: "firebrick")
  ])
  ```

- Add `Tucan.Geo.connections/6` for drawing lines between pairs of geographic
locations, e.g. flight routes.

  ```tucan
  routes =
    for {lon, lat} <- [{-73.78, 40.64}, {55.36, 25.25}, {103.99, 1.36}, {28.24, -26.13}] do
      %{lon: -0.45, lat: 51.47, lon2: lon, lat2: lat}
    end

  Tucan.layers([
    Tucan.Geo.basemap(:world_110m),
    Tucan.Geo.connections(routes, "lon", "lat", "lon2", "lat2", line_color: "firebrick")
  ])
  ```

- Add `Tucan.Geo.path/4` for drawing paths connecting geographic locations, e.g. the
track of a storm or the route of a trip.

  ```tucan
  trip = [
    %{city: "Lisbon", lon: -9.14, lat: 38.72, day: 1},
    %{city: "Madrid", lon: -3.70, lat: 40.42, day: 3},
    %{city: "Paris", lon: 2.35, lat: 48.86, day: 6},
    %{city: "Berlin", lon: 13.40, lat: 52.52, day: 9},
    %{city: "Vienna", lon: 16.37, lat: 48.21, day: 12}
  ]

  projection = [projection: :mercator, projection_opts: [scale: 600, center: [4, 46]]]

  Tucan.layers([
    Tucan.Geo.basemap(:world_110m, projection),
    Tucan.Geo.path(trip, "lon", "lat", [order_by: "day", points: true] ++ projection)
  ])
  ```

- Add a `:volume` option to `Tucan.Finance.candlestick/7` for drawing the traded
volume as a bar chart below the prices, sharing their time axis.

  ```tucan
  :rand.seed(:exsss, {1, 2, 3})

  {data, _close} =
    Enum.map_reduce(Date.range(~D[2024-03-01], ~D[2024-04-30]), 100.0, fn date, previous ->
      close = previous + 2 * :rand.normal()
      high = max(previous, close) + abs(:rand.normal())
      low = min(previous, close) - abs(:rand.normal())
      volume = round(1_000_000 * (0.5 + :rand.uniform()))

      {%{date: date, open: previous, high: high, low: low, close: close, volume: volume}, close}
    end)

  Tucan.Finance.candlestick(data, "date", "open", "high", "low", "close",
    volume: "volume",
    width: 400
  )
  ```

### Changed

- `Tucan.Geometry.circle/3` and `Tucan.Geometry.ellipse/5` are sampled every degree
instead of every tenth of a degree. Each shape is drawn with 361 points instead of
3610, without a visible difference.
- `Tucan.pie/4` validates the `:aggregate` option. An unsupported statistic, e.g. `:avg`,
raises instead of silently producing a broken plot.
- `Tucan.Scale.set_domain/3` validates the domain and raises if it is not valid,
e.g. if a quantitative channel's domain contains non-numeric values.
- Numeric strings, e.g. `"1.5"`, are inferred as quantitative.
- `Tucan.density/3` accepts an integer `:bandwidth`, and requires `:steps`, `:minsteps`
and `:maxsteps` to be positive integers.

### Fixed

- `Tucan.annotate/5` does not change the axis titles of the annotated plot. The
annotation's internal `x` and `y` fields were appended to them, e.g. `Horsepower, x`.
- `Tucan.new/2` applies the spec options, e.g. `:width`, `:height` and `:title`, if the
data are an existing `VegaLite` plot, e.g. a dataset with some transforms. They were
ignored before, so the options of any plot built on such a plot were lost too.

  ```tucan
  VegaLite.new()
  |> VegaLite.data_from_url("https://vega.github.io/editor/data/cars.json")
  |> VegaLite.transform(filter: "datum.Origin == 'Europe'")
  |> Tucan.scatter("Horsepower", "Miles_per_Gallon", width: 400, title: "European cars")
  ```

- `Tucan.density/3` converts the density field to a number before estimating the
density. Previously densities of CSV data were computed on strings, producing
wrong plots, e.g. `Tucan.density(:iris, "petal_width", color_by: "species")`.

## [v0.6.0](https://github.com/pnezis/tucan/tree/v0.6.0) (2026-04-29)

### Added

- Support custom themes as keyword lists in `set_theme/2`
- Add `point_size` option to lineplot and area plots

## [v0.5.1](https://github.com/pnezis/tucan/tree/v0.5.1) (2025-10-24)

### Fixed

- Typing violation warnings in elixir 1.19

## [v0.5.0](https://github.com/pnezis/tucan/tree/v0.5.0) (2025-05-19)

### Added

- Automatic type inference for input data. By inferring types we can automatically set
the type to temporal in case of date, datetime columns.

  ```tucan
  data = [
      %{x: ~D[2020-01-01], y: 12.34},
      %{x: ~D[2020-01-02], y: 13.21},
      %{x: ~D[2020-01-03], y: 9.81}
    ]

  # x is marked as temporal instead of quantitative which is the default for line plots
  Tucan.lineplot(data, "x", "y")
  ```

- Infer time columns and apply the proper formatting on the data definition:

  ```tucan
  data = [
    %{x: ~T[10:00:00], y: 12.34},
    %{x: ~T[11:00:00], y: 13.21},
    %{x: ~T[12:00:00], y: 9.81}
  ]

  Tucan.lineplot(data, "x", "y", points: true)
  ```

- Add `Tucan.configure/1` for setting default width and height for subsequent plots.

  ```elixir
  Tucan.configure(default_width: 600, default_height: 300)

  # This will use default width and height
  Tucan.scatter(:iris, "sepal_width", "sepal_length")

  # You can override if needed the default values
  Tucan.scatter(:iris, "sepal_width", "sepal_length", width: 400, height: 200)
  ```

- Add `Tucan.Axes.set_labels_angle/3` for rotating axes labels.
- Add `Tucan.Axes.set_labels_enabled/3` for disabling axes labels.

### Changed

- `Tucan.Export` now uses `VegaLite.Convert` through the `:vega_lite_convert`
package.

## [v0.4.1](https://github.com/pnezis/tucan/tree/v0.4.1) (2024-10-31)

### Fixed

- Properly handle `:zoomable` option in `Tucan.Finance.candlestick/7` and other multi-layer
plots.
- Remove `:zoomable` option from plots with non quantitative scales since this is not
supported by vega-lite.

## [v0.4.0](https://github.com/pnezis/tucan/tree/v0.4.0) (2024-10-21)

### Added

#### Plots

- Add `Tucan.range_bar/4` plot

  ```tucan
  data = [
    %{category: "A", min: 28, max: 55},
    %{category: "B", min: 43, max: 91},
    %{category: "C", min: 13, max: 61}
  ]

  Tucan.range_bar(data, "category", "min", "max", fill_color: "red")
  ``` 

- Add `Tucan.Finance.candlestick/7` specialized plot

  ```tucan
  Tucan.Finance.candlestick(:ohlc, "date", "open", "high", "low", "close",
    width: 400,
    tooltip: true,
    fill_opacity: 0.5
  )
  ```

- Add `Tucan.Geometry.ellipse/5`

  ```tucan
  Tucan.layers([
    Tucan.Geometry.ellipse({0, 0}, 5, 3, 0, line_color: "green"),
    Tucan.Geometry.ellipse({2, 2}, 4, 1, 40, line_color: "red"),
  ])
  |> Tucan.Scale.set_xy_domain(-7, 7)
  ```

#### Other

- Support zoom and pan with mouse in all plots. You can use your mouse to zoom and pan
most plots if `:zoomable` option is set to `true`. You can also reset the view with a double click.

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length", zoomable: true)
  ```

- Add `Tucan.Export` wrapper around `VegaLite.Export`
- Add `Tucan.Axes.set_color/2`, `Tucan.Axes.set_color/3` helpers.
- Add `Tucan.Axes.set_title_color/3` helpers.
- Add `Tucan.Grid.set_color/2` helper.
- Add `Tucan.Scale.set_clamp/3`.
- Support setting `:container` to `width` and `height`.

### Fixed

- Do not flip custom encoding options if `:orient` flag is set.
- `Tucan.ruler/4`, `Tucan.hruler/3` and `Tucan.vruler/3` can now be used
independently:

  ```tucan
  Tucan.layers([
    Tucan.hruler(Tucan.new(), 10),
    Tucan.hruler(Tucan.new(), 15, stroke_width: 2),
    Tucan.vruler(Tucan.new(), 1),
    Tucan.vruler(Tucan.new(), 4.3, line_color: "red")
  ])
  ```

### Removed

- Remove `Tucan.circle/4`

## [v0.3.1](https://github.com/pnezis/tucan/tree/v0.3.1) (2024-01-20)

### Added plot options

- Support `:fill_color` and `:corner_radius` in `Tucan.bar/4`
- Support `:fill_color` and `:corner_radius` in `Tucan.histogram/3`
- Support `:fill_color`, `:point_color` and `:line_color` in `Tucan.area/4`

## [v0.3.0](https://github.com/pnezis/tucan/tree/v0.3.0) (2024-01-03)

### Added

- `Nx` support, you can pass directly tensors as data series.

  ```tucan
  x = Nx.linspace(-20, 20, n: 200)
  y = Nx.pow(x, 2)

  Tucan.lineplot([x: x, y: y], "x", "y", width: 400)
  ```

- Add `Tucan.imshow/2` for rendering pseudo-color images

  ```tucan
  image = Nx.tensor([[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12]], type: {:f, 32})

  Tucan.imshow(image, show_scale: true, width: 200, height: 150)
  ```

- Add `Tucan.errorbar/3` plot

  ```tucan
  Tucan.errorbar(:barley, "yield", group_by: "variety", points: true, ticks: true)
  |> Tucan.color_by("variety")
  ```

- Add `Tucan.errorband/4` plot

  ```tucan
  Tucan.errorband(:cars, "Year", "Miles_per_Gallon",
    extent: :ci,
    fill_color: "black",
    borders: true,
    x: [time_unit: "year", type: :temporal]
  )
  ```

- Add `Tucan.lollipop/4` plot

  ```tucan
  data = [
    category: ["A", "B", "C", "D"],
    value: [90, 72, 81, 50, 64]
  ]

  Tucan.lollipop(data, "category", "value",
    orient: :horizontal,
    point_color: "red",
    width: 300
  )
  |> Tucan.Scale.set_x_domain(30, 100)
  ```

- Add `Tucan.Geometry.polyline/2` and `Tucan.Geometry.rectangle/3`

  ```tucan
  Tucan.layers([
    Tucan.Geometry.rectangle({-2, 10}, {7, -3}, line_color: "green"),
    Tucan.Geometry.rectangle({-3.5, 0.1}, {8.1, -4.2},
      fill_color: "pink",
      fill_opacity: 0.3
    ),
    Tucan.Geometry.polyline([{1, 1}, {2, 7}, {5, 3}],
      closed: true,
      fill_color: "green",
      fill_opacity: 0.3
    )
  ])
  |> Tucan.Scale.set_xy_domain(-5, 11)
  ```

- Support setting plot's background color through `Tucan.View.set_background/2`
- Support setting view's background color through `Tucan.View.set_view_background/2`
- Add `Tucan.Axes.set_offset/3`
- Add `Tucan.Legend.set_offset/3`
- Support setting axes orientation with `Tucan.Axes.set_orientation/3`

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Axes.set_orientation(:y, :right)
  ```

- Add `Tucan.Scale.set_scale/4` and enable passing scale options.
- Add `Tucan.href_by/2`.

### Added plot options

- Support `:point_shape`, `:point_size` and `:point_color` in `Tucan.stripplot/3`.
- Support uniform jittering through `:jitter_mode` in `Tucan.Stripplot/3`.
- Support stacked mode in `Tucan.density/3`.

### Changed

- Flipped `:orient` semantics for `Tucan.bar/4`
- Rename `:group` option to `:group_by` in `Tucan.stripplot/3` for consistency.
- Rename `:groupby` option to `:group_by` in `Tucan.density/3` for consistency.
- Rename `:area_color` option to `:fill_color` in `Tucan.density/3` for consistency.

### Deprecated

- Deprecate `Tucan.circle/4` in favour of `Tucan.Geometry.circle/3`

## [v0.2.1](https://github.com/pnezis/tucan/tree/v0.2.1) (2023-10-17)

### Added

- Support conditional text color in heatmaps using the `:text_color` option.

  ```tucan
  Tucan.heatmap(:glue, "Task", "Model", "Score",
    annotate: true,
    text: [format: ".1f"],
    text_color: [{nil, 40, "black"}, {40, 80, "white"}, {60, nil, "yellow"}]
  )
  |> Tucan.set_size(250, 250)
  ```

- Add `Tucan.annotate/5` auxiliary plot for adding text to a plot

  ```tucan
  Tucan.new()
  |> Tucan.annotate(10, 10, "Hello", color: :red, font_size: 20)
  |> Tucan.annotate(15, 12, "world...", color: :green, font_weight: :bold)
  |> Tucan.Scale.set_xy_domain(8, 17)
  ```

- Add `Tucan.Layers` with helper layers related functions.
- Add `Tucan.background_image/2` helper function.

- Add `Tucan.circle/4` helper function
- Add `Tucan.Scale.set_xy_domain/3`
- Support setting multi-line string in `Tucan.set_title/3`

### Added plot options

- Support `:only` in all plots. Using `:only` you can select only a subset of the input dataset for the current plot.
- Support `:point_color` in `Tucan.lineplot/4`
- Support `:area_color` and `:filled` in density plot
- Support `:stroke_dash` in `Tucan.ruler/4`, `Tucan.hruler/3` and `Tucan.vruler/3`
- Support `:stroke_dash` in `Tucan.lineplot/4`

## [v0.2.0](https://github.com/pnezis/tucan/tree/v0.2.0) (2023-09-23)

### Added

- Add `Tucan.jointplot/4` composite plot.

  ```tucan
    Tucan.jointplot(
      :penguins, "Beak Length (mm)", "Beak Depth (mm)",
      marginal: :density,
      color_by: "Species",
      marginal_opts: [fill_opacity: 0.5]
    )
  ```

- Add `Tucan.punchcard/5` plot. This is similar to heatmap but the third
  dimension is encoded by size instead of color.

  ```tucan
  Tucan.punchcard(:glue, "Task", "Model", "Score")
  |> Tucan.color_by("Score", recursive: true, type: :quantitative)
  |> Tucan.set_size(250, 250)
  ```

- Add `Tucan.heatmap/5` plot.

  ```tucan
  Tucan.heatmap(:glue, "Task", "Model", "Score", annotate: true, text: [format: ".1f"])
  |> Tucan.set_size(250, 250)
  ```

- Add `Tucan.hruler/2`, `Tucan.vruler/2` and `Tucan.ruler/4` helpers.

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length", width: 300)
  |> Tucan.hruler(3, line_color: "green")
  |> Tucan.vruler("petal_width", color_by: "species", stroke_width: 3)
  |> Tucan.hruler("petal_length", color_by: "species")
  ```

- Add `Tucan.Legend` module for customizing legend properties.
- Add `Tucan.Scale` helper module with helper functions for working with
  scales, like `Tucan.Scale.set_color_scheme/3`.
- Add `Tucan.set_size/3` helper for setting both width and height at once.
- Add `Tucan.Axes.set_xy_titles/3` for setting axes titles at once.
- Port more themes from `vega-themes`, check `Tucan.Themes` for all
  available themes.

- Add `Tucan.layers/2` helper

  ```tucan
  Tucan.layers(
    [
      Tucan.scatter(:iris, "petal_width", "petal_length", point_color: "red"),
      Tucan.scatter(:iris, "sepal_width", "sepal_length", point_color: "green")
    ]
  )
  ```

### Added plots options

- Support `:filled` option in `Tucan.scatter/4`
- Support `:wrapped` mode in `Tucan.facet_by/4`
- Support `:color_by` option in `Tucan.stripplot/3`
- Support `:line_color` option in `Tucan.lineplot/4`
- Support `:point_color`, `:point_shape` and `:point_size` in `Tucan.scatter/4`

### Fixed

- Support setting `:orient` in `Tucan.density/3`.
- Make size encodings quantitative by default.

### Deprecated

- Made `Tucan.VegaLiteUtils` private.
- `Tucan.Axes.put_axis_options` is renamed to `Tucan.Axes.put_options/3`
- Rename `:groupby` to `:group_by` in `Tucan.boxplot/3` options.

## [v0.1.1](https://github.com/pnezis/tucan/tree/v0.1.1) (2023-08-29)

### Added

- Add `concat/2`, `hconcat/2` and `vconcat/2` helper concatenation functions.

## [v0.1.0](https://github.com/pnezis/tucan/tree/v0.1.0) (2023-08-28)

Initial release.
