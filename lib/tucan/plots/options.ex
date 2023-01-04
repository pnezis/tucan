defmodule Tucan.Plots.Options do
  def schema(:scatter) do
    [
      shape: [
        type:
          {:in,
           [
             "circle",
             "square",
             "cross",
             "diamond",
             "triangle-up",
             "triangle-down",
             "triangle-right",
             "triangle-left"
           ]},
        default: "circle",
        doc: """
        Shape of the point mark, for more details check the [Vega-Lite docs](https://vega.github.io/vega-lite/docs/point.html#properties)
        """
      ]
    ]
  end

  def schema(_type), do: []
end
