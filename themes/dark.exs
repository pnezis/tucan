light_color = "#fff"
med_color = "#888"

theme = [
  background: "#333",
  view: [
    stroke: med_color
  ],
  title: [
    color: light_color,
    subtitle_color: light_color
  ],
  style: [
    "guide-label": [
      fill: light_color
    ],
    "guide-title": [
      fill: light_color
    ]
  ],
  axis: [
    domain_color: light_color,
    grid_color: med_color,
    tick_color: light_color
  ]
]

[
  theme: theme,
  name: :dark,
  doc: "A dark theme",
  source: "https://github.com/vega/vega-themes/blob/main/src/theme-dark.ts"
]
