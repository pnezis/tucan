defmodule TucanTest do
  use ExUnit.Case

  alias VegaLite, as: Vl
  doctest Tucan

  @dataset "dataset.csv"

  describe "pie/4" do
    @pie_data [
      %{category: "A", value: 30},
      %{category: "B", value: 45},
      %{category: "C", value: 25}
    ]

    test "with default options" do
      expected =
        Vl.new()
        |> Vl.data_from_values(@pie_data)
        |> Vl.mark(:arc)
        |> Vl.encode_field(:theta, "value", type: :quantitative)
        |> Vl.encode_field(:color, "category")

      assert Tucan.pie(@pie_data, "value", "category") == expected
    end

    test "with aggregate statistic" do
      expected =
        Vl.new()
        |> Vl.data_from_url(Tucan.Datasets.dataset(:iris))
        |> Vl.mark(:arc)
        |> Vl.encode_field(:theta, "sepal_length", type: :quantitative, aggregate: :mean)
        |> Vl.encode_field(:color, "species")

      assert Tucan.pie(:iris, "sepal_length", "species", aggregate: :mean) == expected
    end
  end

  describe "donut/4" do
    test "with default values" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@dataset)
        |> Vl.mark(:arc, inner_radius: 50)
        |> Vl.encode_field(:theta, "value", type: :quantitative)
        |> Vl.encode_field(:color, "category")

      assert Tucan.donut(@dataset, "value", "category") == expected
    end

    test "with set inner radius" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@dataset)
        |> Vl.mark(:arc, inner_radius: 20)
        |> Vl.encode_field(:theta, "value", type: :quantitative)
        |> Vl.encode_field(:color, "category")

      assert Tucan.donut(@dataset, "value", "category", inner_radius: 20) == expected
    end
  end

  describe "countplot/3" do
    test "with default options" do
      data = [
        %{category: "A"},
        %{category: "B"},
        %{category: "A"},
        %{category: "C"},
        %{category: "B"}
      ]

      expected =
        Vl.new()
        |> Vl.data_from_values(data)
        |> Vl.mark(:bar, fill_opacity: 0.5)
        |> Vl.encode_field(:x, "type", type: :nominal)
        |> Vl.encode_field(:y, "type", aggregate: :count)

      assert Tucan.countplot(data, "type") == expected
    end

    test "with orient flag set" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@dataset)
        |> Vl.mark(:bar, fill_opacity: 0.5)
        |> Vl.encode_field(:y, "type", type: :nominal)
        |> Vl.encode_field(:x, "type", aggregate: :count)

      assert Tucan.countplot(@dataset, "type", orient: :vertical) == expected
    end

    test "with color_by set" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@dataset)
        |> Vl.mark(:bar, fill_opacity: 0.5)
        |> Vl.encode_field(:x, "type", type: :nominal)
        |> Vl.encode_field(:y, "type", aggregate: :count)
        |> Vl.encode_field(:color, "group")

      assert Tucan.countplot(@dataset, "type", color_by: "group") == expected
    end

    test "with color_by and stacked set to false" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@dataset)
        |> Vl.mark(:bar, fill_opacity: 0.5)
        |> Vl.encode_field(:x, "type", type: :nominal)
        |> Vl.encode_field(:y, "type", aggregate: :count)
        |> Vl.encode_field(:color, "group")
        |> Vl.encode_field(:x_offset, "group")

      assert Tucan.countplot(@dataset, "type", color_by: "group", stacked: false) == expected
    end

    test "with color_by, stacked set to false and vertical orientation" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@dataset)
        |> Vl.mark(:bar, fill_opacity: 0.5)
        |> Vl.encode_field(:y, "type", type: :nominal)
        |> Vl.encode_field(:x, "type", aggregate: :count)
        |> Vl.encode_field(:color, "group")
        |> Vl.encode_field(:y_offset, "group")

      assert Tucan.countplot(@dataset, "type",
               color_by: "group",
               stacked: false,
               orient: :vertical
             ) == expected
    end
  end
end
