defmodule Tucan.Geometry do
  @moduledoc """
  An API for drawing common geometrical shapes.

  `Tucan.Geometry` provides an API for drawing common geometrical shapes. These among other include
  lines, circles and polygons. In contrary to the `Tucan` common API, these functions instead of a
  dataset, expect the that define the underlying geometrical shapes.

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

  The circle will be added as a new layer to the given plot `vl`.

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
  def circle({x, y}, radius, opts \\ []) when is_number(radius) and radius > 0 do
    opts = NimbleOptions.validate!(opts, @circle_schema)

    mark_opts =
      opts
      |> Tucan.Options.take_options(@circle_opts, :mark)
      |> Tucan.Keyword.put_not_nil(:color, opts[:line_color])
      |> Tucan.Keyword.put_not_nil(:fill, opts[:fill_color])

    Vl.new()
    |> Vl.data(sequence: [start: 0, stop: 361, step: 0.1, as: "theta"])
    |> Vl.transform(calculate: "#{x} + cos(datum.theta*PI/180) * #{radius}", as: "x")
    |> Vl.transform(calculate: "#{y} + sin(datum.theta*PI/180) * #{radius}", as: "y")
    |> Vl.mark(:line, mark_opts)
    |> Vl.encode_field(:x, "x", type: :quantitative)
    |> Vl.encode_field(:y, "y", type: :quantitative)
    |> Vl.encode_field(:order, "theta")
  end

  @doc """
  Draws a rectangle defined by the given `upper_left` and `bottom_right` points.

  ## Options

  See `polyline/3`

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
  @spec rectangle(point1 :: point(), point2 :: point(), opts :: keyword()) :: VegaLite.t()
  def rectangle({x1, y1}, {x2, y2}, opts \\ []) do
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
end
