defmodule Tucan.DatasetsTest do
  use ExUnit.Case

  alias Tucan.Datasets.Docs, as: DatasetsDocs

  @valid_datasets [
    :barley,
    :cars,
    :corruption,
    :flights,
    :gapminder,
    :glue,
    :iris,
    :movies,
    :ohlc,
    :penguins,
    :stocks,
    :tips,
    :titanic,
    :unemployment,
    :weather
  ]

  test "returns the url to a valid dataset" do
    for dataset <- @valid_datasets do
      assert is_binary(Tucan.Datasets.dataset(dataset))
    end
  end

  test "raises if invalid dataset" do
    expected_message =
      "not supported dataset :invalid, valid datasets: #{inspect(@valid_datasets)}"

    assert_raise ArgumentError, expected_message, fn -> Tucan.Datasets.dataset(:invalid) end
  end

  test "renders the docs properly" do
    expected = """
    #### foo

    a dataset [[Data]](http://foo.bar).

    **Columns: ** `hello`, `bar`
    """

    assert DatasetsDocs.docs(
             foo: [url: "http://foo.bar", doc: "a dataset", columns: ~w[hello bar]]
           ) == expected
  end
end
