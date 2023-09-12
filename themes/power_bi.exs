pt_to_px = fn value -> value * (1 / 3 + 1) end

font_small_px = pt_to_px.(9)
legend_font_px = pt_to_px.(10)
font_large_px = pt_to_px.(12)

font_standard = "segoe uI"
font_title = "wf_standard-font, helvetica, arial, sans-serif"
first_level_element_color = "#252423"
second_level_element_color = "#605E5C"
background_color = "transparent"
background_secondary_color = "#c8C6C4"

palette_color1 = "#118DFF"
palette_color2 = "#12239E"
palette_color3 = "#e66C37"
palette_color4 = "#6B007B"
palette_color5 = "#e044A7"
palette_color6 = "#744EC2"
palette_color7 = "#d9B300"
palette_color8 = "#d64550"

divergent_color_max = palette_color1
divergent_color_min = "#dEEFFF"
divergent_palette = [divergent_color_min, divergent_color_max]

ordinal_palette = [
  divergent_color_min,
  "#c7e4ff",
  "#b0d9ff",
  "#9aceff",
  "#83c3ff",
  "#6cb9ff",
  "#55aeff",
  "#3fa3ff",
  "#2898ff",
  divergent_color_max
]

theme = [
  view: [stroke: background_color],
  background: background_color,
  font: font_standard,
  header: [
    title_font: font_title,
    title_font_size: font_large_px,
    title_color: first_level_element_color,
    label_font: font_standard,
    label_font_size: legend_font_px,
    label_color: second_level_element_color
  ],
  axis: [
    ticks: false,
    grid: false,
    domain: false,
    label_color: second_level_element_color,
    label_font_size: font_small_px,
    title_font: font_title,
    title_color: first_level_element_color,
    title_font_size: font_large_px,
    title_font_weight: "normal"
  ],
  axis_quantitative: [
    tick_count: 3,
    grid: true,
    grid_color: background_secondary_color,
    grid_dash: [1, 5],
    label_flush: false
  ],
  axis_band: [tick_extra: true],
  axis_x: [label_padding: 5],
  axis_y: [label_padding: 10],
  bar: [fill: palette_color1],
  line: [
    stroke: palette_color1,
    stroke_width: 3,
    stroke_cap: "round",
    stroke_join: "round"
  ],
  text: [font: font_standard, font_size: font_small_px, fill: second_level_element_color],
  arc: [fill: palette_color1],
  area: [fill: palette_color1, line: true, opacity: 0.6],
  path: [stroke: palette_color1],
  rect: [fill: palette_color1],
  point: [fill: palette_color1, filled: true, size: 75],
  shape: [stroke: palette_color1],
  symbol: [fill: palette_color1, stroke_width: 1.5, size: 50],
  legend: [
    title_font: font_standard,
    title_font_weight: "bold",
    title_color: second_level_element_color,
    label_font: font_standard,
    label_font_size: legend_font_px,
    label_color: second_level_element_color,
    symbol_type: "circle",
    symbol_size: 75
  ],
  range: [
    category: [
      palette_color1,
      palette_color2,
      palette_color3,
      palette_color4,
      palette_color5,
      palette_color6,
      palette_color7,
      palette_color8
    ],
    diverging: divergent_palette,
    heatmap: divergent_palette,
    ordinal: ordinal_palette
  ]
]

[
  theme: theme,
  name: :power_bi,
  doc: "Chart theme modeled after Power BI",
  source: "https://github.com/vega/vega-themes/blob/main/src/theme-powerbi.ts"
]
