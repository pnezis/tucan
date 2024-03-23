defmodule Tucan.Polar do
  @moduledoc """
  Polar plots.

  > #### Experimental {: .error}
  >
  > Notice that this API is experimental. `VegaLite` does not provide polar
  > projections so we create the polar grid manually. As a result the rest
  > of the `Tucan` functions may not work as expected combined with a polar
  > plot.

  TODO: fill this up
  """
  alias VegaLite, as: Vl

  polar_grid_options = [
    angle_marks: [
      type: {:list, {:custom, Tucan.Options, :positive_number, []}},
      default: [0, 90, 180, 270],
      doc: "The angles in degrees for which an angle line will be drawn.",
      dest: :polar_grid
    ],
    direction: [
      type: {:in, [:clockwise, :counter_clockwise]},
      default: :counter_clockwise,
      doc: "The polar plot direction.",
      dest: :polar_grid
    ],
    radius_ticks: [
      type: {:list, {:custom, Tucan.Options, :positive_number, []}},
      doc: "A list of radiuses for which polar grid lines will be plotted.",
      dest: :polar_grid
    ],
    max_radius: [
      type: {:custom, Tucan.Options, :positive_number, []},
      doc: "If set determines the maximum radius of the polar grid.",
      default: 1,
      dest: :polar_grid
    ]
  ]

  @polar_grid_schema Tucan.Options.to_nimble_schema!(polar_grid_options)


  @doc """
  Creates a new polar plot.

  > #### `Tucan` interoperability {: .warning}
  >
  > A polar plot is a special plot with a custom grid. Notice that
  > the rest `Tucan` modules, like `Tucan.Grid`, `Tucan.Axes` etc. may
  > not be compatible with polar plots.

  ## Options

  #{NimbleOptions.docs(@polar_grid_schema)}

  ## Examples

  The default polar grid:

  ```tucan
  Tucan.Polar.new()
  ```

  You can specify more angle marks if needed:

  ```tucan
  Tucan.Polar.new(angle_marks: [0, 15, 30, 45, 60, 90, 180, 270])
  ```

  > #### Max radius {: .info}
  >
  > By default the max radius is set to 1. You can define a different max radius
  > if needed. Notice that currently the scale of your data does not affect the
  > max radius and **you have to manually set it** in order to make the grid
  > dimensions match the plot data.
  >
  > ```tucan
  > Tucan.Polar.new(
  >   max_radius: 20,
  >   angle_marks: [0, 15, 30, 45, 60, 90, 180, 270]
  > )
  > ```
  >
  > Additionally you can enable more radius ticks. In this case the max radius is
  > implicitly set to the maximum tick.
  > 
  > ```tucan
  > Tucan.Polar.new(
  >   radius_ticks: [5, 10, 15, 20],
  >   angle_marks: [0, 15, 30, 45, 60, 90, 180, 270]
  > )
  > ```

  By default polar plots grids have a counter clockwise direction. You can change
  it through the `:direction` option:

  ```tucan
  Tucan.Polar.new(radius_ticks: [0, 5, 10, 15], direction: :clockwise)
  ```
  """

  def new(opts \\ []) do
    # TODO: remove from opts, color, stroke_color stroke_opacity etc
    # instead we should make it compatible with the rest of Tucan,
    # e.g. you should be able to modify it through Grid, View helpers
    opts = NimbleOptions.validate!(opts, @polar_grid_schema)

    opts =
      opts
      |> Keyword.put(:color, "white")
      |> Keyword.put(:opacity, 1)
      |> Keyword.put(:stroke_opacity, 1)
      |> Keyword.put(:stroke_color, :light_gray)

    # Notice that a polar plot base specification is a layered vega lite plot
    # where the first layer is the grid.
    # the grid is a nested layered specification containing all grid objects
    # this way we can easily separate grid from plot layers.
    Vl.layers(
      # TODO: remove once we properly pass data
      Vl.new() |> Vl.data_from_values(%{"_r" => [0]}),
      [grid(opts)]
    )
  end

  defp grid(opts) do
    angle_layers = grid_angle_layers(opts)
    radius_layers = grid_radius_layers(opts)

    Vl.layers(Vl.new(), angle_layers ++ radius_layers)
  end

  defp grid_angle_layers(opts) do
    angle_marks_input = opts[:angle_marks]

    {angle_marks, angle_marks2} =
      case opts[:direction] do
        :clockwise ->
          angle_marks = [0 | Enum.sort(angle_marks_input)]
          angle_marks2 = tl(angle_marks) ++ [360]

          {angle_marks, angle_marks2}

        :counter_clockwise ->
          angle_marks = [360 | Enum.sort(angle_marks_input, :desc)]
          angle_marks2 = tl(angle_marks) ++ [0]

          {Enum.map(angle_marks, &(-&1)), Enum.map(angle_marks2, &(-&1))}
      end

    has_zero = 0 in angle_marks_input

    angle_offset = 90

    [angle_marks, angle_marks2]
    |> Enum.zip_with(fn [t, t2] ->
      is_360 = :math.fmod(t, 360) == 0

      label =
        if (t != 0 and not is_360) or (t == 0 and has_zero) or
             (is_360 and not has_zero) do
          Vl.new()
          |> Vl.mark(:text,
            text: to_string(abs(t)) <> "º",
            theta: "#{deg_to_rad(t + angle_offset)}",
            radius: [expr: "min(width, height) * 0.55"]
          )
        else
          []
        end

      theta = deg_to_rad(t + angle_offset)
      theta2 = deg_to_rad(t2 + angle_offset)

      [
        Vl.new()
        |> Vl.mark(:arc,
          theta: "#{theta}",
          theta2: "#{theta2}",
          stroke: opts[:stroke_color],
          stroke_opacity: opts[:stroke_opacity],
          opacity: opts[:opacity],
          color: opts[:color]
        ),
        label
      ]
    end)
    |> List.flatten()
  end

  defp grid_radius_layers(opts) do
    radius_marks = opts[:radius_ticks] || [0, opts[:max_radius]]
    max_radius = Enum.max(radius_marks)

    radius_marks_vl =
      Enum.map(radius_marks, fn r ->
        Vl.mark(Vl.new(), :arc,
          radius: [expr: "#{r / max_radius} * min(width, height)/2"],
          radius2: [expr: "#{r / max_radius} * min(width, height)/2 + 1"],
          theta: "0",
          theta2: "#{2 * :math.pi()}",
          stroke_color: opts[:stroke_color],
          color: opts[:stroke_color],
          opacity: opts[:stroke_opacity]
        )
      end)

    radius_ruler_vl = [
      Vl.new()
      |> Vl.data_from_values(%{
        r: radius_marks,
        theta: Enum.map(radius_marks, fn _ -> :math.pi() / 4 end)
      })
      |> Vl.mark(:text,
        color: "black",
        radius: [expr: "datum.r  * min(width, height) / (2 * #{max_radius})"],
        theta: :math.pi() / 2,
        dy: 10,
        dx: -10
      )
      |> Vl.encode_field(:text, "r", type: :quantitative)
    ]

    radius_marks_vl ++ radius_ruler_vl
  end

  @doc """
  Plots a line plot in polar coordinates

  ## Examples

  ```tucan
  data = [
    r: [1, 2, 3, 3, 4],
    theta: [0, 30, 45, 135, 270]
  ]

  Tucan.Polar.lineplot(data, "r", "theta", [x: [], y: []])
  ```

  ```tucan
  r = Nx.linspace(0, 2, n: 200)
  theta = Nx.multiply(r, 2 * 180)

  Tucan.Polar.lineplot([r: r, theta: theta], "r", "theta", [x: [], y: []])
  ```

  ```tucan
  theta = Nx.linspace(0, 2 * 180, n: 1000)
  r = Nx.cos(Nx.multiply(theta, 6))

  Tucan.Polar.lineplot([r: r, theta: theta], "r", "theta", [x: [], y: []])
  ```
  """

  def lineplot(data, r, theta, opts) do
    # TODO: ensure data is a polar plot

    pi = :math.pi()

    y_sign = if opts[:direction] == :clockwise, do: "-", else: "+"

    xy_opts = [
      type: :quantitative,
      scale: [
        domain: [-2, 2] # TODO: get from base grod
      ],
      axis: [
        grid: false,
        ticks: false,
        domain_opacity: 0,
        labels: false,
        title: nil,
        domain: false,
        offset: 50
      ]
    ]

    line_layer =
      Tucan.new(data, opts)
      |> Vl.transform(calculate: "datum.#{r} * cos(datum.#{theta} * #{pi / 180})", as: "x")
      |> Vl.transform(
        calculate: "datum.#{r} * sin(#{y_sign}datum.#{theta} * #{pi / 180})",
        as: "y"
      )
      |> Vl.mark(:line, interpolate: :cardinal)
      |> Tucan.Utils.encode_field(:x, "x", opts, xy_opts)
      |> Tucan.Utils.encode_field(:y, "y", opts, xy_opts)
      |> Tucan.Utils.maybe_encode_field(
        :color,
        fn -> opts[:color_by] != nil end,
        opts[:color_by],
        opts,
        []
      )
      |> Tucan.Utils.maybe_encode_field(
        :detail,
        fn -> opts[:group_by] != nil end,
        opts[:group_by],
        [detail: []],
        type: :nominal
      )
      |> Vl.encode_field(:order, theta)

    Tucan.Layers.append(
      new(
        max_radius: 2,
        radius_ticks: [0.5, 1, 1.5, 2],
        angle_marks: [0, 15, 30, 45, 60, 90, 180, 270]
      ),
      line_layer
    )
  end

  defp deg_to_rad(angle), do: angle * :math.pi() / 180
end
