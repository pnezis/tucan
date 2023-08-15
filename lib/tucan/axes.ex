defmodule Tucan.Axes do
  @moduledoc """
  Utilities for configuring plot axes.
  """
  alias Tucan.VegaLiteUtils

  @doc """
  Sets the x axis title.

  An `ArgumentError` is raised if the `x` encoding channel is not defined.
  """
  @spec set_x_title(vl :: VegaLite.t(), title :: binary()) :: VegaLite.t()
  def set_x_title(vl, title) when is_struct(vl, VegaLite) and is_binary(title) do
    put_axis_options(vl, :x, title: title)
  end

  @doc """
  Sets the y axis title.

  An `ArgumentError` is raised if the `x` encoding channel is not defined.
  """
  @spec set_y_title(vl :: VegaLite.t(), title :: binary()) :: VegaLite.t()
  def set_y_title(vl, title) when is_struct(vl, VegaLite) and is_binary(title) do
    put_axis_options(vl, :y, title: title)
  end

  defp put_axis_options(vl, encoding, options) do
    VegaLiteUtils.put_encoding_options!(vl, encoding, axis: options)
  end
end
