defmodule Tucan.DatasetsTest do
  use ExUnit.Case

  @valid_datasets [
    :cars,
    :corruption,
    :flights,
    :gapminder,
    :iris,
    :movies,
    :penguins,
    :stocks,
    :tips,
    :titanic,
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
end
