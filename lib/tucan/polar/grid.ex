defmodule Tucan.Polar.Grid do
  @moduledoc false

  # The polar grid of `Tucan.Polar` plots.
  #
  # The grid is drawn as layers in cartesian coordinates, using the same x/y scale
  # as the data, over the domain [-max_radius, max_radius].

  alias VegaLite, as: Vl

  defstruct [
    :max_radius,
    :radius_ticks,
    :angle_marks,
    :direction,
    :angle_offset,
    :width,
    :color,
    :opacity
  ]

  @type t :: %__MODULE__{}

  @doc """
  Creates the grid configuration from the polar options.

  `infer_max_radius` is called if neither `:max_radius` nor `:radius_ticks` are
  set, and must return the maximum absolute radius of the data or `nil` if it
  cannot be inferred.
  """
  @spec new(opts :: keyword(), infer_max_radius :: (-> number() | nil)) :: t()
  def new(opts, infer_max_radius) do
    {max_radius, radius_ticks} =
      case {opts[:max_radius], opts[:radius_ticks]} do
        {nil, nil} ->
          max_radius = infer_max_radius.() || raise_no_max_radius!()
          max_radius = nice_max(max_radius)
          {max_radius, ticks(max_radius)}

        {nil, ticks} ->
          {Enum.max(ticks), ticks}

        {max_radius, nil} ->
          {max_radius, ticks(max_radius)}

        {max_radius, ticks} ->
          {max_radius, ticks}
      end

    %__MODULE__{
      max_radius: max_radius,
      radius_ticks: radius_ticks,
      angle_marks: opts[:angle_marks],
      direction: opts[:direction],
      angle_offset: opts[:angle_offset],
      width: opts[:width],
      color: opts[:grid_color],
      opacity: opts[:grid_opacity]
    }
  end

  defp raise_no_max_radius! do
    raise ArgumentError,
          "cannot infer the maximum radius of a polar plot if the data are not " <>
            "passed inline, set either the :max_radius or the :radius_ticks option"
  end

  @doc """
  Encodes the given fields to the x, y channels using the grid's scale.
  """
  @spec encode_xy(vl :: VegaLite.t(), x :: String.t(), y :: String.t(), grid :: t()) ::
          VegaLite.t()
  def encode_xy(vl, x, y, grid) do
    xy_opts = [
      type: :quantitative,
      scale: [domain: [-grid.max_radius, grid.max_radius], nice: false, zero: false],
      axis: nil
    ]

    vl
    |> Vl.encode_field(:x, x, xy_opts)
    |> Vl.encode_field(:y, y, xy_opts)
  end

  @doc """
  Returns the grid layers.
  """
  @spec layers(grid :: t()) :: [VegaLite.t()]
  def layers(grid) do
    style = [color: grid.color, opacity: grid.opacity]

    [
      circles_layer(grid, style),
      angle_lines_layer(grid, style),
      angle_labels_layer(grid),
      radius_labels_layer(grid)
    ]
  end

  defp circles_layer(grid, style) do
    radiuses = Enum.uniq(grid.radius_ticks ++ [grid.max_radius])

    values =
      for r <- radiuses, i <- 0..180 do
        angle = deg_to_rad(i * 2)
        %{r: r, i: i, x: r * :math.cos(angle), y: r * :math.sin(angle)}
      end

    Vl.new()
    |> Vl.data_from_values(values)
    |> Vl.mark(:line, style ++ [stroke_width: 1])
    |> encode_xy("x", "y", grid)
    |> Vl.encode_field(:detail, "r", type: :nominal)
    |> Vl.encode_field(:order, "i", type: :quantitative)
  end

  defp angle_lines_layer(grid, style) do
    values =
      for angle <- grid.angle_marks do
        {x, y} = point(grid.max_radius, angle, grid)
        %{x: 0, y: 0, x2: x, y2: y}
      end

    Vl.new()
    |> Vl.data_from_values(values)
    |> Vl.mark(:rule, style ++ [stroke_width: 1])
    |> encode_xy("x", "y", grid)
    |> Vl.encode_field(:x2, "x2")
    |> Vl.encode_field(:y2, "y2")
  end

  # Angle labels are placed a fixed number of pixels outside of the outer circle
  @angle_labels_padding 16

  defp angle_labels_layer(grid) do
    label_radius = grid.max_radius * (1 + @angle_labels_padding / (grid.width / 2))

    values =
      for angle <- grid.angle_marks do
        {x, y} = point(label_radius, angle, grid)
        %{x: x, y: y, label: "#{format_number(angle)}°"}
      end

    Vl.new()
    |> Vl.data_from_values(values)
    |> Vl.mark(:text, align: :center, baseline: :middle)
    |> encode_xy("x", "y", grid)
    |> Vl.encode_field(:text, "label")
  end

  # Radius labels are placed between the first two angle marks
  defp radius_labels_layer(grid) do
    angle =
      case Enum.sort(grid.angle_marks) do
        [first, second | _rest] -> (first + second) / 2
        [first] -> first + 22.5
        [] -> 22.5
      end

    values =
      for r <- grid.radius_ticks do
        {x, y} = point(r, angle, grid)
        %{x: x, y: y, label: format_number(r)}
      end

    Vl.new()
    |> Vl.data_from_values(values)
    |> Vl.mark(:text, align: :center, baseline: :middle, font_size: 10, opacity: 0.8)
    |> encode_xy("x", "y", grid)
    |> Vl.encode_field(:text, "label")
  end

  @doc """
  The cartesian position of the given radius and angle in degrees.
  """
  @spec point(r :: number(), angle :: number(), grid :: t()) :: {number(), number()}
  def point(r, angle, grid) do
    phi = screen_angle(angle, grid)

    {round_float(r * :math.cos(phi)), round_float(r * :math.sin(phi))}
  end

  # The angle in radians, counter clockwise from the x-axis, at which the given
  # angle in degrees is drawn
  defp screen_angle(angle, %{direction: direction, angle_offset: offset}) do
    sign = if direction == :clockwise, do: -1, else: 1

    deg_to_rad(sign * angle + offset)
  end

  ## Radius ticks

  @doc """
  Rounds up the given radius to a multiple of a round tick step.
  """
  @spec nice_max(value :: number()) :: number()
  def nice_max(value) when value == 0, do: 1

  def nice_max(value) do
    step = nice_step(value)

    (Float.ceil(value / step - 1.0e-9) * step)
    |> round_float()
  end

  # A step of 1, 2, 2.5 or 5 times a power of 10 that splits the value in ~4 ticks
  defp nice_step(value) do
    raw = value / 4
    magnitude = :math.pow(10, Float.floor(:math.log10(raw)))

    factor = Enum.find([1, 2, 2.5, 5, 10], fn f -> f * magnitude >= raw end)
    factor * magnitude
  end

  defp ticks(max_radius) do
    step = divisor_step(max_radius) || nice_step(max_radius)
    count = trunc(Float.floor(max_radius / step + 1.0e-9))

    for i <- 1..count//1, do: round_float(i * step)
  end

  # A round step that splits the max radius in 3 to 6 equal ticks, preferring 4 ticks,
  # so that the outer circle is labeled
  defp divisor_step(max_radius) do
    magnitude = :math.pow(10, Float.floor(:math.log10(max_radius)))

    candidates =
      for m <- [magnitude / 10, magnitude],
          f <- [1, 2, 2.5, 5],
          step = f * m,
          count = max_radius / step,
          abs(count - round(count)) < 1.0e-9,
          round(count) in 3..6 do
        {abs(round(count) - 4), step}
      end

    case candidates do
      [] -> nil
      candidates -> candidates |> Enum.min() |> elem(1)
    end
  end

  defp round_float(value) do
    rounded = Float.round(value * 1.0, 10)

    if rounded == Float.round(rounded), do: trunc(rounded), else: rounded
  end

  defp format_number(value) when is_integer(value), do: Integer.to_string(value)

  defp format_number(value) do
    if value == Float.round(value), do: Integer.to_string(trunc(value)), else: to_string(value)
  end

  defp deg_to_rad(angle), do: angle * :math.pi() / 180
end
