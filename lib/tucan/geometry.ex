defmodule Tucan.Geometry do
  @moduledoc """
  An API for drawing common geometrical shapes.

  `Tucan.Geometry` offers an interface for rendering typical geometric forms, such as
  lines, circles, and polygons. Unlike the general Tucan API, these functions require
  only the parameters defining the respective geometric shapes, rather than a
  dataset and data fields.

  You can overlay tucan plots with geometrical shapes through the `Tucan.layers/2` function.

  ## Examples

  ```tucan
  Tucan.layers([
    Tucan.Geometry.circle({3, 3}, 4, line_color: "red", stroke_width: 3),
    Tucan.Geometry.rectangle({-2, 10}, {7, -3}, line_color: "green"),
    Tucan.Geometry.rectangle({-3.5, 0.1}, {8.1, -4.2},
      fill_color: "pink",
      fill_opacity: 0.3
    ),
    Tucan.Geometry.polyline([{1, 1}, {2, 7}, {5, 3}],
      closed: true,
      fill_color: "green",
      fill_opacity: 0.3
    )
  ])
  |> Tucan.Scale.set_xy_domain(-5, 11)
  |> Tucan.set_size(400, 400)
  |> Tucan.set_title("Tucan.Geometry examples")
  ```
  """
  alias VegaLite, as: Vl

  @typedoc "A cartesian point in the form `{x, y}`"
  @type point :: {number(), number()}

  line_opts = [
    stroke_width: [default: 1]
  ]

  @line_opts Tucan.Options.take!(
               [:stroke_width, :stroke_dash, :line_color, :opacity],
               line_opts
             )
  @line_schema Tucan.Options.to_nimble_schema!(@line_opts)

  @doc """
  Draws a line segment from the `start` to the `end` point.

  ## Options

  #{Tucan.Options.docs(@line_opts)}

  ## Examples

  ```tucan
  Tucan.layers([
    Tucan.Geometry.line({0, 0}, {10, 10}, stroke_dash: [5, 5]),
    Tucan.Geometry.line({0, 10}, {10, 0}, line_color: "red", stroke_width: 3)
  ])
  ```

  The identity line on top of a scatter plot:

  ```tucan
  data = for i <- 1..50, do: %{actual: i, predicted: i + 8 * :math.sin(i)}

  Tucan.layers([
    Tucan.scatter(data, "actual", "predicted"),
    Tucan.Geometry.line({0, 0}, {50, 50}, line_color: "gray", stroke_dash: [4, 4])
  ])
  ```
  """
  @spec line(start :: point(), end_point :: point(), opts :: keyword()) :: VegaLite.t()
  def line({x1, y1} = _start, {x2, y2} = _end, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @line_schema)

    mark_opts =
      opts
      |> Tucan.Options.take_options(@line_opts, :mark)
      |> Tucan.Keyword.put_not_nil(:color, opts[:line_color])

    segment(x1, y1, x2, y2, mark_opts)
  end

  defp segment(x1, y1, x2, y2, mark_opts) do
    # the positions are data values and not fields, so that the axis titles of the
    # plots the shape is added to are not affected
    Vl.new()
    |> Vl.data_from_values([%{}])
    |> Vl.mark(:rule, mark_opts)
    |> Vl.encode(:x, datum: x1, type: :quantitative)
    |> Vl.encode(:y, datum: y1, type: :quantitative)
    |> Vl.encode(:x2, datum: x2)
    |> Vl.encode(:y2, datum: y2)
  end

  arrow_opts = [
    stroke_width: [default: 2],
    line_color: [default: "black"],
    head_size: [
      type: :pos_integer,
      default: 60,
      doc: "The size of the arrow head.",
      section: :style
    ]
  ]

  @arrow_opts Tucan.Options.take!(
                [:stroke_width, :stroke_dash, :line_color, :opacity],
                arrow_opts
              )
  @arrow_schema Tucan.Options.to_nimble_schema!(@arrow_opts)

  @doc """
  Draws an arrow from the `start` to the `end` point.

  The arrow head points in the direction of the arrow on the screen, taking into
  account the scales of the plot.

  > #### Concatenated plots {: .warning}
  >
  > Inside concatenated plots, e.g. `Tucan.hconcat/2`, the scales of the plot cannot
  > be referenced and the direction of the head is computed in data units. It matches
  > the arrow only if the x and y axes have the same scale.

  ## Options

  #{Tucan.Options.docs(@arrow_opts)}

  ## Examples

  Pointing to a point of a scatter plot, with an annotation:

  ```tucan
  Tucan.scatter(:cars, "Horsepower", "Miles_per_Gallon")
  |> Tucan.Layers.append(Tucan.Geometry.arrow({180, 35}, {225, 16}, line_color: "red"))
  |> Tucan.annotate(180, 37, "The most powerful car", color: "red")
  ```

  Arrows in every direction:

  ```tucan
  arrows =
    for angle <- 0..330//30 do
      radians = angle * :math.pi() / 180
      Tucan.Geometry.arrow({0, 0}, {5 * :math.cos(radians), 5 * :math.sin(radians)})
    end

  Tucan.layers(arrows)
  |> Tucan.set_size(250, 250)
  ```
  """
  @spec arrow(start :: point(), end_point :: point(), opts :: keyword()) :: VegaLite.t()
  def arrow({x1, y1} = _start, {x2, y2} = _end, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @arrow_schema)

    mark_opts =
      opts
      |> Tucan.Options.take_options(@arrow_opts, :mark)
      |> Keyword.put(:color, opts[:line_color])

    # the angle of the head is computed on the screen, since the x and y scales
    # may differ, it is 0 for an arrow pointing up and increases clockwise. If a
    # scale has an empty domain, e.g. a single horizontal arrow, the screen angle
    # is not defined and the angle in data units is used instead
    screen_angle =
      "atan2(scale('x', #{x2}) - scale('x', #{x1}), scale('y', #{y1}) - scale('y', #{y2}))"

    data_angle = "atan2((#{x2}) - (#{x1}), (#{y2}) - (#{y1}))"

    angle = "(isFinite(#{screen_angle}) ? #{screen_angle} : #{data_angle}) * 180 / PI"

    head =
      Vl.new()
      |> Vl.data_from_values([%{}])
      |> Vl.mark(:point,
        shape: :triangle,
        filled: true,
        opacity: 1,
        size: opts[:head_size],
        color: opts[:line_color],
        angle: [expr: angle]
      )
      |> Vl.encode(:x, datum: x2, type: :quantitative)
      |> Vl.encode(:y, datum: y2, type: :quantitative)

    Vl.new()
    |> Vl.layers([segment(x1, y1, x2, y2, mark_opts), head])
  end

  circle_opts = [
    stroke_width: [default: 1]
  ]

  @circle_opts Tucan.Options.take!(
                 [
                   :stroke_width,
                   :stroke_dash,
                   :line_color,
                   :opacity,
                   :stroke_opacity,
                   :fill_color,
                   :fill_opacity
                 ],
                 circle_opts
               )
  @circle_schema Tucan.Options.to_nimble_schema!(@circle_opts)

  @doc """
  Draws a circle with the given `center` and `radius`.

  ## Options

  #{Tucan.Options.docs(@circle_opts)}

  ## Examples

  ```tucan
  Tucan.layers([
    Tucan.Geometry.circle({3, 2}, 5),
    Tucan.Geometry.circle({-1, 6}, 2, line_color: "red"),
    Tucan.Geometry.circle({0, 1}, 4, line_color: "green", stroke_width: 5)
  ])
  |> Tucan.Scale.set_x_domain(-5, 10)
  |> Tucan.Scale.set_y_domain(-5, 10)
  ```

  You can also draw filled circles by setting the `:fill_color` option. Opacity of the fill color and
  the stroke color can be configured by `:opacity` or independently by `:fill_opacity` and
  `:stroke_opacity`.

  ```tucan
  Tucan.layers([
    Tucan.Geometry.circle({3, 2}, 5, stroke_width: 3, stroke_opacity: 0.4),
    Tucan.Geometry.circle({-1, 6}, 2, line_color: "red", fill_color: "pink", opacity: 0.3),
    Tucan.Geometry.circle({0, 1}, 4, line_color: "green", stroke_width: 5, fill_color: "green", fill_opacity: 0.2)
  ])
  |> Tucan.Scale.set_x_domain(-5, 10)
  |> Tucan.Scale.set_y_domain(-5, 10)
  ```

  > #### Circles and plot dimensions {: .tip}
  >
  > Notice that the plot must be square with identical scale domains across
  > the two axes for the circle to appear circular. In a different case it will
  > look like an ellipsis.
  >
  > ```tucan
  > circle = Tucan.Geometry.circle({0, 0}, 1)
  >
  > Tucan.hconcat([
  >   circle
  >   |> Tucan.set_size(150, 150)
  >   |> Tucan.set_title("Square frame"),
  >   circle
  >   |> Tucan.Scale.set_x_domain(-2, 2)
  >   |> Tucan.Scale.set_y_domain(-1, 1)
  >   |> Tucan.set_size(150, 150)
  >   |> Tucan.set_title("Different domains"),
  >   circle
  >   |> Tucan.set_size(200, 150)
  >   |> Tucan.set_title("Different frame dimensions")
  > ])
  > ```
  """
  @spec circle(center :: point(), radius :: number(), opts :: keyword()) :: VegaLite.t()
  def circle({x, y} = _center, radius, opts \\ []) when is_number(radius) and radius > 0 do
    opts = NimbleOptions.validate!(opts, @circle_schema)

    mark_opts =
      opts
      |> Tucan.Options.take_options(@circle_opts, :mark)
      |> Tucan.Keyword.put_not_nil(:color, opts[:line_color])
      |> Tucan.Keyword.put_not_nil(:fill, opts[:fill_color])

    Vl.new()
    |> Vl.data(sequence: [start: 0, stop: 361, step: 1, as: "theta"])
    |> Vl.transform(calculate: "#{x} + cos(datum.theta*PI/180) * #{radius}", as: "x")
    |> Vl.transform(calculate: "#{y} + sin(datum.theta*PI/180) * #{radius}", as: "y")
    |> Vl.mark(:line, mark_opts)
    |> Vl.encode_field(:x, "x", type: :quantitative)
    |> Vl.encode_field(:y, "y", type: :quantitative)
    |> Vl.encode_field(:order, "theta")
  end

  ellipse_opts = [
    stroke_width: [default: 1]
  ]

  @ellipse_opts Tucan.Options.take!(
                  [
                    :stroke_width,
                    :stroke_dash,
                    :line_color,
                    :opacity,
                    :stroke_opacity,
                    :fill_color,
                    :fill_opacity
                  ],
                  ellipse_opts
                )
  @ellipse_schema Tucan.Options.to_nimble_schema!(@ellipse_opts)

  @doc """
  Draws an ellipse with the given `center`, `x_radius`, `y_radius`, and `rotation_angle`.

  `x_radius` is expected to be a positive number corresponding to the *major semi-axis* length, `y_radius`
  a positive number corresponding to the *minor semi-axis* length and `rotation_angle` the ellipse's
  rotation angle with respect to the *x-axis*.

  ## Options

  #{Tucan.Options.docs(@circle_opts)}

  ## Examples

  ```tucan
  Tucan.layers([
    Tucan.Geometry.ellipse({0, 0}, 5, 3, 0),
    Tucan.Geometry.ellipse({3, 4}, 5, 4, 45, line_color: "red"),
    Tucan.Geometry.ellipse({4, 1}, 7, 2, -30, line_color: "green", stroke_width: 2)
  ])
  |> Tucan.Scale.set_x_domain(-5, 10)
  |> Tucan.Scale.set_y_domain(-5, 10)
  ```
  """
  @spec ellipse(
          center :: point(),
          x_radius :: number(),
          y_radius :: number(),
          rotation_angle :: number(),
          opts :: keyword()
        ) :: VegaLite.t()
  def ellipse({x, y} = _radius, x_radius, y_radius, rotation_angle, opts \\ [])
      when is_number(x_radius) and is_number(y_radius) and is_number(rotation_angle) and
             x_radius > 0 and y_radius > 0 do
    opts = NimbleOptions.validate!(opts, @ellipse_schema)

    mark_opts =
      opts
      |> Tucan.Options.take_options(@ellipse_opts, :mark)
      |> Tucan.Keyword.put_not_nil(:color, opts[:line_color])
      |> Tucan.Keyword.put_not_nil(:fill, opts[:fill_color])

    Vl.new()
    |> Vl.data(sequence: [start: 0, stop: 361, step: 1, as: "theta"])
    |> Vl.transform(calculate: ellipse_x(x, x_radius, y_radius, rotation_angle), as: "x")
    |> Vl.transform(calculate: ellipse_y(y, x_radius, y_radius, rotation_angle), as: "y")
    |> Vl.mark(:line, mark_opts)
    |> Vl.encode_field(:x, "x", type: :quantitative)
    |> Vl.encode_field(:y, "y", type: :quantitative)
    |> Vl.encode_field(:order, "theta")
  end

  defp ellipse_x(x, x_radius, y_radius, angle) do
    "#{x} + cos(datum.theta*PI/180) * cos(#{angle}*PI/180) * #{x_radius} -" <>
      "sin(datum.theta*PI/180) * sin(#{angle}*PI/180) * #{y_radius}"
  end

  defp ellipse_y(y, x_radius, y_radius, angle) do
    "#{y} + cos(datum.theta*PI/180) * sin(#{angle}*PI/180) * #{x_radius} +" <>
      "sin(datum.theta*PI/180) * cos(#{angle}*PI/180) * #{y_radius}"
  end

  @doc """
  Draws a rectangle defined by the given `upper_left` and `bottom_right` points.

  ## Options

  See `polyline/2`

  ## Examples

  ```tucan
  Tucan.layers([
    Tucan.Geometry.rectangle({1, 5}, {5, 1}, line_color: "black", stroke_width: 2, stroke_dash: [5, 5]),
    Tucan.Geometry.rectangle({-2, 10}, {7, -3}, line_color: "green"),
    Tucan.Geometry.rectangle({-3.5, 0.1}, {8.1, -4.2}, fill_color: "pink", fill_opacity: 0.3)
  ])
  |> Tucan.Scale.set_xy_domain(-5, 11)
  |> Tucan.set_size(400, 300)
  ```
  """
  @spec rectangle(upper_left :: point(), bottom_right :: point(), opts :: keyword()) ::
          VegaLite.t()
  def rectangle({x1, y1} = _upper_left, {x2, y2} = _bottom_right, opts \\ []) do
    if x1 == x2 do
      raise ArgumentError, "the two points must have different x coordinates"
    end

    if y1 == y2 do
      raise ArgumentError, "the two points must have different y coordinates"
    end

    x_left = min(x1, x2)
    x_right = max(x1, x2)

    y_bottom = min(y1, y2)
    y_top = max(y1, y2)

    polyline(
      [{x_left, y_bottom}, {x_left, y_top}, {x_right, y_top}, {x_right, y_bottom}],
      Keyword.merge(opts, closed: true)
    )
  end

  polyline_opts = [
    stroke_width: [default: 1],
    closed: [
      type: :boolean,
      doc: "Whether a last segment will be added between the last and first points.",
      default: false
    ]
  ]

  @polyline_opts Tucan.Options.take!(
                   [
                     :stroke_width,
                     :stroke_dash,
                     :line_color,
                     :opacity,
                     :stroke_opacity,
                     :fill_color,
                     :fill_opacity
                   ],
                   polyline_opts
                 )
  @polyline_schema Tucan.Options.to_nimble_schema!(@polyline_opts)

  @doc """
  Draws a polyline defined by the given vertices.

  The order of the vertices defines the order of the line segments that
  will be generated.

  The polyline or polygon will be added as a new layer to the given plot `vl`.

  ## Options

  #{Tucan.Options.docs(@polyline_opts)}

  ## Examples

  ```tucan
  Tucan.Geometry.polyline([{-1, 1}, {-2, 4}, {-1, 3}, {4, 7}, {8, 2}])
  |> Tucan.Scale.set_x_domain(-3, 10)
  |> Tucan.Scale.set_y_domain(-1, 9)
  ```

  If `:closed` is set to `true` a line segment is added between the last and
  first point.

  ```tucan
  Tucan.Geometry.polyline([{-1, 1}, {-2, 4}, {-1, 3}, {4, 7}, {8, 2}], closed: true)
  |> Tucan.Scale.set_x_domain(-3, 10)
  |> Tucan.Scale.set_y_domain(-1, 9)
  ```

  You can change the appearance of the polyline/polygon.

  ```tucan
  points = [{-1, 1}, {-2, 4}, {-1, 3}, {4, 7}, {8, 2}]

  Tucan.Geometry.polyline(points,
    closed: true,
    fill_color: "red",
    line_color: "green",
    fill_opacity: 0.3,
    stroke_width: 3,
    stroke_dash: [5, 3]
  )
  |> Tucan.Scale.set_x_domain(-3, 10)
  |> Tucan.Scale.set_y_domain(-1, 9)
  ```
  """
  @spec polyline(vertices :: [point()], opts :: keyword()) :: VegaLite.t()
  def polyline(vertices, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @polyline_schema)

    mark_opts =
      opts
      |> Tucan.Options.take_options(@polyline_opts, :mark)
      |> Tucan.Keyword.put_not_nil(:color, opts[:line_color])
      |> Tucan.Keyword.put_not_nil(:fill, opts[:fill_color])

    vertices =
      if opts[:closed] do
        vertices ++ [Enum.at(vertices, 0)]
      else
        vertices
      end

    {xs, ys} = Enum.reduce(vertices, {[], []}, fn {x, y}, {xs, ys} -> {[x | xs], [y | ys]} end)

    Vl.new()
    |> Vl.data_from_values(%{
      x: Enum.reverse(xs),
      y: Enum.reverse(ys),
      order: 0..length(vertices)
    })
    |> Vl.mark(:line, mark_opts)
    |> Vl.encode_field(:x, "x", type: :quantitative)
    |> Vl.encode_field(:y, "y", type: :quantitative)
    |> Vl.encode_field(:order, "order")
  end

  regular_polygon_opts = [
    rotation: [
      type: {:or, [:integer, :float]},
      default: 0,
      doc: """
      The rotation of the polygon in degrees, counter clockwise. With `0` the first
      vertex points up.
      """
    ]
  ]

  @regular_polygon_opts Tucan.Options.take!(
                          [
                            :stroke_width,
                            :stroke_dash,
                            :line_color,
                            :opacity,
                            :stroke_opacity,
                            :fill_color,
                            :fill_opacity
                          ],
                          regular_polygon_opts ++ [stroke_width: [default: 1]]
                        )
  @regular_polygon_schema Tucan.Options.to_nimble_schema!(@regular_polygon_opts)

  @doc """
  Draws a regular polygon with the given number of `sides`, whose vertices are on a
  circle with the given `center` and `radius`.

  ## Options

  #{Tucan.Options.docs(@regular_polygon_opts)}

  ## Examples

  ```tucan
  Tucan.layers([
    Tucan.Geometry.regular_polygon({0, 0}, 1, 3, fill_color: "orange", fill_opacity: 0.4),
    Tucan.Geometry.regular_polygon({3, 0}, 1, 4, rotation: 45, line_color: "red"),
    Tucan.Geometry.regular_polygon({6, 0}, 1, 6, fill_color: "teal", stroke_width: 2)
  ])
  |> Tucan.Scale.set_x_domain(-1.5, 7.5)
  |> Tucan.Scale.set_y_domain(-1.5, 1.5)
  |> Tucan.set_size(360, 120)
  ```
  """
  @spec regular_polygon(
          center :: point(),
          radius :: number(),
          sides :: pos_integer(),
          opts :: keyword()
        ) :: VegaLite.t()
  def regular_polygon({x, y} = _center, radius, sides, opts \\ [])
      when is_number(radius) and radius > 0 and is_integer(sides) and sides >= 3 do
    opts = NimbleOptions.validate!(opts, @regular_polygon_schema)

    vertices =
      for i <- 0..(sides - 1) do
        angle = (90 + opts[:rotation] + i * 360 / sides) * :math.pi() / 180
        {x + radius * :math.cos(angle), y + radius * :math.sin(angle)}
      end

    polyline(vertices, Keyword.put(Keyword.delete(opts, :rotation), :closed, true))
  end
end
