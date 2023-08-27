# Tucan


[![Package](https://img.shields.io/badge/-Package-important)](https://hex.pm/packages/tucan)
[![Documentation](https://img.shields.io/badge/-Documentation-blueviolet)](https://hexdocs.pm/tucan/Tucan.html)

`Tucan` is an Elixir plotting library built on top of `VegaLite`, designed to simplify
the creation of interactive and visually stunning plots. With `Tucan`, you can effortlessly
generate a wide range of plots, from simple bar charts to complex composite plots, all
while enjoying the power and flexibility of a clean composable functional API.

`Tucan` offers a simple API for creating most common plot types similarly to `matplotlib`
and `seaborn` without requiring the end user to be familiar with the Vega Lite grammar.

![Tucan](https://github.com/pnezis/tucan/raw/main/assets/tucan.png)

## Features

- **Versatile Plot Types** - `Tucan` provides an array of plot types, including bar charts,
line plots, scatter plots, histograms, and more, allowing you to effectively represent
diverse data sets.
- **Grouping and Faceting** - Enhance your visualizations with grouping and faceting
features, enabling you to examine patterns and trends within subgroups of your data.
- **Customization** - Customize your plots with ease using Tucan's utilities for adjusting
plot dimensions, titles, and themes.

## Installation

### Inside Livebook

You most likely want to use Tucan in [Livebook](https://github.com/livebook-dev/livebook),
in which case you can call `Mix.install/2`:

```elixir
Mix.install([
  {:tucan, "~> 0.1.0"},
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
    {:tucan, "~> 0.1.0"}
  ]
end
```

## License

Copyright (c) 2023 Panagiotis Nezis

Tucan is released under the MIT License. See the LICENSE file for more details.
