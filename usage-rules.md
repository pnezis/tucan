# Tucan Usage Rules

Tucan is a high-level plotting API that returns `%VegaLite{}` specifications.
Start with the plot constructor that matches the visualization you need, then
pipe the result through Tucan or `VegaLite` functions for customization. See the
[README](README.md) for the basic workflow and the [`Tucan`
API](https://hexdocs.pm/tucan/Tucan.html) for the plot and option catalogs.

```elixir
Tucan.scatter(data, "petal_width", "petal_length", color_by: "species")
|> Tucan.Axes.set_xy_titles("Petal width", "Petal length")
|> Tucan.set_theme(:latimes)
```

- Pass a built-in dataset atom, dataset URL, existing `%VegaLite{}`, or any
  tabular value implementing `Table.Reader` as the first constructor argument.
  Fields are named with strings. Use `Tucan.new/2` when constructing a
  specification incrementally; see its API documentation for accepted data
  shapes and optional `Nx` support.
- In-memory data types are inferred from the first row. URL-backed data cannot
  be inspected, and inconsistent first rows can produce the wrong encoding;
  override a channel explicitly, such as `x: [type: :temporal]`, when inference
  is unavailable or unsuitable.
- Prefer constructor options such as `:color_by`, `:shape_by`, and `:size_by`
  when creating a plot. This is required when grouping must participate in a
  data transformation—for example, use `Tucan.density(..., color_by: field)`
  rather than piping the result through `Tucan.color_by/3`.
- Pass arbitrary Vega-Lite encoding settings through the constructor's channel
  options (`:x`, `:y`, `:color`, and similar). With `orient: :horizontal`, these
  options refer to the final channels after orientation, not the constructor's
  default channels.
- Compose plots with `Tucan.layers/1`, `Tucan.hconcat/2`, `Tucan.vconcat/2`,
  `Tucan.concat/2`, or `Tucan.facet_by/4`. Helpers that target a single view may
  reject concatenated plots; for grouping helpers on composite plots, pass
  `recursive: true` when the encoding must be applied to every valid child.
- Use Tucan's styling modules (`Tucan.Axes`, `Tucan.Scale`, `Tucan.Legend`,
  `Tucan.Grid`, and `Tucan.View`) for common changes. Because the result remains
  a `%VegaLite{}`, use the public `VegaLite` API directly for unsupported
  transforms or specification details.
- Use `Tucan.configure/1` for application-wide default dimensions; options on an
  individual plot take precedence over those defaults.
- Export with `Tucan.Export` only after adding the optional
  `:vega_lite_convert` dependency. `Tucan.Export.save!/3` infers the output
  format from the filename unless `:format` is supplied; see the
  [`Tucan.Export` API](https://hexdocs.pm/tucan/Tucan.Export.html) for binary and
  document conversion functions.
