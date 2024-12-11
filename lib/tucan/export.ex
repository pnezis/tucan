defmodule Tucan.Export do
  @moduledoc """
  Various export methods for `Tucan` plots.

  This is a simple wrapper around the `VegaLite.Convert` API. It provides helper
  utilities for exporting a tucan plot as `json`, `html`, `png`, `svg`, `jpeg`
  or `pdf`.

  > #### External dependencies {: .info}
  >
  > All of the export functions depend on the `vega_lite_convert` package.
  > In order to use these functions you need to add the package in your
  > dependencies:
  >
  > ```elixir
  > def deps do
  >   [
  >     {:vega_lite_convert, "~> 1.0.0"}
  >   ]
  > end
  > ```
  """

  @doc """
  Saves a `Tucan` specification in one of the supported formats.

  ## Options

    * `:format` - the format to export the graphic as,
      must be either of: `:json`, `:html`, `:png`, `:svg`, `:pdf`, `:jpeg`.
      By default the format is inferred from the file extension.

  ## Examples

  ```elixir
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Export.save!("iris.png")
  ```

  See also `VegaLite.Convert.save!/3`
  """
  @spec save!(vl :: VegaLite.t(), path :: String.t(), opts :: keyword()) :: :ok
  def save!(vl, path, opts \\ []) do
    assert_vega_lite_convert!()
    VegaLite.Convert.save!(vl, path, opts)
  end

  @doc """
  Returns the underlying Vega-Lite specification as JSON.

  See also `VegaLite.Convert.to_json/1`
  """
  @spec to_json(vl :: VegaLite.t()) :: String.t()
  def to_json(vl) do
    assert_vega_lite_convert!()
    VegaLite.Convert.to_json(vl)
  end

  @doc """
  Builds an HTML page that renders the given graphic.

  ## Options

    * `:bundle` - configures whether the VegaLite client side JS library
      is embedded in the document or if it is pulled down from the CDN.
      Defaults to `true`.

    * `:renderer` - determines how the VegaLite chart is rendered in
      the HTML document. Possible values are: `:svg`, `:canvas`, or
      `:hybrid`. Defaults to `:svg`.

  See also `VegaLite.Convert.to_html/2`
  """
  @spec to_html(vl :: VegaLite.t(), opts :: keyword()) :: String.t()
  def to_html(vl, opts \\ []) do
    assert_vega_lite_convert!()
    VegaLite.Convert.to_html(vl, opts)
  end

  @doc """
  Renders the given graphic as a PNG image and returns its binary content.

  ## Options

    * `:scale` - the image scale factor. Defaults to `1.0`.
    * `:ppi` - the number of pixels per inch. Defaults to `72`

  See also `VegaLite.Convert.to_png/2`
  """
  @spec to_png(vl :: VegaLite.t(), opts :: keyword()) :: binary()
  def to_png(vl, opts \\ []) do
    assert_vega_lite_convert!()
    VegaLite.Convert.to_png(vl, opts)
  end

  @doc """
  Renders the given graphic as a JPEG image and returns its binary content.

  ## Options

    * `:scale` - the image scale factor. Defaults to `1.0`.

    * `:quality` - the quality of the generated JPEG between 0 (worst)
      and 100 (best). Defaults to `90`.

  See also `VegaLite.Convert.to_png/2`
  """
  @spec to_jpeg(vl :: VegaLite.t(), opts :: keyword()) :: binary()
  def to_jpeg(vl, opts \\ []) do
    assert_vega_lite_convert!()
    VegaLite.Convert.to_jpeg(vl, opts)
  end

  @doc """
  Renders the given graphic into a PDF and returns its binary content.

  See also `VegaLite.Convert.to_pdf/1`
  """
  @spec to_pdf(vl :: VegaLite.t()) :: binary()
  def to_pdf(vl) do
    assert_vega_lite_convert!()
    VegaLite.Convert.to_pdf(vl)
  end

  @doc """
  Renders the given graphic as an SVG image and returns its binary content.

  Relies on the `npm` packages mentioned above.

  ## Options

  * `:local_npm_prefix` - a relative path pointing to a local npm project directory
    where the necessary npm packages are installed.

  See also `VegaLite.Convert.to_svg/1`
  """
  @spec to_svg(vl :: VegaLite.t()) :: binary()
  def to_svg(vl) do
    assert_vega_lite_convert!()
    VegaLite.Convert.to_svg(vl)
  end

  defp assert_vega_lite_convert! do
    if !Code.ensure_loaded?(VegaLite.Convert) do
      raise RuntimeError, """
      Tucan.Export depends on the :vega_lite_convert package.

      You can install it by adding

          {:vega_lite_convert, "~> 1.0.0"}

      to your dependency list.
      """
    end
  end
end
