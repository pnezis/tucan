# Tucan

[![Actions Status](https://github.com/pnezis/tucan/actions/workflows/elixir.yml/badge.svg)](https://github.com/pnezis/tucan/actions)
[![Hex.pm](https://img.shields.io/hexpm/v/tucan.svg)](https://hex.pm/packages/tucan)
[![Documentation](https://img.shields.io/badge/-Documentation-blueviolet)](https://hexdocs.pm/tucan/Tucan.html)

`Tucan` is an Elixir plotting library built on top of `VegaLite`, designed to simplify
the creation of interactive and visually stunning plots. With `Tucan`, you can effortlessly
generate a wide range of plots, from simple bar charts to complex composite plots,
all while enjoying the power and flexibility of a clean composable functional API.

`Tucan` offers a simple API for creating most common plot types similarly to `matplotlib`
and `seaborn` without requiring the end user to be familiar with the Vega Lite grammar.

![Tucan](https://github.com/pnezis/tucan/raw/main/assets/tucan.png)

## Features

- **Versatile Plot Types** - `Tucan` provides an array of plot types, including
  bar charts, line plots, scatter plots, histograms, and more, allowing you to
  effectively represent diverse data sets.
- **Clean and consistent API** - A clean and consistent plotting API similar to `matplotlib`
  or `seaborn` is provided. You should be able to create most common plots with
  a single function call and minimal configuration.
- **Grouping and Faceting** - Enhance your visualizations with grouping and faceting
  features, enabling you to examine patterns and trends within subgroups of your
  data.
- **Customization** - Customize your plots with ease using Tucan's utilities for
  adjusting
  plot dimensions, titles, and **themes**.
- **Thin wrapper on top of VegaLite** - All `VegaLite` functions can be used
  seamlessly with `Tucan` in order to enhance/customize your plots.
- **`Nx` support** - You can pass directly `Nx` tensors in all plot functions.
- **Low level API** - A low level API with helper functions is provided for modifying
  `VegaLite` specifications.

## Basic usage

```elixir
# A simple scatter plot
Tucan.scatter(:iris, "petal_width", "petal_length")

# You can combine it with one or more semantic grouping functions
Tucan.scatter(:iris, "petal_width", "petal_length")
|> Tucan.color_by("species")
|> Tucan.shape_by("species")

# You can pipe it through other Tucan functions to modify the look & feel
Tucan.bubble(:gapminder, "income", "health", "population",
  color_by: "region",
  tooltip: true
)
|> Tucan.set_width(400)
|> Tucan.Axes.set_x_title("Gdp per Capita")
|> Tucan.Axes.set_y_title("Life expectancy")
|> Tucan.Scale.set_x_scale(:log)

# Some composite plots are also supported
fields = ["petal_width", "petal_length", "sepal_width", "sepal_length"]

Tucan.pairplot(:iris, , width: 130, height: 130)
|> Tucan.color_by("species", recursive: true)

# creating facet plots is very easy with the facet_by/4 function
Tucan.scatter(:iris, "petal_width", "petal_length")
|> Tucan.facet_by(:column, "species")
|> Tucan.color_by("species")
```

Read the [docs](https://hexdocs.pm/tucan/Tucan.html) for more examples.

## Installation

### Inside Livebook

You most likely want to use Tucan in [Livebook](https://github.com/livebook-dev/livebook),
in which case you can call `Mix.install/2`:

```elixir
Mix.install([
  {:tucan, "~> 0.3.0"},
  {:kino_vega_lite, "~> 0.1.8"}
])
```

You will also want [kino_vega_lite](https://github.com/livebook-dev/kino_vega_lite) to ensure
Livebook renders the graphics nicely.

### In Mix projects

You can add the `:tucan` dependency to your `mix.exs`:

```elixir
def deps do
  [
    {:tucan, "~> 0.3.0"}
  ]
end
```

**NOTE:** While I will try to maintain backwards compatibility as much as possible,
since this is still a 0.x.x project the API is not considered stable and thus
subject to possible breaking changes up until v1.0.0.

## Acknowledgements

- [vega-lite](https://vega.github.io/vega-lite/) and the awesome docs of it, many
  examples and most of the datasets used are based on it.
- The elixir [VegaLite](https://github.com/livebook-dev/vega_lite) bindings
- [seaborn](https://seaborn.pydata.org/), [matplotlib](https://matplotlib.org/) and
  [ggplot2](https://ggplot2.tidyverse.org/) upon which the high level API is partially
  based.
- [vega-themes](https://github.com/vega/vega-themes) from which the existing themes
  are ported.

## License

Copyright (c) 2023 Panagiotis Nezis

Tucan is released under the MIT License. See the [LICENSE](LICENSE) file for more
details.
