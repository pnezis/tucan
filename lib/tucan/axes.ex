defmodule Tucan.Axes do
  @moduledoc """
  Utilities for configuring plot axes.
  """
  alias Tucan.VegaLiteUtils

  @type axis :: :x | :y

  @doc """
  Sets the x axis title.

  This is an alias for `set_title/3`.
  """
  @spec set_x_title(vl :: VegaLite.t(), title :: binary()) :: VegaLite.t()
  def set_x_title(vl, title) when is_struct(vl, VegaLite) and is_binary(title) do
    set_title(vl, :x, title)
  end

  @doc """
  Sets the y axis title.

  This is an alias for `set_title/3`.
  """
  @spec set_y_title(vl :: VegaLite.t(), title :: binary()) :: VegaLite.t()
  def set_y_title(vl, title) when is_struct(vl, VegaLite) and is_binary(title) do
    set_title(vl, :y, title)
  end

  @doc """
  Set the title of the given `axis`.

  An `ArgumentError` is raised if the `x` encoding channel is not defined.
  """
  @spec set_title(vl :: VegaLite.t(), axis :: axis(), title :: binary()) :: VegaLite.t()
  def set_title(vl, axis, title) do
    put_axis_options(vl, axis, title: title)
  end

  defp put_axis_options(vl, encoding, options) do
    VegaLiteUtils.put_encoding_options!(vl, encoding, axis: options)
  end
end
