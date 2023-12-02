defmodule Tucan.Geometry do
  @moduledoc """
  Helper geometrical plots.
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
  Tucan.new()
  |> Tucan.circle({3, 2}, 5)
  |> Tucan.circle({-1, 6}, 2, line_color: "red")
  |> Tucan.circle({0, 1}, 4, line_color: "green", stroke_width: 5)
  |> Tucan.Scale.set_x_domain(-5, 10)
  |> Tucan.Scale.set_y_domain(-5, 10)
  ```

  You can also draw filled circles by setting the `:fill_color` option. Opacity of the fill color and
  the stroke color can be configured by `:opacity` or independently by `:fill_opacity` and
  `:stroke_opacity`.

  ```tucan
  Tucan.new()
  |> Tucan.circle({3, 2}, 5, stroke_width: 3, stroke_opacity: 0.4)
  |> Tucan.circle({-1, 6}, 2, line_color: "red", fill_color: "pink", opacity: 0.3)
  |> Tucan.circle({0, 1}, 4, line_color: "green", stroke_width: 5, fill_color: "green", fill_opacity: 0.2)
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
  > circle = Tucan.circle(Tucan.new(), {0, 0}, 1)
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
  @spec circle(vl :: VegaLite.t(), center :: point(), radius :: number(), opts :: keyword()) ::
          VegaLite.t()
  def circle(vl, {x, y}, radius, opts \\ [])
      when is_struct(vl, VegaLite) and is_number(radius) and radius > 0 do
    opts = NimbleOptions.validate!(opts, @circle_schema)

    mark_opts =
      opts
      |> take_options(@circle_opts, :mark)
      |> Tucan.Keyword.put_not_nil(:color, opts[:line_color])
      |> Tucan.Keyword.put_not_nil(:fill, opts[:fill_color])

    circle =
      Vl.new()
      |> Vl.data(sequence: [start: 0, stop: 361, step: 0.1, as: "theta"])
      |> Vl.transform(calculate: "#{x} + cos(datum.theta*PI/180) * #{radius}", as: "x")
      |> Vl.transform(calculate: "#{y} + sin(datum.theta*PI/180) * #{radius}", as: "y")
      |> Vl.mark(:line, mark_opts)
      |> Vl.encode_field(:x, "x", type: :quantitative)
      |> Vl.encode_field(:y, "y", type: :quantitative)
      |> Vl.encode_field(:order, "theta")

    Tucan.Layers.append(vl, circle)
  end

  # TODO move in helper, used in Tucan as well
  defp take_options(opts, schema, dest) do
    dest_opts =
      schema
      |> Enum.filter(fn {_key, opts} ->
        opts[:dest] == dest
      end)
      |> Keyword.keys()

    Keyword.take(opts, dest_opts)
  end
end
