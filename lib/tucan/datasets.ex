defmodule Tucan.Datasets do
  @moduledoc """
  Common datasets for `Tucan` demos and docs.
  """

  @type t ::
          :iris
          | :corruption
          | :cars
          | :gapminder
          | :weather
          | :titanic
          | :penguins
          | :stocks
          | :flights
          | :tips

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

  def dataset(:stocks), do: "https://vega.github.io/editor/data/stocks.csv"

  def dataset(:titanic),
    do: "https://raw.githubusercontent.com/datasciencedojo/datasets/master/titanic.csv"

  def dataset(:penguins),
    do: "https://raw.githubusercontent.com/vega/vega-datasets/next/data/penguins.json"

  def dataset(:flights),
    do: "https://raw.githubusercontent.com/mwaskom/seaborn-data/master/flights.csv"

  def dataset(:tips), do: "https://raw.githubusercontent.com/mwaskom/seaborn-data/master/tips.csv"
end
