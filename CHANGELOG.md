# Changelog

## [Unreleased]

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
