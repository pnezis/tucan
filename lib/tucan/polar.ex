defmodule Tucan.Polar do
  @moduledoc """
  Plots in polar coordinates.

  > #### Experimental {: .error}
  >
  > This API is experimental and may change. `VegaLite` does not support polar
  > coordinates for lines and points, so the polar data are converted to cartesian
  > coordinates and the polar grid is drawn manually as extra layers. As a result
  > polar plots are layered plots and helpers like `Tucan.Axes`, `Tucan.Grid` or
  > `Tucan.Scale` do not apply to them.

  ## Coordinates

  Each data point is defined by a radius `r` and an angle `theta`:

  * By default angles are in degrees. Set `angle_unit: :radians` if your data are
  in radians.
  * An angle of `0` points to the right (east) and angles increase counter clockwise.
  Use the `:direction` option to reverse the direction and the `:angle_offset` option
  to rotate the plot.
  * Negative radius values are drawn on the opposite side of the origin.

  ## The polar grid

  The grid consists of circles at the radius ticks and lines from the origin at the
  angle marks. The outer circle is drawn at the maximum radius, which is set:

  * explicitly with the `:max_radius` option, or
  * to the largest of the `:radius_ticks`, if set, or
  * from the data, rounded up to a round number. This is possible only if the data
  are passed inline and not as a URL or a dataset name. In this case you must set
  either `:max_radius` or `:radius_ticks`.

  Polar plots are always square. Use the `:width` option to set their size.
  """

  alias VegaLite, as: Vl

  @polar_opts [
    max_radius: [
      type: {:custom, Tucan.Options, :positive_number, []},
      type_doc: "`t:number/0`",
      doc: """
      The radius of the outer grid circle. If not set it is the largest radius tick,
      or if these are not set either it is inferred from the data.
      """
    ],
    radius_ticks: [
      type: {:list, {:custom, Tucan.Options, :positive_number, []}},
      type_doc: "list of `t:number/0`",
      doc: """
      The radiuses at which grid circles are drawn. If not set they are derived from
      the maximum radius.
      """
    ],
    angle_marks: [
      type: {:list, {:or, [:integer, :float]}},
      type_doc: "list of `t:number/0`",
      default: [0, 45, 90, 135, 180, 225, 270, 315],
      doc: """
      The angles in degrees at which grid lines from the origin are drawn. Always in
      degrees, regardless of the `:angle_unit`.
      """
    ],
    angle_unit: [
      type: {:in, [:degrees, :radians]},
      default: :degrees,
      doc: "The unit of the `theta` field values, one of `:degrees` or `:radians`."
    ],
    direction: [
      type: {:in, [:counter_clockwise, :clockwise]},
      default: :counter_clockwise,
      doc: "The direction in which angles increase."
    ],
    angle_offset: [
      type: {:or, [:integer, :float]},
      default: 0,
      doc: """
      Rotates the plot counter clockwise by the given angle in degrees. For example
      with `angle_offset: 90` an angle of `0` points up.
      """
    ],
    grid_color: [
      type: :string,
      default: "#dddddd",
      doc: "The color of the polar grid lines.",
      section: :style
    ],
    grid_opacity: [
      type: {:custom, Tucan.Options, :number_between, [0, 1]},
      type_doc: "`t:number/0`",
      default: 1,
      doc: "The opacity of the polar grid lines.",
      section: :style
    ],
    width: [
      type: :pos_integer,
      default: 300,
      doc: "The width and height of the plot in pixels.",
      section: :style
    ],
    title: [
      type: :string,
      doc: "The title of the plot.",
      section: :style
    ]
  ]

  lineplot_opts = [
    group_by: [
      type: :string,
      doc: "A field to group by the lines without affecting the style of it.",
      section: :grouping
    ],
    points: [
      type: :boolean,
      doc: "Whether points will be included in the chart.",
      default: false,
      section: :style
    ],
    point_color: [
      type: :string,
      doc: "The color of the points, if `:points` is set to `true`.",
      section: :style
    ],
    point_size: [
      type: :pos_integer,
      doc: "The size of the points, if `:points` is set to `true`.",
      section: :style
    ]
  ]

  @lineplot_opts Tucan.Options.take!(
                   [
                     :fill_opacity,
                     :tooltip,
                     :interpolate,
                     :tension,
                     :color_by,
                     :color,
                     :stroke_width,
                     :stroke_dash,
                     :line_color
                   ],
                   lineplot_opts ++ @polar_opts
                 )
  @lineplot_schema Tucan.Options.to_nimble_schema!(@lineplot_opts)

  @doc """
  Draws a line plot in polar coordinates.

  `r` is the field with the radius and `theta` the field with the angle of each
  point. The points are connected in increasing order of `theta`. Use a closed
  interpolation, e.g. `interpolate: "linear-closed"`, to connect the last point
  to the first one.

  See the module documentation for the coordinate conventions and the polar grid.

  ## Options

  #{Tucan.Options.docs(@lineplot_opts)}

  ## Examples

  An Archimedean spiral, where the radius grows linearly with the angle:

  ```tucan
  theta = Enum.to_list(0..720//5)
  r = Enum.map(theta, &(&1 / 360))

  Tucan.Polar.lineplot([r: r, theta: theta], "r", "theta")
  ```

  A rose with three petals. Negative radius values are drawn on the opposite side
  of the origin, so over a full turn each petal is traced twice:

  ```tucan
  theta = Enum.to_list(0..360)
  r = Enum.map(theta, fn t -> :math.cos(3 * t * :math.pi() / 180) end)

  Tucan.Polar.lineplot([r: r, theta: theta], "r", "theta", line_color: "purple")
  ```

  A radar chart comparing two players across six skills. The angle marks are set
  to the skills' angles and `"linear-closed"` closes each outline:

  ```tucan
  skills = ["Speed", "Shooting", "Passing", "Dribbling", "Defense", "Stamina"]

  data =
    for {player, scores} <- [
          {"Alice", [8, 6, 9, 7, 4, 8]},
          {"Bob", [5, 9, 6, 8, 7, 6]}
        ],
        {{skill, score}, i} <- Enum.with_index(Enum.zip(skills, scores)) do
      %{player: player, skill: skill, score: score, angle: i * 60}
    end

  Tucan.Polar.lineplot(data, "score", "angle",
    color_by: "player",
    interpolate: "linear-closed",
    points: true,
    max_radius: 10,
    angle_marks: [0, 60, 120, 180, 240, 300],
    angle_offset: 90,
    direction: :clockwise,
    tooltip: true
  )
  ```
  """
  @spec lineplot(
          plotdata :: Tucan.plotdata(),
          r :: String.t(),
          theta :: String.t(),
          opts :: keyword()
        ) :: VegaLite.t()
  def lineplot(plotdata, r, theta, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @lineplot_schema)

    mark_opts =
      Tucan.Options.take_options(opts, @lineplot_opts, :mark)
      |> maybe_add_point_opts(opts)
      |> Tucan.Keyword.put_not_nil(:color, opts[:line_color])

    layer =
      Vl.new()
      |> Vl.mark(:line, mark_opts)
      |> Vl.encode_field(:order, theta, type: :quantitative)
      |> maybe_encode_detail(opts[:group_by])
      |> maybe_encode_field(:color, opts[:color_by], opts, [])

    polar_plot(plotdata, r, theta, layer, opts)
  end

  defp maybe_add_point_opts(mark_opts, opts) do
    if opts[:points] do
      point_opts =
        []
        |> Tucan.Keyword.put_not_nil(:color, opts[:point_color])
        |> Tucan.Keyword.put_not_nil(:size, opts[:point_size])

      Keyword.put(mark_opts, :point, if(point_opts == [], do: true, else: point_opts))
    else
      mark_opts
    end
  end

  defp maybe_encode_detail(vl, nil), do: vl
  defp maybe_encode_detail(vl, field), do: Vl.encode_field(vl, :detail, field, type: :nominal)

  @scatter_opts Tucan.Options.take!(
                  [
                    :fill_opacity,
                    :tooltip,
                    :filled,
                    :color_by,
                    :shape_by,
                    :size_by,
                    :color,
                    :shape,
                    :size,
                    :point_color,
                    :point_size,
                    :point_shape
                  ],
                  @polar_opts
                )
  @scatter_schema Tucan.Options.to_nimble_schema!(@scatter_opts)

  @doc """
  Draws a scatter plot in polar coordinates.

  `r` is the field with the radius and `theta` the field with the angle of each
  point. Similarly to `Tucan.scatter/4` the points can be colored, shaped and sized
  by data fields.

  See the module documentation for the coordinate conventions and the polar grid.

  ## Options

  #{Tucan.Options.docs(@scatter_opts)}

  ## Examples

  Seeds of a sunflower head are placed at successive multiples of the golden angle,
  at a radius proportional to the square root of their index:

  ```tucan
  seeds = 1..300
  theta = Enum.map(seeds, &(&1 * 137.508))
  r = Enum.map(seeds, &:math.sqrt/1)

  Tucan.Polar.scatter([r: r, theta: theta], "r", "theta",
    point_color: "darkorange",
    point_size: 20,
    filled: true,
    angle_marks: []
  )
  ```

  Wind measurements, where the angle is the direction the wind blows from and the
  radius its speed. The angle offset and direction match the compass, with North
  on top and angles increasing clockwise:

  ```tucan
  data = [
    %{speed: 4.2, direction: 10, station: "A"},
    %{speed: 6.1, direction: 35, station: "A"},
    %{speed: 3.5, direction: 80, station: "A"},
    %{speed: 7.8, direction: 200, station: "A"},
    %{speed: 5.4, direction: 230, station: "A"},
    %{speed: 2.1, direction: 300, station: "B"},
    %{speed: 3.3, direction: 320, station: "B"},
    %{speed: 6.7, direction: 250, station: "B"},
    %{speed: 8.9, direction: 270, station: "B"},
    %{speed: 4.8, direction: 150, station: "B"}
  ]

  Tucan.Polar.scatter(data, "speed", "direction",
    color_by: "station",
    shape_by: "station",
    point_size: 80,
    angle_offset: 90,
    direction: :clockwise,
    tooltip: true
  )
  ```
  """
  @spec scatter(
          plotdata :: Tucan.plotdata(),
          r :: String.t(),
          theta :: String.t(),
          opts :: keyword()
        ) :: VegaLite.t()
  def scatter(plotdata, r, theta, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @scatter_schema)

    mark_opts =
      Tucan.Options.take_options(opts, @scatter_opts, :mark)
      |> Tucan.Keyword.put_not_nil(:color, opts[:point_color])
      |> Tucan.Keyword.put_not_nil(:shape, opts[:point_shape])
      |> Tucan.Keyword.put_not_nil(:size, opts[:point_size])

    layer =
      Vl.new()
      |> Vl.mark(:point, mark_opts)
      |> maybe_encode_field(:color, opts[:color_by], opts, type: :nominal)
      |> maybe_encode_field(:shape, opts[:shape_by], opts, type: :nominal)
      |> maybe_encode_field(:size, opts[:size_by], opts, type: :quantitative)

    polar_plot(plotdata, r, theta, layer, opts)
  end

  ## Polar plot construction

  # Builds a layered plot with the polar grid and the given data layer on top of it.
  # The data are set on the top level spec and inherited by the data layer.
  defp polar_plot(plotdata, r, theta, layer, opts) do
    width = opts[:width]

    vl =
      Tucan.new(plotdata, Keyword.take(opts, [:width, :title]))
      |> Vl.config(view: [stroke: nil])
      |> Tucan.Utils.put_in_spec(:height, width)

    grid = grid_config(vl, r, opts)

    layer =
      layer
      |> Vl.transform(calculate: angle_expr(theta, opts), as: "__polar_angle")
      |> Vl.transform(calculate: "#{to_number(r)} * cos(datum.__polar_angle)", as: "__polar_x")
      |> Vl.transform(calculate: "#{to_number(r)} * sin(datum.__polar_angle)", as: "__polar_y")
      |> encode_xy("__polar_x", "__polar_y", grid)
      |> maybe_encode_tooltip(r, theta, opts)

    Vl.layers(vl, grid_layers(grid, opts) ++ [layer])
  end

  defp angle_expr(theta, opts) do
    to_radians = if opts[:angle_unit] == :degrees, do: :math.pi() / 180, else: 1
    sign = if opts[:direction] == :clockwise, do: -1, else: 1

    "#{sign * to_radians} * #{to_number(theta)} + #{deg_to_rad(opts[:angle_offset])}"
  end

  defp to_number(field), do: "toNumber(datum[#{Jason.encode!(field)}])"

  defp encode_xy(vl, x, y, grid) do
    xy_opts = [
      type: :quantitative,
      scale: [domain: [-grid.max_radius, grid.max_radius], nice: false, zero: false],
      axis: nil
    ]

    vl
    |> Vl.encode_field(:x, x, xy_opts)
    |> Vl.encode_field(:y, y, xy_opts)
  end

  defp maybe_encode_field(vl, _channel, nil, _opts, _extra), do: vl

  defp maybe_encode_field(vl, channel, field, opts, extra),
    do: Tucan.Utils.encode_field(vl, channel, field, opts, extra)

  # The default tooltip would show the cartesian coordinates, instead we show the
  # polar coordinates and the grouping fields
  defp maybe_encode_tooltip(vl, r, theta, opts) do
    if opts[:tooltip] == true do
      fields =
        [
          [field: r, type: :quantitative],
          [field: theta, type: :quantitative]
        ] ++
          for {option, type} <- [
                color_by: :nominal,
                group_by: :nominal,
                shape_by: :nominal,
                size_by: :quantitative
              ],
              field = opts[option],
              field != nil do
            [field: field, type: type]
          end

      Vl.encode(vl, :tooltip, Enum.uniq_by(fields, & &1[:field]))
    else
      vl
    end
  end

  ## Grid

  defp grid_config(vl, r, opts) do
    {max_radius, radius_ticks} =
      case {opts[:max_radius], opts[:radius_ticks]} do
        {nil, nil} ->
          max_radius = infer_max_radius!(vl, r)
          {max_radius, ticks(max_radius)}

        {nil, ticks} ->
          {Enum.max(ticks), ticks}

        {max_radius, nil} ->
          {max_radius, ticks(max_radius)}

        {max_radius, ticks} ->
          {max_radius, ticks}
      end

    %{
      max_radius: max_radius,
      radius_ticks: radius_ticks,
      angle_marks: opts[:angle_marks],
      direction: opts[:direction],
      angle_offset: opts[:angle_offset]
    }
  end

  defp infer_max_radius!(vl, r) do
    case get_in(vl.spec, ["data", "values"]) do
      values when is_list(values) ->
        values
        |> Enum.map(&Map.get(&1, r))
        |> Enum.filter(&is_number/1)
        |> Enum.map(&abs/1)
        |> Enum.max(fn -> 0 end)
        |> nice_max()

      _other ->
        raise ArgumentError,
              "cannot infer the maximum radius of a polar plot if the data are not " <>
                "passed inline, set either the :max_radius or the :radius_ticks option"
    end
  end

  # Rounds up the maximum radius to a multiple of a round tick step
  defp nice_max(value) when value == 0, do: 1

  defp nice_max(value) do
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

  defp grid_layers(grid, opts) do
    style = [color: opts[:grid_color], opacity: opts[:grid_opacity]]
    xy = &encode_xy(&1, "x", "y", grid)

    [
      circles_layer(grid, style, xy),
      angle_lines_layer(grid, style, xy),
      angle_labels_layer(grid, opts, xy),
      radius_labels_layer(grid, xy)
    ]
  end

  defp circles_layer(grid, style, xy) do
    radiuses = Enum.uniq(grid.radius_ticks ++ [grid.max_radius])

    values =
      for r <- radiuses, i <- 0..180 do
        angle = deg_to_rad(i * 2)
        %{r: r, i: i, x: r * :math.cos(angle), y: r * :math.sin(angle)}
      end

    Vl.new()
    |> Vl.data_from_values(values)
    |> Vl.mark(:line, style ++ [stroke_width: 1])
    |> xy.()
    |> Vl.encode_field(:detail, "r", type: :nominal)
    |> Vl.encode_field(:order, "i", type: :quantitative)
  end

  defp angle_lines_layer(grid, style, xy) do
    values =
      for angle <- grid.angle_marks do
        {x, y} = grid_point(grid.max_radius, angle, grid)
        %{x: 0, y: 0, x2: x, y2: y}
      end

    Vl.new()
    |> Vl.data_from_values(values)
    |> Vl.mark(:rule, style ++ [stroke_width: 1])
    |> xy.()
    |> Vl.encode_field(:x2, "x2")
    |> Vl.encode_field(:y2, "y2")
  end

  # Angle labels are placed a fixed number of pixels outside of the outer circle
  @angle_labels_padding 16

  defp angle_labels_layer(grid, opts, xy) do
    label_radius = grid.max_radius * (1 + @angle_labels_padding / (opts[:width] / 2))

    values =
      for angle <- grid.angle_marks do
        {x, y} = grid_point(label_radius, angle, grid)
        %{x: x, y: y, label: "#{format_number(angle)}°"}
      end

    Vl.new()
    |> Vl.data_from_values(values)
    |> Vl.mark(:text, align: :center, baseline: :middle)
    |> xy.()
    |> Vl.encode_field(:text, "label")
  end

  # Radius labels are placed between the first two angle marks
  defp radius_labels_layer(grid, xy) do
    angle =
      case Enum.sort(grid.angle_marks) do
        [first, second | _rest] -> (first + second) / 2
        [first] -> first + 22.5
        [] -> 22.5
      end

    values =
      for r <- grid.radius_ticks do
        {x, y} = grid_point(r, angle, grid)
        %{x: x, y: y, label: format_number(r)}
      end

    Vl.new()
    |> Vl.data_from_values(values)
    |> Vl.mark(:text, align: :center, baseline: :middle, font_size: 10, opacity: 0.8)
    |> xy.()
    |> Vl.encode_field(:text, "label")
  end

  # The cartesian position of a grid element at the given radius and angle in degrees
  defp grid_point(r, angle, %{direction: direction, angle_offset: offset}) do
    sign = if direction == :clockwise, do: -1, else: 1
    phi = deg_to_rad(sign * angle + offset)

    {round_float(r * :math.cos(phi)), round_float(r * :math.sin(phi))}
  end

  defp format_number(value) when is_integer(value), do: Integer.to_string(value)

  defp format_number(value) do
    if value == Float.round(value), do: Integer.to_string(trunc(value)), else: to_string(value)
  end

  defp deg_to_rad(angle), do: angle * :math.pi() / 180
end
