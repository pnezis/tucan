defmodule Tucan.Axes do
  @moduledoc """
  Utilities for configuring plot axes.
  """
  alias Tucan.VegaLiteUtils

  @type axis :: :x | :y

  @doc """
  Sets the _x-axis_ and _y-axis_ titles at once.
  """
  @spec set_xy_titles(vl :: VegaLite.t(), x_title :: binary(), y_title :: binary()) ::
          VegaLite.t()
  def set_xy_titles(vl, x_title, y_title) do
    vl
    |> set_x_title(x_title)
    |> set_y_title(y_title)
  end

  @doc """
  Sets the x axis title.
  """
  @spec set_x_title(vl :: VegaLite.t(), title :: binary()) :: VegaLite.t()
  def set_x_title(vl, title) when is_struct(vl, VegaLite) and is_binary(title) do
    set_title(vl, :x, title)
  end

  @doc """
  Sets the y axis title.
  """
  @spec set_y_title(vl :: VegaLite.t(), title :: binary()) :: VegaLite.t()
  def set_y_title(vl, title) when is_struct(vl, VegaLite) and is_binary(title) do
    set_title(vl, :y, title)
  end

  @doc """
  Set the title of the given `axis`.
  """
  @spec set_title(vl :: VegaLite.t(), axis :: axis(), title :: binary()) :: VegaLite.t()
  def set_title(vl, axis, title) do
    put_options(vl, axis, title: title)
  end

  @doc """
  Sets an arbitrary set of options to the given `encoding` axis object.

  Notice that no validation is performed, any option set will be merged with
  the existing `axis` options of the given `encoding`.

  An `ArgumentError` is raised if the given encoding channel is not defined.
  """
  @spec put_options(vl :: VegaLite.t(), encoding :: atom(), options :: keyword()) ::
          VegaLite.t()
  def put_options(vl, encoding, options) do
    VegaLiteUtils.put_encoding_options(vl, encoding, axis: options)
  end
end
