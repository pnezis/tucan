mark_color = "#3366CC"
grid_color = "#ccc"
default_font = "arial, sans-serif"

theme = [
  arc: [fill: mark_color],
  area: [fill: mark_color],
  path: [stroke: mark_color],
  rect: [fill: mark_color],
  shape: [stroke: mark_color],
  symbol: [stroke: mark_color],
  circle: [fill: mark_color],
  background: "#fff",
  padding: [
    top: 10,
    right: 10,
    bottom: 10,
    left: 10
  ],
  style: [
    guide_label: [
      font: default_font,
      font_size: 12
    ],
    guide_title: [
      font: default_font,
      font_size: 12
    ],
    group_title: [
      font: default_font,
      font_size: 12
    ]
  ],
  title: [
    font: default_font,
    font_size: 14,
    font_weight: "bold",
    dy: -3,
    anchor: "start"
  ],
  axis: [
    grid_color: grid_color,
    tick_color: grid_color,
    domain: false,
    grid: true
  ],
  range: [
    category: [
      "#4285F4",
      "#dB4437",
      "#f4B400",
      "#0F9D58",
      "#aB47BC",
      "#00ACC1",
      "#fF7043",
      "#9E9D24",
      "#5C6BC0",
      "#f06292",
      "#00796B",
      "#c2185B"
    ],
    heatmap: ["#c6dafc", "#5e97f6", "#2a56c6"]
  ]
]

[
  theme: theme,
  name: :google_charts,
  doc: "Chart theme modeled after Google Charts",
  source: "https://github.com/vega/vega-themes/blob/main/src/theme-googlecharts.ts"
]
