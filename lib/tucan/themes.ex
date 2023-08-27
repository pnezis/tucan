defmodule Tucan.Themes do
  @themes Tucan.Themes.Helpers.load_themes()

  @theme_example """
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.color_by("species")
  |> Tucan.shape_by("species")
  """

  @moduledoc """
  Helper functions for `Tucan` theme.

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

  An exception will be raised if the theme name is invlaid.
  """
  @spec theme(name :: atom()) :: keyword()
  def theme(name) do
    IO.inspect(@themes)

    case Keyword.has_key?(@themes, name) do
      true ->
        Keyword.get(@themes, name)
        |> Keyword.fetch!(:theme)

      false ->
        themes = Keyword.keys(@themes)
        raise ArgumentError, "invalid theme #{inspect(name)}, supported: #{inspect(themes)}"
    end
  end
end
