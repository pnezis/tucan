defmodule Tucan.Themes do
  @themes_dir Path.expand("../../themes", __DIR__)
  @themes Tucan.Themes.Helpers.load_themes(@themes_dir)

  @theme_example """
  scatter =
    Tucan.scatter(:iris, "petal_width", "petal_length", tooltip: true)
    |> Tucan.color_by("species")
    |> Tucan.shape_by("species")

  lines = Tucan.lineplot(:stocks, "date", "price", color_by: "symbol", x: [type: :temporal])

  area =
    Tucan.area(:stocks, "date", "price", color_by: "symbol", mode: :normalize, x: [type: :temporal])

  density = Tucan.density(:penguins, "Body Mass (g)", color_by: "Species", fill_opacity: 0.2)

  strip =
    Tucan.stripplot(:tips, "total_bill", group_by: "day", style: :jitter)
    |> Tucan.color_by("sex")

  boxplot = Tucan.boxplot(:penguins, "Body Mass (g)", color_by: "Species")
  histogram = Tucan.histogram(:cars, "Horsepower", color_by: "Origin", fill_opacity: 0.5)

  pie = Tucan.pie(:barley, "yield", "site", aggregate: :sum, tooltip: true)

  donut = Tucan.donut(:barley, "yield", "site", aggregate: :sum, tooltip: true)

  heatmap =
    Tucan.density_heatmap(:penguins, "Beak Length (mm)", "Beak Depth (mm)")

  Tucan.vconcat(
    [
      Tucan.hconcat([scatter, lines, area]),
      Tucan.hconcat([density, Tucan.vconcat([strip, boxplot]), histogram]),
      Tucan.hconcat([pie, donut, heatmap])
    ]
  )
  |> VegaLite.config(legend: [disable: true])
  |> VegaLite.resolve(:scale, color: :independent)
  """

  @moduledoc """
  Helper functions for `Tucan` theme.

  You can apply any of the supported themes through the `Tucan.set_theme/2` helper:

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.color_by("species")
  |> Tucan.shape_by("species")
  |> Tucan.set_theme(:latimes)
  ```

  > #### Themes and `livebook` {: .warning}
  >
  > If you are using `Tucan` with `livebook` notice that
  > [`kino_vega_lite`](https://github.com/livebook-dev/kino_vega_lite) applies by default
  > a theme that may override `Tucan` theme settings. You can disable the default
  > theme through `Kino.VegaLite.configure/1`:
  >
  > ```elixir
  > # disable default livebook theme
  > Kino.VegaLite.configure(theme: nil)
  >
  > Tucan.scatter(:iris, "petal_width", "petal_length")
  > |> Tucan.color_by("species")
  > |> Tucan.shape_by("species")
  > |> Tucan.set_theme(:dark)
  > ```

  ## About themes

  A `Tucan` theme is nothing more than a keyword list with a `VegaLite` configuration
  object with some styles applied and some metadata. Every theme must have the
  following format:

      [
         theme: [],          # the actual theme configuration
         name: :name,        # an atom with a unique name
         doc: "description", # a description of the theme,
         source: "url"       # a url to the source of the theme if any for attribution
      ]

  ## Default themes

  `Tucan` comes pre-packed with a set of themes, borrowed by the [Vega Themes](https://github.com/vega/vega-themes)
  project. You can set a theme to a plot by calling the `Tucan.set_theme/2` function. If no
  theme set the default vega-lite theme is used. In all examples below the following example
  plot is used:

  ```tucan
  #{@theme_example}
  ```

  The following themes are currently supported:

  #{Tucan.Themes.Helpers.docs(@themes, @theme_example)}
  """

  @doc """
  Returns the configuration object for the given theme.

  An exception will be raised if the theme name is invalid.
  """
  @spec theme(name :: atom()) :: keyword()
  def theme(name) do
    case Keyword.has_key?(@themes, name) do
      true ->
        Keyword.get(@themes, name)
        |> Keyword.fetch!(:theme)

      false ->
        themes = Keyword.keys(@themes) |> Enum.sort()
        raise ArgumentError, "invalid theme #{inspect(name)}, supported: #{inspect(themes)}"
    end
  end
end
