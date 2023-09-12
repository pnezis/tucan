mark_color = "#ab5787"
axis_color = "#979797"

theme = [
  background: "#f9f9f9",
  arc: [fill: mark_color],
  area: [fill: mark_color],
  line: [stroke: mark_color],
  path: [stroke: mark_color],
  rect: [fill: mark_color],
  shape: [stroke: mark_color],
  symbol: [fill: mark_color, size: 30],
  axis: [
    domain_color: axis_color,
    domain_width: 0.5,
    grid_width: 0.2,
    label_color: axis_color,
    tick_color: axis_color,
    tick_width: 0.2,
    title_color: axis_color
  ],
  axis_band: [
    grid: false
  ],
  axis_x: [
    grid: true,
    tick_size: 10
  ],
  axis_y: [
    domain: false,
    grid: true,
    tick_size: 0
  ],
  legend: [
    label_font_size: 11,
    padding: 1,
    symbol_size: 30,
    symbol_type: "square"
  ],
  range: [
    category: [
      "#ab5787",
      "#51b2e5",
      "#703c5c",
      "#168dd9",
      "#d190b6",
      "#00609f",
      "#d365ba",
      "#154866",
      "#666666",
      "#c4c4c4"
    ]
  ]
]

[
  theme: theme,
  name: :quartz,
  doc: "Chart theme modeled after Quartz",
  source: "https://github.com/vega/vega-themes/blob/main/src/theme-quartz.ts"
]
