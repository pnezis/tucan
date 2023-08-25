defmodule TucanTest do
  use ExUnit.Case

  alias VegaLite, as: Vl
  doctest Tucan

  @dataset "dataset.csv"

  @cars_dataset Tucan.Datasets.dataset(:cars)
  @iris_dataset Tucan.Datasets.dataset(:iris)
  @tips_dataset Tucan.Datasets.dataset(:tips)

  describe "sanity checks" do
    setup do
      # add all plots here in alphabetical order (composite plots excluded)
      plot_funs = [
        {:bubble, fn opts -> Tucan.bubble(@dataset, "x", "y", "z", opts) end},
        {:countplot, fn opts -> Tucan.countplot(@dataset, "x", opts) end},
        {:density, fn opts -> Tucan.density(@dataset, "x", opts) end},
        {:density_heatmap, fn opts -> Tucan.density_heatmap(@dataset, "x", "y", opts) end},
        {:donut, fn opts -> Tucan.donut(@dataset, "x", "y", opts) end},
        {:histogram, fn opts -> Tucan.histogram(@dataset, "x", opts) end},
        {:lineplot, fn opts -> Tucan.lineplot(@dataset, "x", "y", opts) end},
        {:pie, fn opts -> Tucan.pie(@dataset, "x", "y", opts) end},
        {:scatter, fn opts -> Tucan.scatter(@dataset, "x", "y", opts) end},
        {:stripplot, fn opts -> Tucan.stripplot(@dataset, "x", opts) end}
      ]

      [plot_funs: plot_funs]
    end

    test "global spec settings are applicable to all plots", context do
      opts = [width: 135, height: 82, title: "Plot title"]

      for {name, plot_fun} <- context.plot_funs do
        vl = plot_fun.(opts)

        assert Map.get(vl.spec, "width") == 135, "width not set for #{inspect(name)}"
        assert Map.get(vl.spec, "height") == 82, "height not set for #{inspect(name)}"
        assert Map.get(vl.spec, "title") == "Plot title", "title not set for #{inspect(name)}"
      end
    end

    test "raises for invalid options", context do
      for {_name, plot_fun} <- context.plot_funs do
        assert_raise NimbleOptions.ValidationError, fn ->
          plot_fun.(invalid_option: 1)
        end
      end
    end
  end

  describe "histogram/3" do
    test "with default options" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@cars_dataset)
        |> Vl.transform(bin: true, as: "bin_Horsepower", field: "Horsepower")
        |> Vl.transform(
          aggregate: [[op: :count, as: "count_Horsepower"]],
          groupby: ["bin_Horsepower", "bin_Horsepower_end"]
        )
        |> Vl.mark(:bar, fill_opacity: 0.5)
        |> Vl.encode_field(:x, "bin_Horsepower", bin: [binned: true], title: "Horsepower")
        |> Vl.encode_field(:x2, "bin_Horsepower_end")
        |> Vl.encode_field(:y, "count_Horsepower", stack: nil, type: :quantitative)

      assert Tucan.histogram(@cars_dataset, "Horsepower") == expected
    end

    test "with relative set to true" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@cars_dataset)
        |> Vl.transform(bin: true, as: "bin_Horsepower", field: "Horsepower")
        |> Vl.transform(
          aggregate: [[op: :count, as: "count_Horsepower"]],
          groupby: ["bin_Horsepower", "bin_Horsepower_end"]
        )
        |> Vl.transform(
          joinaggregate: [[as: "total_count_Horsepower", field: "count_Horsepower", op: "sum"]],
          groupby: []
        )
        |> Vl.transform(
          calculate: "datum.count_Horsepower/datum.total_count_Horsepower",
          as: "percent_Horsepower"
        )
        |> Vl.mark(:bar, fill_opacity: 0.5)
        |> Vl.encode_field(:x, "bin_Horsepower", bin: [binned: true], title: "Horsepower")
        |> Vl.encode_field(:x2, "bin_Horsepower_end")
        |> Vl.encode_field(:y, "percent_Horsepower",
          stack: nil,
          type: :quantitative,
          title: "Relative Frequency",
          axis: [format: ".1~%"]
        )

      assert Tucan.histogram(@cars_dataset, "Horsepower", relative: true) == expected
    end

    test "with custom bin options" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@cars_dataset)
        |> Vl.transform(
          bin: [extent: [10, 100], maxbins: 30],
          as: "bin_Horsepower",
          field: "Horsepower"
        )
        |> Vl.transform(
          aggregate: [[op: :count, as: "count_Horsepower"]],
          groupby: ["bin_Horsepower", "bin_Horsepower_end"]
        )
        |> Vl.mark(:bar, fill_opacity: 0.5)
        |> Vl.encode_field(:x, "bin_Horsepower", bin: [binned: true], title: "Horsepower")
        |> Vl.encode_field(:x2, "bin_Horsepower_end")
        |> Vl.encode_field(:y, "count_Horsepower", stack: nil, type: :quantitative)

      assert Tucan.histogram(@cars_dataset, "Horsepower", extent: [10, 100], maxbins: 30) ==
               expected
    end

    test "with orient set to :vertical" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@cars_dataset)
        |> Vl.transform(bin: true, as: "bin_Horsepower", field: "Horsepower")
        |> Vl.transform(
          aggregate: [[op: :count, as: "count_Horsepower"]],
          groupby: ["bin_Horsepower", "bin_Horsepower_end"]
        )
        |> Vl.mark(:bar, fill_opacity: 0.5)
        |> Vl.encode_field(:y, "bin_Horsepower", bin: [binned: true], title: "Horsepower")
        |> Vl.encode_field(:y2, "bin_Horsepower_end")
        |> Vl.encode_field(:x, "count_Horsepower", stack: nil, type: :quantitative)

      assert Tucan.histogram(@cars_dataset, "Horsepower", orient: :vertical) == expected
    end

    test "with groupby and relative" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@cars_dataset)
        |> Vl.transform(bin: true, as: "bin_Horsepower", field: "Horsepower")
        |> Vl.transform(
          aggregate: [[op: :count, as: "count_Horsepower"]],
          groupby: ["bin_Horsepower", "bin_Horsepower_end", "Origin"]
        )
        |> Vl.transform(
          joinaggregate: [[as: "total_count_Horsepower", field: "count_Horsepower", op: "sum"]],
          groupby: ["Origin"]
        )
        |> Vl.transform(
          calculate: "datum.count_Horsepower/datum.total_count_Horsepower",
          as: "percent_Horsepower"
        )
        |> Vl.mark(:bar, fill_opacity: 0.5)
        |> Vl.encode_field(:x, "bin_Horsepower", bin: [binned: true], title: "Horsepower")
        |> Vl.encode_field(:x2, "bin_Horsepower_end")
        |> Vl.encode_field(:y, "percent_Horsepower",
          stack: nil,
          type: :quantitative,
          title: "Relative Frequency",
          axis: [format: ".1~%"]
        )
        |> Vl.encode_field(:color, "Origin")

      assert Tucan.histogram(@cars_dataset, "Horsepower", relative: true, color_by: "Origin") ==
               expected
    end

    test "with stacked set to true" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@cars_dataset)
        |> Vl.transform(bin: true, as: "bin_Horsepower", field: "Horsepower")
        |> Vl.transform(
          aggregate: [[op: :count, as: "count_Horsepower"]],
          groupby: ["bin_Horsepower", "bin_Horsepower_end", "Origin"]
        )
        |> Vl.transform(
          joinaggregate: [[as: "total_count_Horsepower", field: "count_Horsepower", op: "sum"]],
          groupby: ["Origin"]
        )
        |> Vl.transform(
          calculate: "datum.count_Horsepower/datum.total_count_Horsepower",
          as: "percent_Horsepower"
        )
        |> Vl.mark(:bar, fill_opacity: 0.5)
        |> Vl.encode_field(:x, "bin_Horsepower", bin: [binned: true], title: "Horsepower")
        |> Vl.encode_field(:x2, "bin_Horsepower_end")
        |> Vl.encode_field(:y, "percent_Horsepower",
          stack: true,
          type: :quantitative,
          title: "Relative Frequency",
          axis: [format: ".1~%"]
        )
        |> Vl.encode_field(:color, "Origin")

      assert Tucan.histogram(@cars_dataset, "Horsepower",
               relative: true,
               color_by: "Origin",
               stacked: true
             ) ==
               expected
    end
  end

  describe "scatter/4" do
    test "with default settings" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@iris_dataset)
        |> Vl.mark(:point)
        |> Vl.encode_field(:x, "petal_width", type: :quantitative, scale: [zero: false])
        |> Vl.encode_field(:y, "petal_length", type: :quantitative, scale: [zero: false])

      assert Tucan.scatter(@iris_dataset, "petal_width", "petal_length") == expected
    end

    test "with color shape and size groupings" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@iris_dataset)
        |> Vl.mark(:point)
        |> Vl.encode_field(:x, "petal_width", type: :quantitative, scale: [zero: false])
        |> Vl.encode_field(:y, "petal_length", type: :quantitative, scale: [zero: false])
        |> Vl.encode_field(:color, "species", type: :nominal)
        |> Vl.encode_field(:shape, "species", type: :nominal)
        |> Vl.encode_field(:size, "sepal_length", type: :quantitative)

      assert Tucan.scatter(@iris_dataset, "petal_width", "petal_length",
               color_by: "species",
               shape_by: "species",
               size_by: "sepal_length"
             ) == expected
    end
  end

  describe "bubble/5" do
    test "with default settings" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@iris_dataset)
        |> Vl.mark(:circle)
        |> Vl.encode_field(:x, "petal_width", type: :quantitative, scale: [zero: false])
        |> Vl.encode_field(:y, "petal_length", type: :quantitative, scale: [zero: false])
        |> Vl.encode_field(:size, "sepal_length", type: :quantitative)

      assert Tucan.bubble(@iris_dataset, "petal_width", "petal_length", "sepal_length") ==
               expected
    end

    test "with color_by set" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@iris_dataset)
        |> Vl.mark(:circle)
        |> Vl.encode_field(:x, "petal_width", type: :quantitative, scale: [zero: false])
        |> Vl.encode_field(:y, "petal_length", type: :quantitative, scale: [zero: false])
        |> Vl.encode_field(:size, "sepal_length", type: :quantitative)
        |> Vl.encode_field(:color, "species", type: :nominal)

      assert Tucan.bubble(@iris_dataset, "petal_width", "petal_length", "sepal_length",
               color_by: "species"
             ) ==
               expected
    end
  end

  describe "stripplot/3" do
    test "with default settings" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@tips_dataset)
        |> Vl.mark(:tick)
        |> Vl.encode_field(:x, "total_bill", type: :quantitative)

      assert Tucan.stripplot(@tips_dataset, "total_bill") == expected
    end

    test "with point style" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@tips_dataset)
        |> Vl.mark(:point, size: 16)
        |> Vl.encode_field(:x, "total_bill", type: :quantitative)

      assert Tucan.stripplot(@tips_dataset, "total_bill", style: :point) == expected
    end

    test "with jitter style" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@tips_dataset)
        |> Vl.transform(calculate: "sqrt(-2*log(random()))*cos(2*PI*random())", as: "jitter")
        |> Vl.mark(:point, size: 16)
        |> Vl.encode_field(:x, "total_bill", type: :quantitative)
        |> Vl.encode_field(:y_offset, "jitter", type: :quantitative, axis: nil)

      assert Tucan.stripplot(@tips_dataset, "total_bill", style: :jitter) == expected
    end

    test "with jitter and vertical orient" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@tips_dataset)
        |> Vl.transform(calculate: "sqrt(-2*log(random()))*cos(2*PI*random())", as: "jitter")
        |> Vl.mark(:point, size: 16)
        |> Vl.encode_field(:y, "total_bill", type: :quantitative)
        |> Vl.encode_field(:x_offset, "jitter", type: :quantitative, axis: nil)

      assert Tucan.stripplot(@tips_dataset, "total_bill", style: :jitter, orient: :vertical) ==
               expected
    end

    test "with jitter, vertical orient and grouping" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@tips_dataset)
        |> Vl.transform(calculate: "sqrt(-2*log(random()))*cos(2*PI*random())", as: "jitter")
        |> Vl.mark(:point, size: 16)
        |> Vl.encode_field(:y, "total_bill", type: :quantitative)
        |> Vl.encode_field(:x, "sex", type: :nominal)
        |> Vl.encode_field(:x_offset, "jitter", type: :quantitative, axis: nil)

      assert Tucan.stripplot(@tips_dataset, "total_bill",
               style: :jitter,
               orient: :vertical,
               group: "sex"
             ) ==
               expected
    end
  end

  describe "density/3" do
    test "with default values" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@iris_dataset)
        |> Vl.transform(
          density: "petal_width",
          counts: false,
          cumulative: false,
          maxsteps: 200,
          minsteps: 25
        )
        |> Vl.mark(:area, fill_opacity: 0.5)
        |> Vl.encode_field(:y, "density", type: :quantitative)
        |> Vl.encode_field(:x, "value", type: :quantitative, scale: [zero: false])

      assert Tucan.density(@iris_dataset, "petal_width") ==
               expected
    end

    test "with density values set" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@iris_dataset)
        |> Vl.transform(
          density: "petal_width",
          groupby: ["species"],
          bandwidth: 5,
          counts: true,
          cumulative: true,
          maxsteps: 30,
          minsteps: 5
        )
        |> Vl.mark(:area, fill_opacity: 0.5)
        |> Vl.encode_field(:y, "density", type: :quantitative)
        |> Vl.encode_field(:x, "value", type: :quantitative, scale: [zero: false])

      assert Tucan.density(@iris_dataset, "petal_width",
               counts: true,
               bandwidth: 5.0,
               minsteps: 5,
               maxsteps: 30,
               cumulative: true,
               groupby: ["species"]
             ) ==
               expected
    end

    test "with color_by set" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@iris_dataset)
        |> Vl.transform(
          density: "petal_width",
          counts: false,
          cumulative: false,
          maxsteps: 200,
          minsteps: 25,
          groupby: ["species"]
        )
        |> Vl.mark(:area, fill_opacity: 0.5)
        |> Vl.encode_field(:y, "density", type: :quantitative)
        |> Vl.encode_field(:x, "value", type: :quantitative, scale: [zero: false])
        |> Vl.encode_field(:color, "species")

      assert Tucan.density(@iris_dataset, "petal_width", color_by: "species") ==
               expected
    end

    test "with both groupby and color_by set" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@iris_dataset)
        |> Vl.transform(
          density: "petal_width",
          counts: false,
          cumulative: false,
          maxsteps: 200,
          minsteps: 25,
          groupby: ["other"]
        )
        |> Vl.mark(:area, fill_opacity: 0.5)
        |> Vl.encode_field(:y, "density", type: :quantitative)
        |> Vl.encode_field(:x, "value", type: :quantitative, scale: [zero: false])
        |> Vl.encode_field(:color, "species")

      assert Tucan.density(@iris_dataset, "petal_width", groupby: ["other"], color_by: "species") ==
               expected
    end
  end

  describe "density_heatmap/3" do
    test "with default values" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@iris_dataset)
        |> Vl.mark(:rect, fill_opacity: 0.5)
        |> Vl.encode_field(:x, "petal_width", type: :quantitative, bin: true)
        |> Vl.encode_field(:y, "petal_length", type: :quantitative, bin: true)
        |> Vl.encode(:color, type: :quantitative, aggregate: :count)

      assert Tucan.density_heatmap(@iris_dataset, "petal_width", "petal_length") ==
               expected
    end

    test "with z and aggregate set" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@iris_dataset)
        |> Vl.mark(:rect, fill_opacity: 0.5)
        |> Vl.encode_field(:x, "petal_width", type: :quantitative, bin: true)
        |> Vl.encode_field(:y, "petal_length", type: :quantitative, bin: true)
        |> Vl.encode_field(:color, "sepal_width", type: :quantitative, aggregate: :max)

      assert Tucan.density_heatmap(@iris_dataset, "petal_width", "petal_length",
               z: "sepal_width",
               aggregate: :max
             ) ==
               expected
    end
  end

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
        |> Vl.mark(:arc, fill_opacity: 0.5)
        |> Vl.encode_field(:theta, "value", type: :quantitative)
        |> Vl.encode_field(:color, "category")

      assert Tucan.pie(@pie_data, "value", "category") == expected
    end

    test "with aggregate statistic" do
      expected =
        Vl.new()
        |> Vl.data_from_url(Tucan.Datasets.dataset(:iris))
        |> Vl.mark(:arc, fill_opacity: 0.8)
        |> Vl.encode_field(:theta, "sepal_length", type: :quantitative, aggregate: :mean)
        |> Vl.encode_field(:color, "species")

      assert Tucan.pie(:iris, "sepal_length", "species", aggregate: :mean, fill_opacity: 0.8) ==
               expected
    end
  end

  describe "donut/4" do
    test "with default values" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@dataset)
        |> Vl.mark(:arc, inner_radius: 50, fill_opacity: 0.5)
        |> Vl.encode_field(:theta, "value", type: :quantitative)
        |> Vl.encode_field(:color, "category")

      assert Tucan.donut(@dataset, "value", "category") == expected
    end

    test "with set inner radius" do
      expected =
        Vl.new()
        |> Vl.data_from_url(@dataset)
        |> Vl.mark(:arc, inner_radius: 20, fill_opacity: 0.5)
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

  describe "color_by/3" do
    test "applies encoding on single view plot" do
      expected =
        Vl.new()
        |> Vl.encode_field(:color, "field", foo: 1, bar: "a")

      assert Tucan.color_by(Vl.new(), "field", foo: 1, bar: "a") == expected
    end

    test "applies encoding recursively" do
      test_plots = concatenated_test_plots(:color)

      for {vl, expected} <- test_plots do
        assert Tucan.color_by(vl, "field", recursive: true) == expected
      end
    end
  end

  describe "shape_by/3" do
    test "applies encoding on single view plot" do
      expected =
        Vl.new()
        |> Vl.encode_field(:shape, "field", foo: 1, bar: "a")

      assert Tucan.shape_by(Vl.new(), "field", foo: 1, bar: "a") == expected
    end

    test "applies encoding recursively" do
      test_plots = concatenated_test_plots(:shape)

      for {vl, expected} <- test_plots do
        assert Tucan.shape_by(vl, "field", recursive: true) == expected
      end
    end
  end

  describe "fill_by/3" do
    test "applies encoding on single view plot" do
      expected =
        Vl.new()
        |> Vl.encode_field(:fill, "field", foo: 1, bar: "a")

      assert Tucan.fill_by(Vl.new(), "field", foo: 1, bar: "a") == expected
    end

    test "applies encoding recursively" do
      test_plots = concatenated_test_plots(:fill)

      for {vl, expected} <- test_plots do
        assert Tucan.fill_by(vl, "field", recursive: true) == expected
      end
    end
  end

  describe "size_by/3" do
    test "applies encoding on single view plot" do
      expected =
        Vl.new()
        |> Vl.encode_field(:size, "field", foo: 1, bar: "a")

      assert Tucan.size_by(Vl.new(), "field", foo: 1, bar: "a") == expected
    end

    test "applies encoding recursively" do
      test_plots = concatenated_test_plots(:size)

      for {vl, expected} <- test_plots do
        assert Tucan.size_by(vl, "field", recursive: true) == expected
      end
    end
  end

  describe "stroke_dash_by/3" do
    test "applies encoding on single view plot" do
      expected =
        Vl.new()
        |> Vl.encode_field(:stroke_dash, "field", foo: 1, bar: "a")

      assert Tucan.stroke_dash_by(Vl.new(), "field", foo: 1, bar: "a") == expected
    end

    test "applies encoding recursively" do
      test_plots = concatenated_test_plots(:stroke_dash)

      for {vl, expected} <- test_plots do
        assert Tucan.stroke_dash_by(vl, "field", recursive: true) == expected
      end
    end
  end

  describe "set_width/2" do
    test "sets the width" do
      vl = Tucan.set_width(Vl.new(), 100)

      assert vl.spec["width"] == 100
    end

    test "can be called multiple times" do
      vl =
        Vl.new()
        |> Tucan.set_width(100)
        |> Tucan.set_width(300)

      assert vl.spec["width"] == 300
    end
  end

  describe "set_height/2" do
    test "sets the height" do
      vl = Tucan.set_height(Vl.new(), 100)

      assert vl.spec["height"] == 100
    end

    test "can be called multiple times" do
      vl =
        Vl.new()
        |> Tucan.set_height(100)
        |> Tucan.set_height(300)

      assert vl.spec["height"] == 300
    end
  end

  describe "set_title/3" do
    test "sets the title" do
      vl = Tucan.set_title(Vl.new(), "A title")

      assert vl.spec["title"]["text"] == "A title"
    end

    test "with extra options" do
      vl = Tucan.set_title(Vl.new(), "A title", color: "red")

      assert vl.spec["title"] == %{"color" => "red", "text" => "A title"}
    end
  end

  defp concatenated_test_plots(encoding) do
    vl_encoded = Vl.encode_field(Vl.new(), encoding, "field")

    horizontal_concat = Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :horizontal)
    horizontal_concat_expected = Vl.concat(Vl.new(), [vl_encoded, vl_encoded], :horizontal)

    vertical_concat = Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :vertical)
    vertical_concat_expected = Vl.concat(Vl.new(), [vl_encoded, vl_encoded], :vertical)

    wrappable_concat = Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :wrappable)
    wrappable_concat_expected = Vl.concat(Vl.new(), [vl_encoded, vl_encoded], :wrappable)

    nested_concat =
      Vl.concat(
        Vl.new(),
        [
          Vl.concat(Vl.new(), [Vl.new(), Vl.new(), Vl.new()], :horizontal),
          Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :horizontal)
        ],
        :vertical
      )

    nested_concat_expected =
      Vl.concat(
        Vl.new(),
        [
          Vl.concat(Vl.new(), [vl_encoded, vl_encoded, vl_encoded], :horizontal),
          Vl.concat(Vl.new(), [vl_encoded, vl_encoded], :horizontal)
        ],
        :vertical
      )

    [
      {horizontal_concat, horizontal_concat_expected},
      {vertical_concat, vertical_concat_expected},
      {wrappable_concat, wrappable_concat_expected},
      {nested_concat, nested_concat_expected}
    ]
  end
end
