defmodule Tucan.Themes do
  @themes Tucan.Themes.Helpers.load_themes()

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
  project. The following themes are currently supported:

  #{Tucan.Themes.Helpers.docs(@themes)}
  """

  @doc """
  Returns the configuration object for the given theme.

  An exception will be raised if the theme name is invlaid.
  """
  @spec theme(name :: atom()) :: keyword()
  def theme(name) do
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
