defmodule Tucan.Datasets do
  @moduledoc """
  Common datasets for `Tucan` demos and docs.
  """

  @type t ::
          :barley
          | :iris
          | :corruption
          | :cars
          | :gapminder
          | :weather
          | :titanic
          | :penguins
          | :stocks
          | :flights
          | :tips
          | :movies
          | :unemployment

  @datasets [
    barley: [
      url: "https://vega.github.io/editor/data/barley.json"
    ],
    iris: [
      url:
        "https://gist.githubusercontent.com/curran/a08a1080b88344b0c8a7/raw/0e7a9b0a5d22642a06d3d5b9bcbad9890c8ee534/iris.csv"
    ],
    corruption: [
      url:
        "https://raw.githubusercontent.com/holtzy/The-Python-Graph-Gallery/master/static/data/corruption.csv"
    ],
    cars: [
      url: "https://vega.github.io/editor/data/cars.json"
    ],
    gapminder: [
      url: "https://vega.github.io/vega-datasets/data/gapminder-health-income.csv"
    ],
    weather: [
      url: "https://vega.github.io/editor/data/weather.csv"
    ],
    stocks: [
      url: "https://vega.github.io/editor/data/stocks.csv"
    ],
    movies: [
      url: "https://vega.github.io/editor/data/movies.json"
    ],
    titanic: [
      url: "https://raw.githubusercontent.com/datasciencedojo/datasets/master/titanic.csv"
    ],
    penguins: [
      url: "https://raw.githubusercontent.com/vega/vega-datasets/next/data/penguins.json"
    ],
    flights: [
      url: "https://raw.githubusercontent.com/mwaskom/seaborn-data/master/flights.csv"
    ],
    tips: [url: "https://raw.githubusercontent.com/mwaskom/seaborn-data/master/tips.csv"],
    unemployment: [url: "https://vega.github.io/editor/data/unemployment-across-industries.json"]
  ]

  @valid_datasets @datasets
                  |> Keyword.keys()
                  |> Enum.sort()

  @doc """
  Reruns the url of the given dataset.

  Raises an error if the dataset is invalid.

  Currently the following datasets are supported:

  #{Enum.map(@valid_datasets, fn d -> "* " <> inspect(d) end) |> Enum.join("\n")}
  """
  @spec dataset(atom()) :: binary()
  def dataset(dataset) when is_atom(dataset) do
    case @datasets[dataset] do
      nil ->
        raise ArgumentError,
              "not supported dataset #{inspect(dataset)}, valid datasets: #{inspect(@valid_datasets)}"

      dataset ->
        Keyword.fetch!(dataset, :url)
    end
  end
end
