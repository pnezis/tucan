mark_color = "#000"

theme = [
  group: [
    fill: "#e5e5e5"
  ],
  arc: [fill: mark_color],
  area: [fill: mark_color],
  line: [stroke: mark_color],
  path: [stroke: mark_color],
  rect: [fill: mark_color],
  shape: [stroke: mark_color],
  symbol: [fill: mark_color, size: 40],
  axis: [
    domain: false,
    grid: true,
    grid_color: "#FFFFFF",
    grid_opacity: 1,
    label_color: "#7F7F7F",
    label_padding: 4,
    tick_color: "#7F7F7F",
    tick_size: 5.67,
    title_font_size: 16,
    title_font_weight: "normal"
  ],
  legend: [
    label_baseline: "middle",
    label_font_size: 11,
    symbol_size: 40
  ],
  range: [
    category: [
      "#000000",
      "#7F7F7F",
      "#1A1A1A",
      "#999999",
      "#333333",
      "#B0B0B0",
      "#4D4D4D",
      "#C9C9C9",
      "#666666",
      "#DCDCDC"
    ]
  ]
]

[
  theme: theme,
  name: :ggplot2,
  doc: "Chart theme modeled after `ggplot2`",
  source: "https://github.com/vega/vega-themes/blob/main/src/theme-ggplot2.ts"
]
