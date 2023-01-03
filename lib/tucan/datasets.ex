defmodule Tucan.Datasets do
  @moduledoc """
  Common datasets for `Tucan` demos and docs.
  """

  def dataset(:iris),
    do:
      "https://gist.githubusercontent.com/curran/a08a1080b88344b0c8a7/raw/0e7a9b0a5d22642a06d3d5b9bcbad9890c8ee534/iris.csv"

  def dataset(:corruption),
    do:
      "https://raw.githubusercontent.com/holtzy/The-Python-Graph-Gallery/master/static/data/corruption.csv"

  def dataset(:cars), do: "https://vega.github.io/editor/data/cars.json"

  def dataset(:gapminder),
    do: "https://vega.github.io/vega-datasets/data/gapminder-health-income.csv"

  def dataset(:weather), do: "https://vega.github.io/editor/data/weather.csv"
end
