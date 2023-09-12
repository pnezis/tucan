mark_color = "#3e5c69"

theme = [
  background: "#fff",
  arc: [fill: mark_color],
  area: [fill: mark_color],
  line: [stroke: mark_color],
  path: [stroke: mark_color],
  rect: [fill: mark_color],
  shape: [stroke: mark_color],
  symbol: [fill: mark_color],
  axis: [
    domain_width: 0.5,
    grid: true,
    label_padding: 2,
    tick_size: 5,
    tick_width: 0.5,
    title_font_weight: "normal"
  ],
  axis_band: [
    grid: false
  ],
  axis_x: [
    grid_width: 0.2
  ],
  axis_y: [
    grid_dash: [3],
    grid_width: 0.4
  ],
  legend: [
    label_font_size: 11,
    padding: 1,
    symbol_type: "square"
  ],
  range: [
    category: [
      "#3e5c69",
      "#6793a6",
      "#182429",
      "#0570b0",
      "#3690c0",
      "#74a9cf",
      "#a6bddb",
      "#e2ddf2"
    ]
  ]
]

[
  theme: theme,
  name: :vox,
  doc: "Chart theme modeled after Vox",
  source: "https://github.com/vega/vega-themes/blob/main/src/theme-vox.ts"
]
