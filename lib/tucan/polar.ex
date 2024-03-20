defmodule Tucan.Polar do
  @moduledoc """
  Polar plots.

  TODO: fill this up
  """
  alias VegaLite, as: Vl

  @doc """
  Creates a new polar plot.

  > #### `Tucan` interoperability {: .warning}
  >
  > A polar plot is a special plot with a custom grid. Notice that
  > the rest `Tucan` modules, like `Tucan.Grid`, `Tucan.Axes` etc. may
  > not be compatible with polar plots.

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
  >   radius_max: 20,
  >   angle_marks: [0, 15, 30, 45, 60, 90, 180, 270]
  > )
  > ```
  >
  > Additionally you can enable more radius ticks:
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
    opts =
      Keyword.validate!(
        opts,
        angle_marks: [0, 90, 180, 270, 360],
        direction: :counter_clockwise,
        radius_max: 1,
        angle_offset: 0,
        opacity: 1,
        color: "white",
        stroke_color: "black",
        stroke_opacity: 1,
        radius_ticks: nil
      )

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

    grid = Vl.layers(Vl.new(), angle_layers ++ radius_layers)
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
    radius_marks = opts[:radius_ticks] || [0, opts[:radius_max]]
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
        color: opts[:stroke_color],
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

  ```
  Tucan.Polar.lineplot()
  ```
  """
  def lineplot(data, r, theta, opts) do
    # TODO: ensure data is a polar plot



  end

  defp deg_to_rad(angle), do: angle * :math.pi() / 180
end
