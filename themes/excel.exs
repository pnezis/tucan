mark_color = "#4572a7"

theme = [
  background: "#fff",
  arc: [fill: mark_color],
  area: [fill: mark_color],
  line: [stroke: mark_color, stroke_width: 2],
  path: [stroke: mark_color],
  rect: [fill: mark_color],
  shape: [stroke: mark_color],
  symbol: [fill: mark_color, stroke_width: 1.5, size: 50],
  axis: [
    band_position: 0.5,
    grid: true,
    grid_color: "#000000",
    grid_opacity: 1,
    grid_width: 0.5,
    label_padding: 10,
    tick_size: 5,
    tick_width: 0.5
  ],
  axis_band: [
    grid: false,
    tick_extra: true
  ],
  legend: [
    label_baseline: "middle",
    label_font_size: 11,
    symbol_size: 50,
    symbol_type: "square"
  ],
  range: [
    category: [
      "#4572a7",
      "#aa4643",
      "#8aa453",
      "#71598e",
      "#4598ae",
      "#d98445",
      "#94aace",
      "#d09393",
      "#b9cc98",
      "#a99cbc"
    ]
  ]
]

[
  theme: theme,
  name: :excel,
  doc: "Chart theme modeled after `excel`",
  source: "https://github.com/vega/vega-themes/blob/main/src/theme-excel.ts"
]
