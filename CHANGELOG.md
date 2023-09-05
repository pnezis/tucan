# Changelog

## [UNRELEASED]

- Add `jointplot/4` composite plot.

```tucan
  Tucan.jointplot(
    :penguins, "Beak Length (mm)", "Beak Depth (mm)",
    marginal: :density,
    color_by: "Species",
    marginal_opts: [fill_opacity: 0.5]
  )
```

- Add `heatmap/5` plot.

```tucan
Tucan.heatmap(:glue, "Task", "Model", "Score", fill_opacity: 1.0)
```

- Add `hline/2`, `vline/2` and `line/3` helpers.

```tucan
Tucan.scatter(:iris, "petal_width", "petal_length", width: 300)
|> Tucan.hline(3, line_color: "green")
|> Tucan.vline("petal_width", color_by: "species", stroke_width: 3)
|> Tucan.hline("petal_length", color_by: "species")
```

- Port more themes.

## [v0.1.1](https://github.com/pnezis/tucan/tree/v0.1.1) (2023-08-29)

### Enhancements

- Add `concat/2`, `hconcat/2` and `vconcat/2` helper concatenation functions.

## [v0.1.0](https://github.com/pnezis/tucan/tree/v0.1.0) (2023-08-28)

Initial release.
