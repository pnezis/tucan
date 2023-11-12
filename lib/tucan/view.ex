defmodule Tucan.View do
  @moduledoc """
  Helper utilities for customizing the plot view.
  """

  @doc """
  Sets the background color of the plot view.

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
end
