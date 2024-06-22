defmodule Tucan.Axes do
  @moduledoc """
  Utilities for configuring plot axes.
  """
  alias Tucan.Utils

  @type axis :: :x | :y

  @doc """
  Sets the _x-axis_ and _y-axis_ titles at once.
  """
  @spec set_xy_titles(vl :: VegaLite.t(), x_title :: String.t(), y_title :: String.t()) ::
          VegaLite.t()
  def set_xy_titles(vl, x_title, y_title) do
    vl
    |> set_x_title(x_title)
    |> set_y_title(y_title)
  end

  @doc """
  Sets the x axis title.
  """
  @spec set_x_title(vl :: VegaLite.t(), title :: String.t()) :: VegaLite.t()
  def set_x_title(vl, title) when is_struct(vl, VegaLite) and is_binary(title) do
    set_title(vl, :x, title)
  end

  @doc """
  Sets the y axis title.
  """
  @spec set_y_title(vl :: VegaLite.t(), title :: String.t()) :: VegaLite.t()
  def set_y_title(vl, title) when is_struct(vl, VegaLite) and is_binary(title) do
    set_title(vl, :y, title)
  end

  @doc """
  Set the title of the given `axis`.
  """
  @spec set_title(vl :: VegaLite.t(), axis :: axis(), title :: String.t()) :: VegaLite.t()
  def set_title(vl, axis, title) do
    put_options(vl, axis, title: title)
  end

  @doc """
  Sets the title color of the given `axis`

  ## Examples

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Axes.set_title_color(:x, "red")
  |> Tucan.Axes.set_title_color(:y, "#F3B212")
  ```
  """
  @spec set_title_color(vl :: VegaLite.t(), axis :: axis(), color :: String.t()) :: VegaLite.t()
  def set_title_color(vl, axis, color) when is_struct(vl, VegaLite) and is_binary(color) do
    validate_axis!(axis, [:x, :y], "set_title_color/3")

    put_options(vl, axis, title_color: color)
  end

  @doc """
  Sets the axis offset (in pixels).

  The offset indicates the amount in pixels by which the axis will be  displaces from the
  edge of the enclosing group or data rectangle.

  ## Examples

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Axes.set_offset(:y, 10)
  |> Tucan.Grid.set_enabled(false)
  ```
  """
  @spec set_offset(vl :: VegaLite.t(), axis :: axis(), offset :: number()) :: VegaLite.t()
  def set_offset(vl, axis, offset) when is_struct(vl, VegaLite) and is_integer(offset) do
    validate_axis!(axis, [:x, :y], "set_offset/3")

    put_options(vl, axis, offset: offset)
  end

  @doc """
  Sets the `color` of both `:x` and `:y` axes.

  See also `set_color/3`.
  """
  @spec set_color(vl :: VegaLite.t(), color :: String.t()) :: VegaLite.t()
  def set_color(vl, color) when is_struct(vl, VegaLite) and is_binary(color) do
    vl
    |> set_color(:x, color)
    |> set_color(:y, color)
  end

  @doc """
  Set a specific color to the given axis.

  ## Examples

  A scatter plot with the `y-axis` colored red and `x-axis` with a custom RGB color:

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Axes.set_color(:y, "red")
  |> Tucan.Axes.set_color(:x, "#2A32F4")
  ```
  """
  @spec set_color(vl :: VegaLite.t(), axis :: axis(), color :: String.t()) ::
          VegaLite.t()
  def set_color(vl, axis, color)
      when is_struct(vl, VegaLite) and is_binary(color) do
    validate_axis!(axis, [:x, :y], "set_color/3")

    put_options(vl, axis, domain_color: color)
  end

  @type orient :: :bottom | :top | :left | :right

  @doc """
  Sets the orientation for the given axis.

  Valid values for `orient` are:

  * `:top`, `:bottom` for the x axis
  * `:left`, `:right` for the y axis

  ## Examples

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Axes.set_orientation(:x, :top)
  |> Tucan.Axes.set_orientation(:y, :right)
  ```
  """
  @spec set_orientation(vl :: VegaLite.t(), axis :: axis(), orient :: orient()) :: VegaLite.t()
  def set_orientation(vl, axis, orientation) do
    cond do
      axis not in [:x, :y] ->
        raise ArgumentError, "you can only set orientation for :x, :y axes, got: #{inspect(axis)}"

      axis == :x and orientation not in [:bottom, :top] ->
        raise ArgumentError,
              "you can only set :bottom or :top orientation for :x axis, " <>
                "got: #{inspect(orientation)}"

      axis == :y and orientation not in [:left, :right] ->
        raise ArgumentError,
              "you can only set :left or :right orientation for :y axis, " <>
                "got: #{inspect(orientation)}"

      true ->
        put_options(vl, axis, orient: orientation)
    end
  end

  @doc """
  Enables or disables both axes (`x`, `y`) at once.

  See also `set_enabled/3`
  """
  @spec set_enabled(vl :: VegaLite.t(), enabled :: boolean()) :: VegaLite.t()
  def set_enabled(vl, enabled) do
    vl
    |> set_enabled(:x, enabled)
    |> set_enabled(:y, enabled)
  end

  @doc """
  Enables or disables the given axis.

  Notice that axes are enabled by default.

  ## Examples

  ```tucan
  Tucan.scatter(:iris, "petal_width", "petal_length")
  |> Tucan.Axes.set_enabled(:x, false)
  |> Tucan.Axes.set_enabled(:y, false)
  ```
  """
  @spec set_enabled(vl :: VegaLite.t(), axis :: axis(), enabled :: boolean()) :: VegaLite.t()
  def set_enabled(vl, axis, true) when is_struct(vl, VegaLite) do
    Utils.put_encoding_options(vl, axis, axis: [])
  end

  def set_enabled(vl, axis, false) when is_struct(vl, VegaLite) do
    Utils.put_encoding_options(vl, axis, axis: nil)
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
    Utils.put_encoding_options(vl, encoding, axis: options)
  end

  defp validate_axis!(axis, allowed, caller) do
    if axis not in allowed do
      raise ArgumentError,
            "invalid axis #{inspect(axis)} set in #{caller}, only one of #{inspect(allowed)} is allowed"
    end

    :ok
  end
end
