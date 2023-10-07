defmodule Tucan.LayersTest do
  use ExUnit.Case

  alias Tucan.Layers
  alias VegaLite, as: Vl

  describe "prepend/append/2" do
    test "raises with a non single view" do
      vl = Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :horizontal)

      expected =
        "append_layers/2 expects a single view spec, multi view detected: :hconcat key is defined"

      assert_raise ArgumentError,
                   expected,
                   fn ->
                     Layers.append_layers(vl, VegaLite.new())
                   end

      expected =
        "prepend_layers/2 expects a single view spec, multi view detected: :hconcat key is defined"

      assert_raise ArgumentError,
                   expected,
                   fn ->
                     Layers.prepend_layers(vl, VegaLite.new())
                   end
    end

    test "adds the layers into an empty view" do
      vl = Vl.data_from_url(Vl.new(), "a_dataset")

      # with a list of layers

      layers = [
        Vl.new()
        |> Vl.mark(:rect)
        |> Vl.encode_field(:x, "x"),
        Vl.new()
        |> Vl.mark(:area)
        |> Vl.encode_field(:y, "y")
      ]

      expected_append =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers(layers)

      assert Layers.append_layers(vl, layers) == expected_append

      expected_prepend =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers(layers)

      assert Layers.prepend_layers(vl, layers) == expected_prepend
    end

    test "adds the layers with a single view" do
      input_layer =
        Vl.new()
        |> Vl.mark(:point)
        |> Vl.encode_field(:x, "x")
        |> Vl.encode_field(:y, "y")

      vl = Vl.data_from_url(input_layer, "a_dataset")

      # with a list of layers

      layers = [
        Vl.new()
        |> Vl.mark(:rect)
        |> Vl.encode_field(:x, "x"),
        Vl.new()
        |> Vl.mark(:area)
        |> Vl.encode_field(:y, "y")
      ]

      expected_append =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers([input_layer] ++ layers)

      assert Layers.append_layers(vl, layers) == expected_append

      expected_prepend =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers(layers ++ [input_layer])

      assert Layers.prepend_layers(vl, layers) == expected_prepend

      # with a single layer

      single_layer =
        Vl.new()
        |> Vl.mark(:area)
        |> Vl.encode_field(:x, "x")

      expected_append =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers([input_layer, single_layer])

      assert Layers.append_layers(vl, single_layer) == expected_append

      expected_prepend =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers([single_layer, input_layer])

      assert Layers.prepend_layers(vl, single_layer) == expected_prepend
    end

    test "adds the layers with a layered single view" do
      input_layers = [
        Vl.new()
        |> Vl.mark(:point)
        |> Vl.encode_field(:x, "x")
        |> Vl.encode_field(:y, "y"),
        Vl.new()
        |> Vl.mark(:rect)
        |> Vl.encode_field(:x, "z")
      ]

      vl =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers(input_layers)

      # with a list of layers

      layers = [
        Vl.new()
        |> Vl.mark(:rect)
        |> Vl.encode_field(:x, "x"),
        Vl.new()
        |> Vl.mark(:area)
        |> Vl.encode_field(:y, "y")
      ]

      expected_append =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers(input_layers ++ layers)

      assert Layers.append_layers(vl, layers) == expected_append

      expected_prepend =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers(layers ++ input_layers)

      assert Layers.prepend_layers(vl, layers) == expected_prepend

      # with a single spec passed
      single_layer =
        Vl.new()
        |> Vl.mark(:area)
        |> Vl.encode_field(:x, "x")

      expected_append =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers(input_layers ++ [single_layer])

      assert Layers.append_layers(vl, single_layer) == expected_append

      expected_prepend =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers([single_layer] ++ input_layers)

      assert Layers.prepend_layers(vl, single_layer) == expected_prepend
    end
  end
end
