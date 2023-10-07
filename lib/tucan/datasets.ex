defmodule Tucan.Datasets.Docs do
  @moduledoc false

  @doc false
  @spec docs(datasets :: keyword()) :: String.t()
  def docs(datasets) do
    Enum.map_join(datasets, "\n", &dataset_docs/1)
  end

  defp dataset_docs({name, opts}) do
    """
    #### #{name}

    #{opts[:doc]} [[Data]](#{opts[:url]}).

    **Columns: ** #{Enum.map_join(opts[:columns], ", ", fn col -> "`#{col}`" end)}
    """
  end
end

defmodule Tucan.Datasets do
  @type t ::
          :barley
          | :cars
          | :corruption
          | :flights
          | :gapminder
          | :glue
          | :iris
          | :movies
          | :penguins
          | :stocks
          | :tips
          | :titanic
          | :unemployment
          | :weather

  # add datasets in alphabetical order
  @datasets [
    barley: [
      url: "https://vega.github.io/editor/data/barley.json",
      columns: ~w[yield variety year site],
      doc: """
      [Yield data](https://stat.ethz.ch/R-manual/R-devel/library/lattice/html/barley.html) from a
      Minnesota barley trial. Includes total yield in bushels per acre for 10 varieties at 6 sites
      in each of two years.
      """
    ],
    cars: [
      url: "https://vega.github.io/editor/data/cars.json",
      columns:
        ~w[Name Miles_per_Gallon Cylinders Displacement Horsepower Weight_in_lbs Acceleration Year Origin],
      doc: """
      This was the 1983 ASA Data Exposition dataset. The dataset was collected by Ernesto Ramos and
      David Donoho and dealt with automobiles. I don't remember the instructions for analysis. Data
      on mpg, cylinders, displacement, etc. (8 variables) for 406 different cars. [[Source]](http://lib.stat.cmu.edu/datasets/)
      """
    ],
    corruption: [
      url:
        "https://raw.githubusercontent.com/holtzy/The-Python-Graph-Gallery/master/static/data/corruption.csv",
      columns: ~w[country region year cpi iso3c hdi],
      doc: """
      Corruption Perceptions Index (CPI) and Human Development Index (HDI) for 176 countries,
      from 2012 to 2015.
      """
    ],
    flights: [
      url: "https://raw.githubusercontent.com/mwaskom/seaborn-data/master/flights.csv",
      columns: ~w[year month passengers],
      doc: """
      Monthly airline passengers from 1949 to 1960. 
      """
    ],
    gapminder: [
      url: "https://vega.github.io/vega-datasets/data/gapminder-health-income.csv",
      columns: ~w[country income health population region],
      doc: """
      [Gapminder](https://www.gapminder.org/) health & income by country data.
      """
    ],
    glue: [
      url: "https://raw.githubusercontent.com/mwaskom/seaborn-data/master/glue.csv",
      columns: ~w[Model Year Encoder Task Score],
      doc: """
      Data from the [GLUE (The General Language Understanding Evaluation) benchmark
      leaderboard](https://gluebenchmark.com/leaderboard).
      """
    ],
    iris: [
      url:
        "https://gist.githubusercontent.com/curran/a08a1080b88344b0c8a7/raw/0e7a9b0a5d22642a06d3d5b9bcbad9890c8ee534/iris.csv",
      doc: """
      This is one of the earliest datasets used in the literature on classification methods and widely
      used in statistics and machine learning.  The data set contains 3 classes of 50 instances each,
      where each class refers to a type of iris plant.
      """,
      columns: ~w[sepal_length sepal_width petal_length petal_width species]
    ],
    movies: [
      url: "https://vega.github.io/editor/data/movies.json",
      columns: [
        "Creative Type",
        "Director",
        "Distributor",
        "IMDB Rating",
        "IMDB Votes",
        "MPAA Rating",
        "Major Genre",
        "Production Budget",
        "Release Date",
        "Rotten Tomatoes Rating",
        "Running Time min",
        "Source",
        "Title",
        "US DVD Sales",
        "US Gross",
        "Worldwide Gross"
      ],
      doc: """
      Movies dataset including IMDB scores. The dataset has well known and intentionally included
      errors. This dataset is used for instructional purposes, including the need to reckon with
      dirty data.
      """
    ],
    penguins: [
      url: "https://raw.githubusercontent.com/vega/vega-datasets/next/data/penguins.json",
      columns: [
        "Beak Depth (mm)",
        "Beak Length (mm)",
        "Body Mass (g)",
        "Flipper Length (mm)",
        "Island",
        "Sex",
        "Species"
      ],
      doc: """
      The [dataset](https://github.com/allisonhorst/palmerpenguins) contains data for 344 penguins.
      There are 3 different species of penguins in this dataset, collected from 3 islands in the
      Palmer Archipelago, Antarctica. This is an excellent dataset for data exploration
      & visualization, as an alternative to `:iris`.

      Data were collected and made available by [Dr. Kristen Gorman](https://www.uaf.edu/cfos/people/faculty/detail/kristen-gorman.php)
      and the [Palmer Station, Antarctica LTER](https://pallter.marine.rutgers.edu/), a member of
      the [Long Term Ecological Research Network](https://lternet.edu/).
      """
    ],
    stocks: [
      url: "https://vega.github.io/editor/data/stocks.csv",
      columns: ~w[symbol date price],
      doc: "Daily closing prices of various stocks."
    ],
    tips: [
      url: "https://raw.githubusercontent.com/mwaskom/seaborn-data/master/tips.csv",
      columns: ~w[total_bill tip sex smoker day time size],
      doc: """
      [Tipping data](https://rdrr.io/cran/reshape2/man/tips.html) as collected by one waiter.
      Information about each tip he received over a period of a few months working in one restaurant
      is included.
      """
    ],
    titanic: [
      url: "https://raw.githubusercontent.com/datasciencedojo/datasets/master/titanic.csv",
      columns:
        ~w[PassengerId Survived Pclass Name Sex Age SibSp Parch Ticket Fare Cabin Embarked],
      doc: """
      Titanic survival data from the [legendary Kaggle competition](https://www.kaggle.com/competitions/titanic/data).
      """
    ],
    unemployment: [
      url: "https://vega.github.io/editor/data/unemployment-across-industries.json",
      columns: ~w[count date month rate series year],
      doc: """
      US unemployment data across various industries from 2000 to 2009.
      """
    ],
    weather: [
      url: "https://vega.github.io/editor/data/weather.csv",
      columns: ~w[date precipitation temp_max temp_min wind weather],
      doc: """
      Daily weather records from Seattle with metric units. [Data from NOAA](https://www.ncdc.noaa.gov/cdo-web/datatools/records).
      """
    ]
  ]

  @valid_datasets @datasets
                  |> Keyword.keys()
                  |> Enum.sort()

  @moduledoc """
  Common datasets for `Tucan` demos and docs.

  ## Supported datasets

  Currently the following datasets are supported:

  #{Tucan.Datasets.Docs.docs(@datasets)}
  """

  @doc """
  Reruns the url of the given dataset.

  Raises an error if the dataset is invalid.
  """
  @spec dataset(atom()) :: String.t()
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
