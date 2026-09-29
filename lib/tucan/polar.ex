defmodule Tucan.Polar do
  @moduledoc """
  Plots in polar coordinates.

  The following plots are supported:

  * `lineplot/4`, `scatter/4` and `area/4` for lines, points and filled areas.
  * `radar/4` for comparing the values of several categories.
  * `bar/4`, `histogram/3` and `windrose/4` for circular sectors per category, per
  angle bin, or per direction and speed.
  * `heatmap/5` for cells binned by angle and radius.

  > #### Experimental {: .error}
  >
  > This API is experimental and may change. `VegaLite` does not support polar
  > coordinates for lines and points, so the polar data are converted to cartesian
  > coordinates, while circular sectors are drawn as arc marks. The polar grid is
  > drawn manually as extra layers. As a result polar plots are layered plots and
  > helpers like `Tucan.Axes`, `Tucan.Grid` or `Tucan.Scale` do not apply to them.

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

  ## Cyclic data

  Polar plots are well suited for cyclic data, like the hours of a day or the days
  of a year, since the end of a period is next to its start. With the `:period`
  option a full turn corresponds to the given period. By default the plot then
  looks like a clock, starting at the top and going clockwise, and the angle marks
  are labeled with the period's divisions.

  Daily temperatures of two cities over a year, where the `theta` field is a date:

  ```tucan
  data =
    for {city, mean, amplitude} <- [{"Dublin", 10, 5}, {"Madrid", 16, 10}],
        date <- Date.range(~D[2024-01-01], ~D[2024-12-31]) do
      day = Date.day_of_year(date)
      wiggle = :math.sin(day / 3) + 0.6 * :math.sin(day / 1.7)
      temp = mean - amplitude * :math.cos(2 * :math.pi() * (day - 20) / 366) + wiggle

      %{city: city, date: date, temp: temp}
    end

  Tucan.Polar.lineplot(data, "temp", "date", period: :year, color_by: "city")
  ```

  With a numeric period the `theta` field is a number, e.g. the hour of the day
  with a period of `24`. Notice that the hour `24` is the same as the hour `0`:

  ```tucan
  demand = [30, 26, 24, 23, 24, 28, 38, 52, 60, 58, 55, 54,
            56, 55, 53, 54, 60, 72, 80, 78, 70, 58, 45, 36]

  data = Enum.with_index(demand, fn value, hour -> %{hour: hour, demand: value} end)

  Tucan.Polar.area(data, "demand", "hour",
    period: 24,
    fill_color: "orange",
    line_color: "darkorange",
    tooltip: true
  )
  ```
  """

  alias Tucan.Polar.Grid
  alias VegaLite, as: Vl

  @temporal_periods [:day, :week, :year]

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
      doc: """
      The angles in degrees at which grid lines from the origin are drawn. Always in
      degrees, regardless of the `:angle_unit` and the `:period`. Defaults to every
      45 degrees, or to the period's divisions if `:period` is set.
      """
    ],
    angle_labels: [
      type: {:or, [{:in, [:degrees, :compass, :none]}, {:list, :string}]},
      type_doc: "`t:atom/0` or list of `t:String.t/0`",
      doc: """
      The labels of the angle marks. Defaults to `:degrees`, or to the period's
      divisions if `:period` is set and `:angle_marks` is not. One of:

      * `:degrees` - the angle in degrees, e.g. `"45°"`.
      * `:compass` - the compass point of the angle, e.g. `"NE"`, for multiples of
      22.5 degrees. The angles are treated as compass bearings, so you should usually
      also set `direction: :clockwise` and `angle_offset: 90`.
      * `:none` - no labels.
      * a list of strings, one for each angle mark.
      """
    ],
    angle_unit: [
      type: {:in, [:degrees, :radians]},
      default: :degrees,
      doc: """
      The unit of the `theta` field values, one of `:degrees` or `:radians`. Ignored
      if `:period` is set.
      """
    ],
    period: [
      type: {:or, [{:in, [:day, :week, :year]}, {:custom, Tucan.Options, :positive_number, []}]},
      type_doc: "`t:atom/0` or `t:number/0`",
      doc: """
      Plots cyclic data, where a full turn corresponds to the given period. One of:

      * `:day`, `:week` or `:year` - the `theta` field is a date or datetime and a
      full turn corresponds to a day, a week starting on Monday, or a year.
      * a number - the `theta` field is a number and a full turn corresponds to the
      given value, e.g. `24` for the hours of a day.

      See the "Cyclic data" section of the module documentation for more details.
      """
    ],
    direction: [
      type: {:in, [:counter_clockwise, :clockwise]},
      doc: """
      The direction in which angles increase. Defaults to `:counter_clockwise`, or to
      `:clockwise` if `:period` is set.
      """
    ],
    angle_offset: [
      type: {:or, [:integer, :float]},
      doc: """
      Rotates the plot counter clockwise by the given angle in degrees. For example
      with `angle_offset: 90` an angle of `0` points up. Defaults to `0`, or to `90`
      if `:period` is set.
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

  For radar charts see `radar/4`.
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
      |> Vl.encode_field(:order, theta, type: theta_type(opts))
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
  on top and angles increasing clockwise, and the angle marks are labeled with the
  compass points:

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
    angle_labels: :compass,
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

  area_opts = [
    group_by: [
      type: :string,
      doc: "A field to group by the areas without affecting the style of it.",
      section: :grouping
    ],
    interpolate: [default: "linear-closed"],
    fill_opacity: [default: 0.5]
  ]

  @area_opts Tucan.Options.take!(
               [
                 :fill_opacity,
                 :tooltip,
                 :interpolate,
                 :tension,
                 :color_by,
                 :color,
                 :fill_color,
                 :line_color,
                 :stroke_width,
                 :stroke_dash
               ],
               area_opts ++ @polar_opts
             )
  @area_schema Tucan.Options.to_nimble_schema!(@area_opts)

  @doc """
  Draws a filled area in polar coordinates.

  `r` is the field with the radius and `theta` the field with the angle of each
  point. The points are connected in increasing order of `theta` and the shape is
  closed by connecting the last point to the first one. To fill the area between a
  curve and the origin, include a point with a zero radius at the start or the end
  of the curve.

  The areas are not outlined by default, set `:line_color` to draw an outline.

  See the module documentation for the coordinate conventions and the polar grid.

  ## Options

  #{Tucan.Options.docs(@area_opts)}

  ## Examples

  A cardioid, drawn with an outline:

  ```tucan
  theta = Enum.to_list(0..355//5)
  r = Enum.map(theta, fn t -> 1 + :math.cos(t * :math.pi() / 180) end)

  Tucan.Polar.area([r: r, theta: theta], "r", "theta",
    fill_color: "teal",
    line_color: "teal",
    stroke_width: 2
  )
  ```

  Two overlapping shapes colored by a field. With a smooth closed interpolation the
  few points of each shape are connected with curves:

  ```tucan
  data =
    for {shape, radiuses} <- [a: [5, 1, 5, 1, 5, 1], b: [1, 4, 1, 4, 1, 4]],
        {r, i} <- Enum.with_index(radiuses) do
      %{shape: shape, r: r, theta: i * 60}
    end

  Tucan.Polar.area(data, "r", "theta",
    color_by: "shape",
    interpolate: "cardinal-closed",
    angle_marks: [0, 60, 120, 180, 240, 300]
  )
  ```
  """
  @spec area(
          plotdata :: Tucan.plotdata(),
          r :: String.t(),
          theta :: String.t(),
          opts :: keyword()
        ) :: VegaLite.t()
  def area(plotdata, r, theta, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @area_schema)

    polar_plot(plotdata, r, theta, area_layer(theta, opts, @area_opts), opts)
  end

  defp area_layer(theta, opts, schema) do
    mark_opts =
      Tucan.Options.take_options(opts, schema, :mark)
      |> Keyword.put(:filled, true)
      |> Tucan.Keyword.put_not_nil(:color, opts[:fill_color])
      |> Tucan.Keyword.put_not_nil(:stroke, opts[:line_color])

    Vl.new()
    |> Vl.mark(:line, mark_opts)
    |> Vl.encode_field(:order, theta, type: theta_type(opts))
    |> maybe_encode_detail(opts[:group_by])
    # filled lines have no stroke, so the default line legend symbols would be empty
    |> maybe_encode_field(:color, opts[:color_by], opts, legend: [symbol_type: "square"])
  end

  categories_opt = [
    type: {:list, :string},
    doc: """
    The categories in the order they are drawn. If not set they are inferred from
    the data, in the order they first appear. This is possible only if the data are
    passed inline.
    """
  ]

  radar_opts = [
    categories: categories_opt,
    group_by: [
      type: :string,
      doc: "A field to group by the outlines without affecting the style of it.",
      section: :grouping
    ],
    filled: [
      type: :boolean,
      default: false,
      doc: "Whether the outlines will be filled.",
      section: :style
    ],
    fill_opacity: [
      default: 0.3,
      doc: "The opacity of the fill, if `:filled` is set."
    ],
    points: [
      type: :boolean,
      doc: "Whether points will be drawn at the values.",
      default: true,
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
    ],
    direction: [default: :clockwise],
    angle_offset: [default: 90]
  ]

  @radar_opts Tucan.Options.take!(
                [
                  :fill_opacity,
                  :tooltip,
                  :color_by,
                  :color,
                  :line_color,
                  :stroke_width,
                  :stroke_dash
                ],
                Tucan.Keyword.deep_merge(
                  Keyword.drop(@polar_opts, [:angle_marks, :angle_labels, :angle_unit, :period]),
                  radar_opts
                )
              )
  @radar_schema Tucan.Options.to_nimble_schema!(@radar_opts)

  @doc """
  Draws a radar chart.

  A radar chart, also known as a spider or star chart, compares the values of
  several categories. Each category has its own axis starting from the center and
  the values of each series are connected into a closed outline. The data must have
  one row per category and series, with the `value` of the category.

  The categories are placed at equal angles, starting at the top and going
  clockwise, and the grid lines are labeled with the category names.

  See the module documentation for more details on the polar grid.

  ## Options

  #{Tucan.Options.docs(@radar_opts)}

  ## Examples

  Two players compared across six skills:

  ```tucan
  data =
    for {player, scores} <- [
          {"Alice", [8, 6, 9, 7, 4, 8]},
          {"Bob", [5, 9, 6, 8, 7, 6]}
        ],
        {skill, score} <-
          Enum.zip(["Speed", "Shooting", "Passing", "Dribbling", "Defense", "Stamina"], scores) do
      %{player: player, skill: skill, score: score}
    end

  Tucan.Polar.radar(data, "score", "skill",
    color_by: "player",
    filled: true,
    max_radius: 10,
    tooltip: true
  )
  ```

  The monthly average temperatures of Seattle. The `:categories` option sets the
  order of the categories explicitly, which is required if the data are not passed
  inline:

  ```tucan
  months = ~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)

  data =
    Enum.zip_with(
      months,
      [5.5, 6.5, 8.4, 10.8, 14.4, 17.0, 19.9, 20.1, 17.2, 12.6, 8.2, 5.8],
      fn month, temp -> %{month: month, temp: temp} end
    )

  Tucan.Polar.radar(data, "temp", "month",
    categories: months,
    line_color: "firebrick",
    point_color: "firebrick",
    max_radius: 25,
    radius_ticks: [5, 10, 15, 20, 25]
  )
  ```
  """
  @spec radar(
          plotdata :: Tucan.plotdata(),
          value :: String.t(),
          category :: String.t(),
          opts :: keyword()
        ) :: VegaLite.t()
  def radar(plotdata, value, category, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @radar_schema)

    categories = opts[:categories] || infer_categories!(plotdata, category)
    step = 360 / max(length(categories), 1)
    angle_marks = for i <- 0..(length(categories) - 1)//1, do: i * step

    opts =
      Keyword.merge(opts,
        angle_marks: angle_marks,
        angle_labels: categories,
        angle_unit: :degrees
      )

    index = "indexof(#{Jason.encode!(categories)}, datum[#{Jason.encode!(category)}])"

    layers =
      for layer <- radar_layers(opts) do
        layer
        |> Vl.transform(filter: "#{index} >= 0")
        |> Vl.transform(calculate: "#{index} * #{step}", as: "__radar_angle")
      end

    polar_plot(plotdata, value, "__radar_angle", layers, opts, {category, :nominal})
  end

  defp infer_categories!(plotdata, category) do
    case inline_values(Tucan.new(plotdata), category) do
      nil ->
        raise ArgumentError,
              "cannot infer the categories of a radar chart if the data are not passed " <>
                "inline, set the :categories option"

      values ->
        values
        |> Enum.reject(&is_nil/1)
        |> Enum.map(&to_string/1)
        |> Enum.uniq()
    end
  end

  defp radar_layers(opts) do
    line_mark_opts =
      Tucan.Options.take_options(opts, @radar_opts, :mark)
      |> Keyword.drop([:fill_opacity])
      |> Keyword.put(:interpolate, "linear-closed")
      |> maybe_add_point_opts(opts)
      |> Tucan.Keyword.put_not_nil(:color, opts[:line_color])

    line_layer =
      Vl.new()
      |> Vl.mark(:line, line_mark_opts)
      |> Vl.encode_field(:order, "__radar_angle", type: :quantitative)
      |> maybe_encode_detail(opts[:group_by])
      |> maybe_encode_field(:color, opts[:color_by], opts, [])

    if opts[:filled] do
      fill_mark_opts =
        [
          filled: true,
          interpolate: "linear-closed",
          fill_opacity: opts[:fill_opacity]
        ]
        |> Tucan.Keyword.put_not_nil(:color, opts[:line_color])

      fill_layer =
        Vl.new()
        |> Vl.mark(:line, fill_mark_opts)
        |> Vl.encode_field(:order, "__radar_angle", type: :quantitative)
        |> maybe_encode_detail(opts[:group_by])
        |> maybe_encode_field(:color, opts[:color_by], opts, [])

      [fill_layer, line_layer]
    else
      [line_layer]
    end
  end

  bar_opts = [
    categories: categories_opt,
    aggregate: [
      type: {:in, [:sum, :count, :mean, :min, :max]},
      doc: """
      The statistic used for aggregating the values of each category, and of each
      `:color_by` group if set. If not set each row is drawn as is.
      """
    ],
    color_by: [
      doc: """
      If set a data field used for coloring the bars. The bars of each category are
      stacked outwards, in the order of the colors in the legend.
      """
    ],
    direction: [default: :clockwise],
    angle_offset: [default: 90]
  ]

  @bar_opts Tucan.Options.take!(
              [
                :fill_opacity,
                :tooltip,
                :color_by,
                :color,
                :fill_color,
                :line_color,
                :stroke_width
              ],
              Tucan.Keyword.deep_merge(
                Keyword.drop(@polar_opts, [:angle_marks, :angle_labels, :angle_unit, :period]),
                bar_opts
              )
            )
  @bar_schema Tucan.Options.to_nimble_schema!(@bar_opts)

  @doc """
  Draws a polar bar chart.

  Each category is drawn as a circular sector of the same angle and a radius equal
  to its `value`. This is also known as a Nightingale rose or coxcomb chart.
  Compared to `Tucan.radial/4`, where the angle of each wedge depends on its value,
  here the values are compared only through the radius.

  The categories are placed at equal angles, starting at the top and going
  clockwise. If `:color_by` is set, the bars are stacked.

  See the module documentation for more details on the polar grid.

  ## Options

  #{Tucan.Options.docs(@bar_opts)}

  ## Examples

  The monthly rainfall of a city:

  ```tucan
  months = ~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
  rainfall = [120, 95, 80, 60, 45, 30, 20, 25, 50, 90, 130, 140]

  data = Enum.zip_with(months, rainfall, fn month, mm -> %{month: month, rainfall: mm} end)

  Tucan.Polar.bar(data, "rainfall", "month",
    fill_color: "steelblue",
    line_color: "white",
    tooltip: true
  )
  ```

  Stacked bars, with the total yield of each barley variety, grouped by site:

  ```tucan
  Tucan.Polar.bar(:barley, "yield", "variety",
    color_by: "site",
    aggregate: :sum,
    categories: [
      "Manchuria", "Glabron", "Svansota", "Velvet", "Trebi",
      "No. 457", "No. 462", "Peatland", "No. 475", "Wisconsin No. 38"
    ],
    max_radius: 600,
    line_color: "white",
    width: 400
  )
  ```
  """
  @spec bar(
          plotdata :: Tucan.plotdata(),
          value :: String.t(),
          category :: String.t(),
          opts :: keyword()
        ) :: VegaLite.t()
  def bar(plotdata, value, category, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @bar_schema)

    categories = opts[:categories] || infer_categories!(plotdata, category)
    count = length(categories)
    step = 360 / max(count, 1)
    index = index_expr(categories, category)

    # the sectors are centered at the category angles, with grid lines at their
    # boundaries
    opts =
      Keyword.merge(opts,
        angle_marks: for(i <- 0..(count - 1)//1, do: i * step - step / 2),
        angle_labels: Enum.with_index(categories, fn category, i -> {i * step, category} end),
        radius_labels_angle: -step / 2
      )

    groupby = Enum.reject([category, opts[:color_by]], &is_nil/1)

    layer =
      Vl.new()
      |> Vl.transform(filter: "#{index} >= 0")
      |> aggregate_value(value, groupby, opts[:aggregate])
      |> Vl.transform(calculate: "#{index} * #{step} - #{step / 2}", as: "__start_angle")
      |> Vl.transform(calculate: "datum.__start_angle + #{step}", as: "__end_angle")
      |> stack_radius(category, opts[:color_by])

    tooltip = [
      [field: category, type: :nominal],
      [field: "__value", type: :quantitative, title: value_title(value, opts[:aggregate])]
    ]

    infer_max_radius = fn vl ->
      max_stacked_value(vl, value, category, categories, opts[:color_by], opts[:aggregate])
    end

    sectors_plot(plotdata, layer, opts, infer_max_radius, tooltip)
  end

  defp index_expr(categories, category) do
    "indexof(#{Jason.encode!(categories)}, datum[#{Jason.encode!(category)}])"
  end

  defp value_title(value, nil), do: value
  defp value_title(value, aggregate), do: "#{aggregate}(#{value})"

  # Sets the __value field, aggregated per group if needed
  defp aggregate_value(vl, value, _groupby, nil) do
    Vl.transform(vl, calculate: to_number(value), as: "__value")
  end

  defp aggregate_value(vl, value, groupby, aggregate) do
    Vl.transform(vl, aggregate: [[op: aggregate, field: value, as: "__value"]], groupby: groupby)
  end

  # Sets the __r_start and __r_end fields of each sector, stacking the values of
  # each group in the order of the sort field, if set
  defp stack_radius(vl, _group, nil) do
    vl
    |> Vl.transform(calculate: "datum.__value", as: "__r_end")
    |> Vl.transform(calculate: "0", as: "__r_start")
  end

  defp stack_radius(vl, group, sort_field) do
    vl
    |> Vl.transform(
      window: [[op: :sum, field: "__value", as: "__r_end"]],
      groupby: [group],
      sort: [[field: sort_field]],
      frame: [nil, 0]
    )
    |> Vl.transform(calculate: "datum.__r_end - datum.__value", as: "__r_start")
  end

  # The maximum stacked value of a group, computed in the same way as the vega-lite
  # transforms, if the data are inline
  defp max_stacked_value(vl, value, group, groups, color_by, aggregate) do
    case get_in(vl.spec, ["data", "values"]) do
      rows when is_list(rows) ->
        groups = MapSet.new(groups)

        rows
        |> Enum.filter(&(to_string(&1[group]) in groups))
        |> Enum.group_by(&{&1[group], color_by && &1[color_by]}, &to_number_value(&1[value]))
        |> Enum.flat_map(fn {{group, _color}, values} ->
          for value <- aggregate_values(values, aggregate), do: {group, value}
        end)
        |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
        |> Enum.map(fn {_group, values} ->
          if color_by, do: Enum.sum(values), else: Enum.max(values)
        end)
        |> Enum.max(fn -> 0 end)

      _other ->
        nil
    end
  end

  defp to_number_value(value) when is_number(value), do: value
  defp to_number_value(_value), do: 0

  defp aggregate_values(values, nil), do: values
  defp aggregate_values(values, :sum), do: [Enum.sum(values)]
  defp aggregate_values(values, :count), do: [length(values)]
  defp aggregate_values(values, :mean), do: [Enum.sum(values) / length(values)]
  defp aggregate_values(values, :min), do: [Enum.min(values)]
  defp aggregate_values(values, :max), do: [Enum.max(values)]

  # Builds a polar plot of circular sectors, from a layer that sets the __start_angle,
  # __end_angle (in degrees) and __r_start, __r_end fields of each sector. The layer
  # can also be a function receiving the grid and returning the layer.
  #
  # `color` is the field and the encoding options of the color, by default the
  # `:color_by` field if set.
  defp sectors_plot(plotdata, layer, opts, infer_max_radius, tooltip, color \\ nil) do
    {vl, grid, opts} = base_plot(plotdata, opts, infer_max_radius)

    mark_opts =
      Tucan.Options.take_options(opts, @bar_opts, :mark)
      |> Tucan.Keyword.put_not_nil(:color, opts[:fill_color])
      |> Tucan.Keyword.put_not_nil(:stroke, opts[:line_color])

    {color_field, color_opts} =
      color || {opts[:color_by], [type: :nominal]}

    # the layer may depend on the grid
    layer = if is_function(layer, 1), do: layer.(grid), else: layer

    tooltip =
      if color_field,
        do:
          Enum.uniq_by(tooltip ++ [[field: color_field, type: color_opts[:type]]], & &1[:field]),
        else: tooltip

    layer =
      layer
      |> Vl.transform(
        calculate: Grid.arc_theta_expr("datum.__start_angle", grid),
        as: "__theta"
      )
      |> Vl.transform(calculate: Grid.arc_theta_expr("datum.__end_angle", grid), as: "__theta2")
      |> Vl.mark(:arc, mark_opts)
      |> Vl.encode_field(:theta, "__theta", type: :quantitative, scale: nil, stack: nil)
      |> Vl.encode_field(:theta2, "__theta2")
      |> Vl.encode_field(:radius, "__r_end",
        type: :quantitative,
        scale: Grid.radius_scale(grid),
        stack: nil
      )
      |> Vl.encode_field(:radius2, "__r_start")
      |> maybe_encode_field(:color, color_field, opts, color_opts)
      |> then(fn layer ->
        if opts[:tooltip] == true, do: Vl.encode(layer, :tooltip, tooltip), else: layer
      end)

    Vl.layers(vl, Grid.layers(grid, [layer]))
  end

  histogram_opts = [
    bins: [
      type: :pos_integer,
      default: 16,
      doc: "The number of equal angle bins a full turn is split to."
    ],
    relative: [
      type: :boolean,
      default: false,
      doc: """
      If set the radius is the percentage of the values in each bin instead of
      their count.
      """
    ],
    color_by: [
      doc: """
      If set a data field used for coloring the bars. The bars of each bin are
      stacked outwards, in the order of the colors in the legend.
      """
    ]
  ]

  @histogram_opts Tucan.Options.take!(
                    [
                      :fill_opacity,
                      :tooltip,
                      :color_by,
                      :color,
                      :fill_color,
                      :line_color,
                      :stroke_width
                    ],
                    Tucan.Keyword.deep_merge(@polar_opts, histogram_opts)
                  )
  @histogram_schema Tucan.Options.to_nimble_schema!(@histogram_opts)

  @doc """
  Draws a circular histogram of the angles in the `theta` field.

  A full turn is split in `:bins` equal sectors and the radius of each sector is
  the number of values in it. Circular histograms are useful for cyclic data, like
  directions or the times of a day, since values near the end of the cycle are next
  to values near its start.

  See the module documentation for the coordinate conventions, cyclic data and the
  polar grid.

  ## Options

  #{Tucan.Options.docs(@histogram_opts)}

  ## Examples

  The directions of 400 generated observations, concentrated around 60 degrees:

  ```tucan
  directions =
    for i <- 1..400 do
      spread = 50 * :math.sin(i * 12.9898) * :math.cos(i * 4.1414)
      60 + spread + if(rem(i, 5) == 0, do: 180, else: 0)
    end

  Tucan.Polar.histogram([direction: directions], "direction",
    bins: 24,
    fill_color: "seagreen",
    line_color: "white"
  )
  ```

  The times of the day at which the purchases of an online store were made, as a
  percentage per hour and colored by the kind of device:

  ```tucan
  purchases =
    for i <- 1..600 do
      device = if rem(i, 3) == 0, do: "mobile", else: "desktop"
      peak = if device == "mobile", do: 21, else: 14
      hour = peak + 4 * :math.sin(i * 7.31) * :math.cos(i * 2.17)

      %{hour: hour, device: device}
    end

  Tucan.Polar.histogram(purchases, "hour",
    period: 24,
    bins: 24,
    color_by: "device",
    relative: true,
    tooltip: true
  )
  ```
  """
  @spec histogram(plotdata :: Tucan.plotdata(), theta :: String.t(), opts :: keyword()) ::
          VegaLite.t()
  def histogram(plotdata, theta, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @histogram_schema)

    bin_width = 360 / opts[:bins]
    color_by = opts[:color_by]
    groupby = Enum.reject(["__bin", color_by], &is_nil/1)

    layer =
      Vl.new()
      |> add_degrees_transform(theta, opts)
      |> Vl.transform(
        calculate: "min(floor(datum.__degrees / #{bin_width}), #{opts[:bins] - 1})",
        as: "__bin"
      )
      |> Vl.transform(aggregate: [[op: :count, as: "__value"]], groupby: groupby)
      |> maybe_relative(opts[:relative])
      |> Vl.transform(calculate: "datum.__bin * #{bin_width}", as: "__start_angle")
      |> Vl.transform(calculate: "datum.__start_angle + #{bin_width}", as: "__end_angle")
      |> stack_radius("__bin", color_by)
      |> add_bin_range_transforms(opts)

    value_title = if opts[:relative], do: "Percentage", else: "Count"

    tooltip =
      bin_range_tooltip(theta, opts) ++
        [[field: "__value", type: :quantitative, title: value_title, format: ".3~f"]]

    infer_max_radius = fn vl ->
      max_bin_value(vl, theta, color_by, opts, fn degrees -> trunc(degrees / bin_width) end)
    end

    sectors_plot(plotdata, layer, opts, infer_max_radius, tooltip)
  end

  # Sets the __degrees field, the angle in degrees in [0, 360)
  defp add_degrees_transform(vl, theta, opts) do
    degrees =
      cond do
        opts[:period] != nil -> "datum.__polar_period_angle"
        opts[:angle_unit] == :radians -> "#{to_number(theta)} * #{180 / :math.pi()}"
        true -> to_number(theta)
      end

    vl
    |> maybe_add_period_transform(theta, opts[:period])
    |> Vl.transform(calculate: "((#{degrees}) % 360 + 360) % 360", as: "__degrees")
  end

  defp maybe_relative(vl, false), do: vl

  defp maybe_relative(vl, true) do
    vl
    |> Vl.transform(joinaggregate: [[op: :sum, field: "__value", as: "__total"]])
    |> Vl.transform(calculate: "datum.__value / datum.__total * 100", as: "__value")
  end

  # The bin limits in the units of the theta field, not available for temporal data
  defp add_bin_range_transforms(vl, opts) do
    case bin_range_factor(opts) do
      nil ->
        vl

      factor ->
        vl
        |> Vl.transform(calculate: "datum.__start_angle * #{factor}", as: "__bin_start")
        |> Vl.transform(calculate: "datum.__end_angle * #{factor}", as: "__bin_end")
    end
  end

  defp bin_range_factor(opts) do
    cond do
      opts[:period] in @temporal_periods -> nil
      opts[:period] != nil -> opts[:period] / 360
      opts[:angle_unit] == :radians -> :math.pi() / 180
      true -> 1
    end
  end

  defp bin_range_tooltip(theta, opts) do
    if bin_range_factor(opts) do
      [
        [field: "__bin_start", type: :quantitative, title: "#{theta} from", format: ".4~f"],
        [field: "__bin_end", type: :quantitative, title: "#{theta} to", format: ".4~f"]
      ]
    else
      []
    end
  end

  # The maximum stacked value of the bins, computed in the same way as the vega-lite
  # transforms, if the data are inline. `bin_fun` returns the bin of an angle in
  # degrees in [0, 360).
  defp max_bin_value(vl, theta, color_by, opts, bin_fun) do
    case get_in(vl.spec, ["data", "values"]) do
      rows when is_list(rows) ->
        counts =
          rows
          |> Enum.map(fn row -> {degrees(row[theta], opts), color_by && row[color_by]} end)
          |> Enum.reject(fn {degrees, _color} -> is_nil(degrees) end)
          |> Enum.map(fn {degrees, color} -> {bin_fun.(degrees), color} end)
          |> Enum.frequencies()

        total = counts |> Map.values() |> Enum.sum()

        counts
        |> Enum.group_by(fn {{bin, _color}, _count} -> bin end, &elem(&1, 1))
        |> Enum.map(fn {_bin, counts} -> Enum.sum(counts) end)
        |> Enum.max(fn -> 0 end)
        |> then(fn max -> if opts[:relative] and total > 0, do: max / total * 100, else: max end)

      _other ->
        nil
    end
  end

  # The angle in degrees in [0, 360) of a theta value, nil if it is not valid
  defp degrees(value, opts) do
    degrees =
      case {opts[:period], opts[:angle_unit]} do
        {nil, :radians} -> to_float(value) && to_float(value) * 180 / :math.pi()
        {nil, _unit} -> to_float(value)
        {period, _unit} when period in @temporal_periods -> period_fraction(value, period)
        {period, _unit} -> to_float(value) && positive_mod(to_float(value), period) / period * 360
      end

    degrees && positive_mod(degrees, 360)
  end

  defp to_float(value) when is_number(value), do: value * 1.0

  defp to_float(value) when is_binary(value) do
    case Float.parse(value) do
      {float, ""} -> float
      _other -> nil
    end
  end

  defp to_float(_value), do: nil

  defp positive_mod(value, period) do
    value - period * Float.floor(value / period)
  end

  # The fraction of a temporal period, in degrees
  defp period_fraction(value, period) do
    case to_naive_datetime(value) do
      nil ->
        nil

      datetime ->
        {seconds, _micro} = NaiveDateTime.to_time(datetime) |> Time.to_seconds_after_midnight()
        day_fraction = seconds / 86_400
        date = NaiveDateTime.to_date(datetime)

        case period do
          :day ->
            day_fraction * 360

          :week ->
            (Date.day_of_week(date) - 1 + day_fraction) / 7 * 360

          :year ->
            days = if Date.leap_year?(date), do: 366, else: 365
            (Date.day_of_year(date) - 1 + day_fraction) / days * 360
        end
    end
  end

  defp to_naive_datetime(%NaiveDateTime{} = datetime), do: datetime
  defp to_naive_datetime(%DateTime{} = datetime), do: DateTime.to_naive(datetime)
  defp to_naive_datetime(%Date{} = date), do: NaiveDateTime.new!(date, ~T[00:00:00])

  defp to_naive_datetime(value) when is_binary(value) do
    case NaiveDateTime.from_iso8601(value) do
      {:ok, datetime} ->
        datetime

      _error ->
        case Date.from_iso8601(value) do
          {:ok, date} -> NaiveDateTime.new!(date, ~T[00:00:00])
          _error -> nil
        end
    end
  end

  defp to_naive_datetime(_value), do: nil

  windrose_opts = [
    directions: [
      type: :pos_integer,
      default: 16,
      doc: """
      The number of direction bins. The bins are centered at the directions, e.g. with
      the default 16 bins the North bin spans from -11.25 to 11.25 degrees.
      """
    ],
    speed_bins: [
      type: {:list, {:or, [:integer, :float]}},
      type_doc: "list of `t:number/0`",
      doc: """
      The increasing lower limits of the speed bins. The last bin contains all speeds
      above the last limit and speeds below the first limit are ignored. If not set,
      five equal bins starting from `0` are used, which is possible only if the data
      are passed inline.
      """
    ],
    relative: [
      type: :boolean,
      default: true,
      doc: """
      If set the radius is the percentage of the observations in each bin, otherwise
      their count.
      """
    ],
    direction: [default: :clockwise],
    angle_offset: [default: 90],
    angle_labels: [default: :compass]
  ]

  @windrose_opts Tucan.Options.take!(
                   [
                     :fill_opacity,
                     :tooltip,
                     :color,
                     :line_color,
                     :stroke_width
                   ],
                   Tucan.Keyword.deep_merge(
                     Keyword.drop(@polar_opts, [:angle_unit, :period]),
                     windrose_opts
                   )
                 )
  @windrose_schema Tucan.Options.to_nimble_schema!(@windrose_opts)

  @doc """
  Draws a wind rose.

  A wind rose shows how the observations of wind speed and direction are distributed.
  The observations are binned by direction, and the bar of each direction is split
  by speed, with the lower speeds closer to the center. By default the radius is the
  percentage of the observations in each bin.

  `direction` is the field with the direction the wind blows from, in degrees, and
  `speed` the field with the wind speed. The plot follows the compass, with North on
  top and directions increasing clockwise.

  See the module documentation for more details on the polar grid.

  ## Options

  #{Tucan.Options.docs(@windrose_opts)}

  ## Examples

  Generated observations with a prevailing south west wind:

  ```tucan
  :rand.seed(:exsss, {1, 2, 3})

  data =
    for _i <- 1..500 do
      direction = 225 + 45 * :rand.normal()
      speed = abs(6 + 3 * :rand.normal() + 2 * :math.cos((direction - 225) * :math.pi() / 180))

      %{direction: direction, speed: speed}
    end

  Tucan.Polar.windrose(data, "direction", "speed", line_color: "white", tooltip: true)
  ```

  With custom speed bins, eight directions, counts instead of percentages and a
  different color scheme:

  ```tucan
  :rand.seed(:exsss, {1, 2, 3})

  data =
    for _i <- 1..300 do
      direction = if :rand.uniform() < 0.6, do: 20 * :rand.normal(), else: 360 * :rand.uniform()
      %{direction: direction, speed: 12 * :rand.uniform()}
    end

  Tucan.Polar.windrose(data, "direction", "speed",
    directions: 8,
    speed_bins: [0, 3, 6, 9],
    relative: false,
    color: [scale: [scheme: "viridis"]]
  )
  ```
  """
  @spec windrose(
          plotdata :: Tucan.plotdata(),
          direction :: String.t(),
          speed :: String.t(),
          opts :: keyword()
        ) :: VegaLite.t()
  def windrose(plotdata, direction, speed, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @windrose_schema)

    thresholds = validate_speed_bins!(opts[:speed_bins]) || default_speed_bins!(plotdata, speed)
    labels = speed_labels(thresholds)
    bin_width = 360 / opts[:directions]

    # the index of the highest threshold not greater than the speed, -1 if none
    speed_index =
      thresholds
      |> Enum.with_index()
      |> Enum.reduce("-1", fn {threshold, i}, acc ->
        "#{to_number(speed)} >= #{threshold} ? #{i} : (#{acc})"
      end)

    layer =
      Vl.new()
      |> add_degrees_transform(direction, opts)
      |> Vl.transform(calculate: speed_index, as: "__speed_index")
      |> Vl.transform(filter: "datum.__speed_index >= 0")
      |> Vl.transform(
        calculate: "#{Jason.encode!(labels)}[datum.__speed_index]",
        as: "__speed"
      )
      |> Vl.transform(
        calculate: "floor(((datum.__degrees + #{bin_width / 2}) % 360) / #{bin_width})",
        as: "__bin"
      )
      |> Vl.transform(
        aggregate: [[op: :count, as: "__value"]],
        groupby: ["__bin", "__speed_index", "__speed"]
      )
      |> maybe_relative(opts[:relative])
      |> Vl.transform(
        calculate: "datum.__bin * #{bin_width} - #{bin_width / 2}",
        as: "__start_angle"
      )
      |> Vl.transform(calculate: "datum.__start_angle + #{bin_width}", as: "__end_angle")
      |> stack_radius("__bin", "__speed_index")

    value_title = if opts[:relative], do: "Percentage", else: "Count"

    tooltip = [[field: "__value", type: :quantitative, title: value_title, format: ".3~f"]]

    infer_max_radius = fn vl ->
      max_windrose_value(vl, direction, speed, thresholds, bin_width, opts[:relative])
    end

    color = {"__speed", [type: :ordinal, sort: labels, title: speed]}

    sectors_plot(plotdata, layer, opts, infer_max_radius, tooltip, color)
  end

  defp validate_speed_bins!(nil), do: nil

  defp validate_speed_bins!(bins) do
    if bins == [] or bins != Enum.sort(Enum.uniq(bins)) do
      raise ArgumentError,
            "expected :speed_bins to be a non empty list of increasing numbers, " <>
              "got: #{inspect(bins)}"
    end

    bins
  end

  defp default_speed_bins!(plotdata, speed) do
    case inline_values(Tucan.new(plotdata), speed) do
      nil ->
        raise ArgumentError,
              "cannot infer the speed bins of a wind rose if the data are not passed " <>
                "inline, set the :speed_bins option"

      values ->
        max = values |> Enum.map(&to_float/1) |> Enum.reject(&is_nil/1) |> Enum.max(fn -> 0 end)
        step = Grid.nice_max(max) / 5

        for i <- 0..4, do: round_number(i * step)
    end
  end

  defp round_number(value) do
    rounded = Float.round(value * 1.0, 10)
    if rounded == Float.round(rounded), do: trunc(rounded), else: rounded
  end

  defp speed_labels(thresholds) do
    ranges =
      thresholds
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [from, to] -> "#{format_number(from)}–#{format_number(to)}" end)

    ranges ++ ["#{format_number(List.last(thresholds))}+"]
  end

  defp max_windrose_value(vl, direction, speed, thresholds, bin_width, relative) do
    case get_in(vl.spec, ["data", "values"]) do
      rows when is_list(rows) ->
        min_speed = hd(thresholds)

        bins =
          for row <- rows,
              speed = to_float(row[speed]),
              speed != nil and speed >= min_speed,
              degrees = degrees(row[direction], angle_unit: :degrees),
              degrees != nil do
            trunc(positive_mod(degrees + bin_width / 2, 360) / bin_width)
          end

        max = bins |> Enum.frequencies() |> Map.values() |> Enum.max(fn -> 0 end)

        if relative and bins != [], do: max / length(bins) * 100, else: max

      _other ->
        nil
    end
  end

  heatmap_opts = [
    theta_bins: [
      type: :pos_integer,
      default: 24,
      doc: "The number of equal angle bins a full turn is split to."
    ],
    radius_bins: [
      type: :pos_integer,
      doc: """
      The number of equal radius bins. If not set the radius ticks of the grid are
      used as the bin limits, so that the grid circles are the edges of the cells.
      """
    ],
    aggregate: [
      type: {:in, [:mean, :sum, :count, :median, :min, :max]},
      doc: """
      The statistic used for aggregating the values of the `color` field within each
      cell. Defaults to `:mean`. Ignored if `color` is `nil`.
      """
    ],
    color_scheme: [
      type: :atom,
      doc: """
      The color scheme to use, for supported color schemes check `Tucan.Scale`.
      """,
      section: :style
    ]
  ]

  @heatmap_opts Tucan.Options.take!(
                  [
                    :fill_opacity,
                    :tooltip,
                    :color,
                    :line_color,
                    :stroke_width
                  ],
                  Tucan.Keyword.deep_merge(@polar_opts, heatmap_opts)
                )
  @heatmap_schema Tucan.Options.to_nimble_schema!(@heatmap_opts)

  @doc """
  Draws a polar heatmap.

  The observations are binned by their angle, the `theta` field, and their radius,
  the `r` field, and each cell is colored by the aggregated values of the `color`
  field. If `color` is `nil` the cells are colored by the number of observations.

  Radius values below zero or above the maximum radius are ignored.

  See the module documentation for the coordinate conventions, cyclic data and the
  polar grid.

  ## Options

  #{Tucan.Options.docs(@heatmap_opts)}

  ## Examples

  The number of generated wind observations by direction and speed:

  ```tucan
  :rand.seed(:exsss, {1, 2, 3})

  data =
    for _i <- 1..2000 do
      direction = 225 + 50 * :rand.normal()
      %{direction: direction, speed: abs(6 + 2.5 * :rand.normal())}
    end

  Tucan.Polar.heatmap(data, "direction", "speed", nil,
    theta_bins: 36,
    radius_bins: 12,
    direction: :clockwise,
    angle_offset: 90,
    angle_labels: :compass,
    color_scheme: :viridis
  )
  ```

  The activity of a website per hour of the day and day of the week, from Monday at
  the center to Sunday at the edge:

  ```tucan
  data =
    for day <- 0..6, hour <- 0..23 do
      weekend? = day >= 5
      peak = if weekend?, do: 15, else: 11
      activity = 100 * :math.exp(-:math.pow((hour - peak) / 4, 2)) * if(weekend?, do: 0.6, else: 1)

      %{day: day, hour: hour, activity: activity}
    end

  Tucan.Polar.heatmap(data, "hour", "day", "activity",
    period: 24,
    radius_ticks: [1, 2, 3, 4, 5, 6, 7],
    color_scheme: :oranges,
    tooltip: true
  )
  ```
  """
  @spec heatmap(
          plotdata :: Tucan.plotdata(),
          theta :: String.t(),
          r :: String.t(),
          color :: String.t() | nil,
          opts :: keyword()
        ) :: VegaLite.t()
  def heatmap(plotdata, theta, r, color, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @heatmap_schema)

    bin_width = 360 / opts[:theta_bins]

    {aggregate, value_title} =
      case color do
        nil -> {[op: :count, as: "__value"], "Count"}
        field -> heatmap_aggregate(field, opts[:aggregate] || :mean)
      end

    layer = fn grid ->
      edges = radius_edges(grid, opts[:radius_bins])

      Vl.new()
      |> add_degrees_transform(theta, opts)
      |> Vl.transform(calculate: to_number(r), as: "__r")
      |> Vl.transform(filter: "datum.__r >= 0 && datum.__r <= #{grid.max_radius}")
      |> Vl.transform(
        calculate: "min(floor(datum.__degrees / #{bin_width}), #{opts[:theta_bins] - 1})",
        as: "__bin"
      )
      |> Vl.transform(calculate: radius_bin_expr(edges), as: "__r_bin")
      |> Vl.transform(aggregate: [aggregate], groupby: ["__bin", "__r_bin"])
      |> Vl.transform(calculate: "datum.__bin * #{bin_width}", as: "__start_angle")
      |> Vl.transform(calculate: "datum.__start_angle + #{bin_width}", as: "__end_angle")
      |> Vl.transform(calculate: "#{Jason.encode!(edges)}[datum.__r_bin]", as: "__r_start")
      |> Vl.transform(calculate: "#{Jason.encode!(edges)}[datum.__r_bin + 1]", as: "__r_end")
      |> add_bin_range_transforms(opts)
    end

    tooltip =
      bin_range_tooltip(theta, opts) ++
        [
          [field: "__r_start", type: :quantitative, title: "#{r} from", format: ".4~f"],
          [field: "__r_end", type: :quantitative, title: "#{r} to", format: ".4~f"],
          [field: "__value", type: :quantitative, title: value_title, format: ".3~f"]
        ]

    opts =
      if opts[:color_scheme] do
        Keyword.update!(opts, :color, fn color_opts ->
          Tucan.Keyword.deep_merge([scale: [scheme: opts[:color_scheme]]], color_opts)
        end)
      else
        opts
      end

    sectors_plot(
      plotdata,
      layer,
      opts,
      &max_abs_value(&1, r),
      tooltip,
      {"__value", [type: :quantitative, title: value_title]}
    )
  end

  defp heatmap_aggregate(field, aggregate) do
    {[op: aggregate, field: field, as: "__value"], "#{aggregate}(#{field})"}
  end

  defp radius_edges(grid, nil) do
    Enum.uniq([0 | grid.radius_ticks] ++ [grid.max_radius])
  end

  defp radius_edges(grid, bins) do
    for i <- 0..bins, do: round_number(i * grid.max_radius / bins)
  end

  # The index of the radius bin, the last bin includes its upper limit
  defp radius_bin_expr(edges) do
    edges
    |> Enum.drop(-1)
    |> Enum.with_index()
    |> Enum.reduce("0", fn {edge, i}, acc -> "datum.__r >= #{edge} ? #{i} : (#{acc})" end)
  end

  ## Polar plot construction

  # Builds a layered plot with the polar grid and the given data layers, drawn above
  # the grid lines and below the grid labels.
  # The data are set on the top level spec and inherited by the data layers.
  #
  # `tooltip_theta` is the field and type of the angle shown in the tooltip.
  defp polar_plot(plotdata, r, theta, layers, opts, tooltip_theta \\ nil) do
    {vl, grid, opts} = base_plot(plotdata, opts, &max_abs_value(&1, r))

    layers =
      for layer <- List.wrap(layers) do
        layer
        |> maybe_add_period_transform(theta, opts[:period])
        |> Vl.transform(calculate: angle_expr(theta, opts), as: "__polar_angle")
        |> Vl.transform(calculate: "#{to_number(r)} * cos(datum.__polar_angle)", as: "__polar_x")
        |> Vl.transform(calculate: "#{to_number(r)} * sin(datum.__polar_angle)", as: "__polar_y")
        |> Grid.encode_xy("__polar_x", "__polar_y", grid)
        |> maybe_encode_tooltip(r, tooltip_theta || {theta, theta_type(opts)}, opts)
      end

    Vl.layers(vl, Grid.layers(grid, layers))
  end

  # The square top level plot and the grid. `infer_max_radius` is called with the
  # top level plot if the max radius must be inferred from the data.
  defp base_plot(plotdata, opts, infer_max_radius) do
    opts = resolve_defaults(opts)
    width = opts[:width]

    vl =
      Tucan.new(plotdata, Keyword.take(opts, [:width, :title]))
      |> Vl.config(view: [stroke: nil])
      |> Tucan.Utils.put_in_spec(:height, width)

    grid = Grid.new(opts, fn -> infer_max_radius.(vl) end)

    # the angle labels are outside of the plot, so the legends must be moved further
    # to the right, the default legend offset is 18 pixels
    vl = Vl.config(vl, legend: [offset: round(max(18, Grid.right_overflow(grid) + 10))])

    {vl, grid, opts}
  end

  # The maximum absolute value of the field if the data are inline, nil otherwise
  defp max_abs_value(vl, field) do
    case inline_values(vl, field) do
      nil ->
        nil

      values ->
        values
        |> Enum.filter(&is_number/1)
        |> Enum.map(&abs/1)
        |> Enum.max(fn -> 0 end)
    end
  end

  # The values of the field if the data are inline, nil otherwise
  defp inline_values(%VegaLite{} = vl, field) do
    case get_in(vl.spec, ["data", "values"]) do
      values when is_list(values) -> Enum.map(values, &Map.get(&1, field))
      _other -> nil
    end
  end

  defp angle_expr(theta, opts) do
    sign = if opts[:direction] == :clockwise, do: -1, else: 1
    offset = deg_to_rad(opts[:angle_offset])

    cond do
      opts[:period] != nil ->
        "#{sign * :math.pi() / 180} * datum.__polar_period_angle + #{offset}"

      opts[:angle_unit] == :degrees ->
        "#{sign * :math.pi() / 180} * #{to_number(theta)} + #{offset}"

      true ->
        "#{sign} * #{to_number(theta)} + #{offset}"
    end
  end

  ## Cyclic data

  defp theta_type(opts) do
    if opts[:period] in @temporal_periods, do: :temporal, else: :quantitative
  end

  defp resolve_defaults(opts) do
    {period_marks, period_labels} = period_marks(opts[:period])

    # the period labels apply only to the period marks
    angle_labels = if opts[:angle_marks], do: :degrees, else: period_labels

    {direction, angle_offset} =
      if opts[:period], do: {:clockwise, 90}, else: {:counter_clockwise, 0}

    Keyword.merge(opts,
      angle_marks: opts[:angle_marks] || period_marks,
      angle_labels: opts[:angle_labels] || angle_labels,
      direction: opts[:direction] || direction,
      angle_offset: opts[:angle_offset] || angle_offset
    )
  end

  @default_angle_marks [0, 45, 90, 135, 180, 225, 270, 315]

  @month_start_days [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]

  # The default angle marks and labels of a period
  defp period_marks(nil), do: {@default_angle_marks, :degrees}

  defp period_marks(:day) do
    {@default_angle_marks,
     for(hour <- 0..21//3, do: String.pad_leading("#{hour}", 2, "0") <> ":00")}
  end

  defp period_marks(:week) do
    {for(i <- 0..6, do: i * 360 / 7), ~w(Mon Tue Wed Thu Fri Sat Sun)}
  end

  defp period_marks(:year) do
    {for(day <- @month_start_days, do: day * 360 / 365),
     ~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)}
  end

  defp period_marks(period) do
    divisions =
      Enum.find([8, 12, 6, 4], 8, fn divisions ->
        step = period / divisions
        step == Float.round(step * 1.0)
      end)

    step = period / divisions

    {for(i <- 0..(divisions - 1), do: i * 360 / divisions),
     for(i <- 0..(divisions - 1), do: format_number(i * step))}
  end

  defp format_number(value) do
    if value == Float.round(value * 1.0),
      do: Integer.to_string(trunc(value)),
      else: to_string(value)
  end

  defp maybe_add_period_transform(vl, _theta, nil), do: vl

  defp maybe_add_period_transform(vl, theta, period) when period in @temporal_periods do
    vl
    |> Vl.transform(calculate: "toDate(datum[#{Jason.encode!(theta)}])", as: "__polar_date")
    |> Vl.transform(calculate: period_degrees_expr(period), as: "__polar_period_angle")
  end

  defp maybe_add_period_transform(vl, theta, period) do
    Vl.transform(vl,
      calculate: "((#{to_number(theta)} % #{period}) + #{period}) % #{period} / #{period} * 360",
      as: "__polar_period_angle"
    )
  end

  @seconds_of_day "(hours(datum.__polar_date) * 3600 + minutes(datum.__polar_date) * 60 + " <>
                    "seconds(datum.__polar_date))"

  defp period_degrees_expr(:day), do: "#{@seconds_of_day} / 86400 * 360"

  defp period_degrees_expr(:week),
    do: "((day(datum.__polar_date) + 6) % 7 + #{@seconds_of_day} / 86400) / 7 * 360"

  defp period_degrees_expr(:year) do
    year_start = "time(datetime(year(datum.__polar_date), 0, 1))"
    next_year_start = "time(datetime(year(datum.__polar_date) + 1, 0, 1))"

    "(time(datum.__polar_date) - #{year_start}) / (#{next_year_start} - #{year_start}) * 360"
  end

  defp to_number(field), do: "toNumber(datum[#{Jason.encode!(field)}])"

  defp maybe_encode_field(vl, _channel, nil, _opts, _extra), do: vl

  defp maybe_encode_field(vl, channel, field, opts, extra),
    do: Tucan.Utils.encode_field(vl, channel, field, opts, extra)

  # The default tooltip would show the cartesian coordinates, instead we show the
  # polar coordinates and the grouping fields
  defp maybe_encode_tooltip(vl, r, {theta, theta_type}, opts) do
    if opts[:tooltip] == true do
      fields =
        [
          [field: r, type: :quantitative],
          [field: theta, type: theta_type]
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

  defp deg_to_rad(angle), do: angle * :math.pi() / 180
end
