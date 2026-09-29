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
    :angle_labels,
    :radius_labels_angle,
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
      angle_labels: angle_labels(opts[:angle_marks], opts[:angle_labels]),
      radius_labels_angle: opts[:radius_labels_angle],
      direction: opts[:direction],
      angle_offset: opts[:angle_offset],
      width: opts[:width],
      color: opts[:grid_color],
      opacity: opts[:grid_opacity]
    }
  end

  # Returns a list of {angle, label} tuples
  defp angle_labels(marks, :degrees), do: Enum.map(marks, &{&1, "#{format_number(&1)}°"})
  defp angle_labels(marks, :compass), do: Enum.map(marks, &{&1, compass_label(&1)})
  defp angle_labels(_marks, :none), do: []

  defp angle_labels(marks, labels) when is_list(labels) do
    cond do
      Enum.all?(labels, &is_tuple/1) ->
        labels

      length(labels) == length(marks) ->
        Enum.zip(marks, labels)

      true ->
        raise ArgumentError,
              "expected as many :angle_labels as :angle_marks, got #{length(labels)} " <>
                "labels for #{length(marks)} angle marks"
    end
  end

  @compass_points ~w(N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW)

  # Compass points for multiples of 22.5 degrees, degrees otherwise
  defp compass_label(angle) do
    index = angle / 22.5

    if index == Float.round(index * 1.0) do
      Enum.at(@compass_points, Integer.mod(trunc(index), 16))
    else
      "#{format_number(angle)}°"
    end
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
  The options of a `:radius` scale matching the grid.

  Arc marks are centered in the plot, so a radius scale mapping `[0, max_radius]`
  to `[0, width / 2]` pixels is aligned with the grid.
  """
  @spec radius_scale(grid :: t()) :: keyword()
  def radius_scale(grid) do
    [type: :linear, domain: [0, grid.max_radius], range: [0, grid.width / 2], nice: false]
  end

  @doc """
  An expression converting the given expression of an angle in degrees to the
  radians expected by the `:theta` channel of arc marks.

  Arc angles start at the top and increase clockwise.
  """
  @spec arc_theta_expr(degrees :: String.t(), grid :: t()) :: String.t()
  def arc_theta_expr(degrees, %{direction: direction, angle_offset: offset}) do
    sign = if direction == :clockwise, do: -1, else: 1

    "#{deg_to_rad(90 - offset)} - #{sign * :math.pi() / 180} * (#{degrees})"
  end

  @doc """
  Adds the grid layers to the given data layers. The grid labels are always drawn
  above the data.

  The grid lines are drawn below the data, unless `lines_above` is set, e.g. for
  opaque sectors that would hide them.

  The grid layers are named with a `polar_` prefix.
  """
  @spec layers(grid :: t(), data_layers :: [VegaLite.t()], lines_above :: boolean()) ::
          [VegaLite.t()]
  def layers(grid, data_layers, lines_above \\ false) do
    style = [color: grid.color, opacity: grid.opacity]
    lines = [circles_layer(grid, style), angle_lines_layer(grid, style)]
    labels = [angle_labels_layer(grid), radius_labels_layer(grid)]

    if lines_above,
      do: data_layers ++ lines ++ labels,
      else: lines ++ data_layers ++ labels
  end

  defp named_layer(name), do: Tucan.Utils.put_in_spec(Vl.new(), :name, "polar_#{name}")

  defp circles_layer(grid, style) do
    radiuses = Enum.uniq(grid.radius_ticks ++ [grid.max_radius])

    values =
      for r <- radiuses, i <- 0..180 do
        angle = deg_to_rad(i * 2)
        %{r: r, i: i, x: r * :math.cos(angle), y: r * :math.sin(angle)}
      end

    named_layer("circles")
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

    named_layer("angle_lines")
    |> Vl.data_from_values(values)
    |> Vl.mark(:rule, style ++ [stroke_width: 1])
    |> encode_xy("x", "y", grid)
    |> Vl.encode_field(:x2, "x2")
    |> Vl.encode_field(:y2, "y2")
  end

  # Angle labels are placed a fixed number of pixels outside of the outer circle
  @angle_labels_padding 16

  # An estimate of the average character width of the labels in pixels
  @label_char_width 6.5

  @doc """
  The estimated number of pixels the angle labels extend to the right of the plot.
  """
  @spec right_overflow(grid :: t()) :: number()
  def right_overflow(grid) do
    label_radius = grid.width / 2 + @angle_labels_padding

    grid.angle_labels
    |> Enum.map(fn {angle, label} ->
      {x, _y} = point(label_radius, angle, grid)
      x + String.length(label) * @label_char_width / 2 - grid.width / 2
    end)
    |> Enum.max(fn -> 0 end)
    |> max(0)
  end

  defp angle_labels_layer(grid) do
    label_radius = grid.max_radius * (1 + @angle_labels_padding / (grid.width / 2))

    values =
      for {angle, label} <- grid.angle_labels do
        {x, y} = point(label_radius, angle, grid)
        %{x: x, y: y, label: label}
      end

    named_layer("angle_labels")
    |> Vl.data_from_values(values)
    |> Vl.mark(:text, align: :center, baseline: :middle)
    |> encode_xy("x", "y", grid)
    |> Vl.encode_field(:text, "label")
  end

  # Radius labels are placed between the first two angle marks, unless an angle
  # is explicitly set
  defp radius_labels_layer(grid) do
    angle =
      case {grid.radius_labels_angle, Enum.sort(grid.angle_marks)} do
        {nil, [first, second | _rest]} -> (first + second) / 2
        {nil, [first]} -> first + 22.5
        {nil, []} -> 22.5
        {angle, _marks} -> angle
      end

    values =
      for r <- grid.radius_ticks do
        {x, y} = point(r, angle, grid)
        %{x: x, y: y, label: format_number(r)}
      end

    named_layer("radius_labels")
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
  Rounds up the given radius to a round number.

  The smallest multiple of a round step that can be split in 3 to 6 equal ticks is
  preferred, e.g. `5` is kept as is and `1.7` is rounded up to `2`.
  """
  @spec nice_max(value :: number()) :: number()
  def nice_max(value) when value == 0, do: 1

  def nice_max(value) do
    magnitude = :math.pow(10, Float.floor(:math.log10(value)))

    candidates =
      for m <- [magnitude / 10, magnitude],
          f <- [1, 2, 2.5, 5],
          step = f * m,
          candidate = round_float(Float.ceil(value / step - 1.0e-9) * step),
          divisor_step(candidate) != nil do
        candidate
      end

    Enum.min(candidates, fn -> round_up(value, nice_step(value)) end)
  end

  defp round_up(value, step), do: round_float(Float.ceil(value / step - 1.0e-9) * step)

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
