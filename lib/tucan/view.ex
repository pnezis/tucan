defmodule Tucan.View do
  @moduledoc """
  Helper utilities for customizing the plot view.
  """

  @doc """
  Sets the background color of the visualization canvas.

  ## Examples

  ```tucan
  Tucan.scatter(:iris, "sepal_width", "sepal_length")
  |> Tucan.View.set_background("#fcffde")
  ```
  """
  @spec set_background(vl :: VegaLite.t(), color :: String.t()) :: VegaLite.t()
  def set_background(vl, color) when is_struct(vl, VegaLite) and is_binary(color) do
    update_in(vl.spec, fn spec -> Map.merge(spec, %{"background" => color}) end)
  end

  @doc """
  Sets the background color of the view.

  `set_background/2` defines the background of the whole visualization canvas. Meanwhile,
  the view property of a single-view or layer specification can define the background of
  the view.

  ## Examples

  Two concatenated plots with different view backgrounds and an overall canvas
  background.

  ```tucan
  Tucan.hconcat(
    [
      Tucan.scatter(:iris, "sepal_width", "sepal_length")
      |> Tucan.View.set_view_background("#e6fae1"),
      Tucan.scatter(:iris, "petal_width", "petal_length")
      |> Tucan.View.set_view_background("#facbc5"),
    ]
  )
  |> Tucan.View.set_background("#fcffde")
  ```
  """
  @spec set_view_background(vl :: VegaLite.t(), color :: String.t()) :: VegaLite.t()
  def set_view_background(vl, color) do
    update_in(vl.spec, fn spec -> Map.merge(spec, %{"view" => %{"fill" => color}}) end)
  end
end
