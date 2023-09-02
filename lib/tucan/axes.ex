defmodule Tucan.Axes do
  @moduledoc """
  Utilities for configuring plot axes.
  """
  alias Tucan.VegaLiteUtils

  @type axis :: :x | :y

  @type scale :: :linear | :log | :symlog | :pow | :sqrt

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
    put_axis_options(vl, axis, title: title)
  end

  @doc """
  Sets the x axis scale.
  """
  # TODO validate the scale based on the encoding type
  @spec set_x_scale(vl :: VegaLite.t(), scale :: scale()) :: VegaLite.t()
  def set_x_scale(vl, scale) when is_struct(vl, VegaLite) and is_atom(scale) do
    VegaLiteUtils.put_encoding_options(vl, :x, scale: [type: scale])
  end

  @doc """
  Sets the x axis scale.
  """
  @spec set_y_scale(vl :: VegaLite.t(), scale :: scale()) :: VegaLite.t()
  def set_y_scale(vl, scale) when is_struct(vl, VegaLite) and is_atom(scale) do
    VegaLiteUtils.put_encoding_options(vl, :y, scale: [type: scale])
  end

  @doc """
  Sets the x axis domain.
  """
  @spec set_x_domain(vl :: VegaLite.t(), min :: number(), max :: number()) :: VegaLite.t()
  def set_x_domain(vl, min, max), do: set_domain(vl, :x, min, max)

  @doc """
  Sets the y axis domain.
  """
  @spec set_y_domain(vl :: VegaLite.t(), min :: number(), max :: number()) :: VegaLite.t()
  def set_y_domain(vl, min, max), do: set_domain(vl, :y, min, max)

  defp set_domain(vl, axis, min, max)
       when is_struct(vl, VegaLite) and is_number(min) and is_number(max) do
    if min >= max do
      raise ArgumentError,
            "a domain min value cannot be greater than the max value, got [#{min}, #{max}]"
    end

    VegaLiteUtils.put_encoding_options(vl, axis, scale: [domain: [min, max]])
  end

  @doc """
  Sets an arbitrary set of options to the given `encoding` axis object.

  Notice that no validation is performed, any option set will be merged with
  the existing `axis` options of the given `encoding`.

  An `ArgumentError` is raised if the `x` encoding channel is not defined.
  """
  @spec put_axis_options(vl :: VegaLite.t(), encoding :: atom(), options :: keyword()) ::
          VegaLite.t()
  def put_axis_options(vl, encoding, options) do
    VegaLiteUtils.put_encoding_options(vl, encoding, axis: options)
  end
end
