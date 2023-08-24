headline_font_size = 22
headline_font_weight = "normal"
label_font = "Benton Gothic, sans-serif"
label_font_size = 11.5
label_font_weight = "normal"
mark_color = "#82c6df"
title_font = "Benton Gothic Bold, sans-serif"
title_font_weight = "normal"
title_font_size = 13

color_schemes = %{
  "category-6" => ["#ec8431", "#829eb1", "#c89d29", "#3580b1", "#adc839", "#ab7fb4"],
  "fire-7" => ["#fbf2c7", "#f9e39c", "#f8d36e", "#f4bb6a", "#e68a4f", "#d15a40", "#ab4232"],
  "fireandice-6" => ["#e68a4f", "#f4bb6a", "#f9e39c", "#dadfe2", "#a6b7c6", "#849eae"],
  "ice-7" => ["#edefee", "#dadfe2", "#c4ccd2", "#a6b7c6", "#849eae", "#607785", "#47525d"]
}

theme = [
  background: "#ffffff",
  title: [
    anchor: "start",
    color: "#000000",
    font: title_font,
    font_size: headline_font_size,
    font_weight: headline_font_weight
  ],
  arc: [fill: mark_color],
  area: [fill: mark_color],
  line: [stroke: mark_color, stroke_width: 2],
  path: [stroke: mark_color],
  rect: [fill: mark_color],
  shape: [stroke: mark_color],
  symbol: [fill: mark_color, size: 30],
  axis: [
    label_font: label_font,
    label_font_size: label_font_size,
    label_font_weight: label_font_weight,
    title_font: title_font,
    title_font_size: title_font_size,
    title_font_weight: title_font_weight
  ],
  axis_x: [
    labelAngle: 0,
    labelPadding: 4,
    tickSize: 3
  ],
  axis_y: [
    labelBaseline: "middle",
    maxExtent: 45,
    minExtent: 45,
    tickSize: 2,
    titleAlign: "left",
    titleAngle: 0,
    titleX: -45,
    titleY: -11
  ],
  legend: [
    font: label_font,
    font_size: label_font_size,
    symbolType: "square",
    title_font: title_font,
    title_font_size: title_font_size,
    title_font_weight: title_font_weight
  ],
  range: [
    category: color_schemes["category-6"],
    diverging: color_schemes["fireandice-6"],
    heatmap: color_schemes["fire-7"],
    ordinal: color_schemes["fire-7"],
    ramp: color_schemes["fire-7"]
  ]
]

[
  theme: theme,
  name: :latimes,
  doc: "Chart theme modeled after the Los Angeles Times",
  source: "https://github.com/vega/vega-themes/blob/main/src/theme-latimes.ts"
]
