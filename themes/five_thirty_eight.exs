mark_color = "#30a2da"
axis_color = "#cbcbcb"
guide_label_color = "#999"
guide_title_color = "#333"
background_color = "#f0f0f0"
black_title = "#333"

theme = [
  arc: [fill: mark_color],
  area: [fill: mark_color],
  axis: [
    domain_color: axis_color,
    grid: true,
    grid_color: axis_color,
    grid_width: 1,
    label_color: guide_label_color,
    label_font_size: 10,
    title_color: guide_title_color,
    tick_color: axis_color,
    tick_size: 10,
    title_font_size: 14,
    title_padding: 10,
    label_padding: 4
  ],
  axis_band: [
    grid: false
  ],
  background: background_color,
  group: [
    fill: background_color
  ],
  legend: [
    label_color: black_title,
    label_font_size: 11,
    padding: 1,
    symbol_size: 30,
    symbol_type: "square",
    title_color: black_title,
    title_font_size: 14,
    title_padding: 10
  ],
  line: [
    stroke: mark_color,
    stroke_width: 2
  ],
  path: [stroke: mark_color, stroke_width: 0.5],
  rect: [fill: mark_color],
  range: [
    category: [
      "#30a2da",
      "#fc4f30",
      "#e5ae38",
      "#6d904f",
      "#8b8b8b",
      "#b96db8",
      "#ff9e27",
      "#56cc60",
      "#52d2ca",
      "#52689e",
      "#545454",
      "#9fe4f8"
    ],
    diverging: ["#cc0020", "#e77866", "#f6e7e1", "#d6e8ed", "#91bfd9", "#1d78b5"],
    heatmap: ["#d6e8ed", "#cee0e5", "#91bfd9", "#549cc6", "#1d78b5"]
  ],
  point: [
    filled: true,
    shape: "circle"
  ],
  shape: [stroke: mark_color],
  bar: [
    bin_spacing: 2,
    fill: mark_color,
    stroke: nil
  ],
  title: [
    anchor: "start",
    font_size: 24,
    font_weight: 600,
    offset: 20
  ]
]

[
  theme: theme,
  name: :five_thirty_eight,
  doc: "Chart theme modeled after FiveThirtyEight",
  source: "https://github.com/vega/vega-themes/blob/main/src/theme-fivethirtyeight.ts"
]
