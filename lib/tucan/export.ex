defmodule Tucan.Export do
  @moduledoc """
  Various export methods for `Tucan` plots.

  This is a simple wrapper around the `VegaLite.Export` API. It provides helper
  utilities for exporting a tucan plot as `json`, `html`, `png`, `svg` or `pdf`.

  > #### External dependencies {: .info}
  >
  > All of the export functions depend on the `:jason` package. Additionally PNG,
  > SVG and PDF exports rely on `npm` packages, so you will need `Node.js`, `npm`,
  > and the following dependencies installed:
  >
  > ```bash
  > npm install -g vega vega-lite canvas
  > ```
  >
  > For more details check `VegaLite.Export`.
  """

  @doc """
  Saves a `Tucan` specification in one of the supported formats.

  ## Options

  * `:format` - the format to export the graphic as,
    must be either of: `:json`, `:html`, `:png`, `:svg`, `:pdf`.
    By default the format is inferred from the file extension.

  * `:local_npm_prefix` - a relative path pointing to a local npm project directory
    where the necessary npm packages are installed.

  ## Examples

  ```elixir
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Export.save!("iris.png")
  ```

  See also `VegaLite.Export.save!/3`
  """
  @spec save!(vl :: VegaLite.t(), path :: String.t(), opts :: keyword()) :: :ok
  def save!(vl, path, opts \\ []) do
    VegaLite.Export.save!(vl, path, opts)
  end

  @doc """
  Returns the underlying Vega-Lite specification as JSON.

  See also `VegaLite.Export.to_json/1`
  """
  @spec to_json(vl :: VegaLite.t()) :: String.t()
  def to_json(vl), do: VegaLite.Export.to_json(vl)

  @doc """
  Builds an HTML page that renders the given graphic.

  See also `VegaLite.Export.to_html/1`
  """
  @spec to_html(vl :: VegaLite.t()) :: String.t()
  def to_html(vl), do: VegaLite.Export.to_html(vl)

  @doc """
  Renders the given graphic as a PNG image and returns its binary content.

  Relies on the `npm` packages mentioned above.

  ## Options

  * `:local_npm_prefix` - a relative path pointing to a local npm project directory
    where the necessary npm packages are installed.

  See also `VegaLite.Export.to_png/2`

  """
  @spec to_png(vl :: VegaLite.t(), opts :: keyword()) :: binary()
  def to_png(vl, opts \\ []), do: VegaLite.Export.to_png(vl, opts)

  @doc """
  Renders the given graphic into a PDF and returns its binary content.

  Relies on the `npm` packages mentioned above.

  ## Options

  * `:local_npm_prefix` - a relative path pointing to a local npm project directory
    where the necessary npm packages are installed.

  See also `VegaLite.Export.to_pdf/2`

  """
  @spec to_pdf(vl :: VegaLite.t(), opts :: keyword()) :: binary()
  def to_pdf(vl, opts \\ []), do: VegaLite.Export.to_pdf(vl, opts)

  @doc """
  Renders the given graphic as an SVG image and returns its binary content.

  Relies on the `npm` packages mentioned above.

  ## Options

  * `:local_npm_prefix` - a relative path pointing to a local npm project directory
    where the necessary npm packages are installed.

  See also `VegaLite.Export.to_svg/2`

  """
  @spec to_svg(vl :: VegaLite.t(), opts :: keyword()) :: binary()
  def to_svg(vl, opts \\ []), do: VegaLite.Export.to_svg(vl, opts)
end
