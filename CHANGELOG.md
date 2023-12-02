# Changelog

## [Unreleased]

### Added

- Support setting plot's background color through `Tucan.View.set_background/2`
- Support setting view's background color through `Tucan.View.set_view_background/2`
- Add `Tucan.Axes.set_offset/3`
- Add `Tucan.Legend.set_offset/3`
- Support setting axes orientation with `Tucan.Axes.set_orientation/3`

```tucan
Tucan.scatter(:iris, "petal_width", "petal_length")
|> Tucan.Axes.set_orientation(:y, :right)
```

- Add `Tucan.errorbar/3` plot

```tucan
Tucan.errorbar(:barley, "yield", group_by: "variety")
|> Tucan.color_by("variety")
```

### Deprecated

- Deprecate `Tucan.circle/4` in favour of `Tucan.Geometry.circle/4`

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

```tucan
Tucan.new()
|> Tucan.circle({3, 2}, 5, line_color: "purple")
|> Tucan.circle({-1, 6}, 2, line_color: "red")
|> Tucan.circle({0, 1}, 4, line_color: "green", stroke_width: 3)
|> Tucan.Scale.set_xy_domain(-4, 8)
```

- Add `Tucan.Scale.set_xy_domain/3`
- Support setting multi-line string in `Tucan.set_title/3`

### Added plot options

- Support `:only` in all plots. Using `:only` you can select only a subset of the input
  dataset for the current plot.
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
