defmodule Tucan.VegaLiteUtilsTest do
  use ExUnit.Case

  alias Tucan.VegaLiteUtils
  alias VegaLite, as: Vl

  doctest Tucan.VegaLiteUtils

  describe "encoding_options/2" do
    test "with multi children views" do
      vl = Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :horizontal)

      assert_raise ArgumentError,
                   "encoding_options/2 expects a single view spec, multi view detected: :hconcat key is defined",
                   fn ->
                     VegaLiteUtils.encoding_options(vl, :x)
                   end
    end

    test "with a proper view" do
      vl = Vl.new() |> Vl.encode_field(:x, "x", foo: 1, bar: "abc")

      assert VegaLiteUtils.encoding_options(vl, :x) == %{
               "bar" => "abc",
               "field" => "x",
               "foo" => 1
             }
    end
  end

  describe "has_encoding?/2" do
    test "with multi children views" do
      vl = Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :horizontal)

      assert_raise ArgumentError,
                   "has_encoding?/2 expects a single view spec, multi view detected: :hconcat key is defined",
                   fn ->
                     VegaLiteUtils.has_encoding?(vl, :x)
                   end
    end

    test "with a proper view" do
      vl = Vl.new() |> Vl.encode_field(:x, "x", foo: 1, bar: "abc")

      assert VegaLiteUtils.has_encoding?(vl, :x)
      refute VegaLiteUtils.has_encoding?(vl, :y)
    end
  end

  describe "put_encoding_options/3" do
    test "raises with multi children views" do
      vl = Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :horizontal)

      expected =
        "put_encoding_options/3 expects a single view spec, multi view detected: :hconcat key is defined"

      assert_raise ArgumentError,
                   expected,
                   fn ->
                     VegaLiteUtils.put_encoding_options(vl, :x, foo: "bar")
                   end

      assert_raise ArgumentError,
                   expected,
                   fn ->
                     VegaLiteUtils.put_encoding_options(vl.spec, :x, foo: "bar")
                   end
    end

    test "with missing encoding channel" do
      assert_raise ArgumentError,
                   "encoding for channel :x not found in the spec",
                   fn ->
                     VegaLiteUtils.put_encoding_options(Vl.new(), :x, foo: "bar")
                   end
    end

    test "merges options" do
      vl = Vl.new() |> Vl.encode_field(:x, "x", axis: [title: nil], type: :nominal)

      updated = VegaLiteUtils.put_encoding_options(vl, :x, axis: [subtitle: "title"])

      assert VegaLiteUtils.encoding_options(updated, :x) == %{
               "axis" => %{"subtitle" => "title", "title" => nil},
               "field" => "x",
               "type" => "nominal"
             }

      updated =
        VegaLiteUtils.put_encoding_options(vl, :x, axis: [title: "title", ticks: true], foo: 1)

      assert VegaLiteUtils.encoding_options(updated, :x) == %{
               "axis" => %{"title" => "title", "ticks" => true},
               "field" => "x",
               "type" => "nominal",
               "foo" => 1
             }

      updated = VegaLiteUtils.put_encoding_options(vl, :x, axis: nil)

      assert VegaLiteUtils.encoding_options(updated, :x) == %{
               "axis" => nil,
               "field" => "x",
               "type" => "nominal"
             }
    end

    test "deep merging" do
      vl = Vl.new() |> Vl.encode_field(:x, "x", foo: [bar: [baz: [value: 1]]], type: :nominal)

      updated =
        VegaLiteUtils.put_encoding_options(vl, :x,
          foo: [tmp: 2, bar: [baz: [value: 3, another: 4]]]
        )

      assert VegaLiteUtils.encoding_options(updated, :x) == %{
               "foo" => %{"bar" => %{"baz" => %{"another" => 4, "value" => 3}}, "tmp" => 2},
               "field" => "x",
               "type" => "nominal"
             }
    end
  end

  describe "drop_encoding_channels/2" do
    test "raises if not single view" do
      vl = Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :horizontal)

      expected =
        "drop_encoding_channels/2 expects a single view spec, multi view detected: :hconcat key is defined"

      assert_raise ArgumentError,
                   expected,
                   fn ->
                     VegaLiteUtils.drop_encoding_channels(vl, :x)
                   end
    end

    test "drops a single channel" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x")

      assert VegaLiteUtils.drop_encoding_channels(vl, :x) == Vl.new()
    end

    test "drops multiple channels" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x")
        |> Vl.encode_field(:y, "y")
        |> Vl.encode_field(:color, "y")

      assert VegaLiteUtils.drop_encoding_channels(vl, [:x, :color]) ==
               Vl.encode_field(Vl.new(), :y, "y")
    end
  end

  describe "put_in_spec/3" do
    test "adds non existing options" do
      expected = Vl.new(width: 100)

      assert VegaLiteUtils.put_in_spec(Vl.new(), :width, 100) == expected
    end

    test "replaces existing options" do
      expected = Vl.new(width: 100, height: 20)

      assert VegaLiteUtils.put_in_spec(Vl.new(width: 50, height: 20), :width, 100) == expected
    end
  end

  describe "encode_raw/3" do
    test "raises if not single view" do
      vl = Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :horizontal)

      expected =
        "encode_raw/3 expects a single view spec, multi view detected: :hconcat key is defined"

      assert_raise ArgumentError,
                   expected,
                   fn ->
                     VegaLiteUtils.encode_raw(vl, :x, foo: 1)
                   end

      assert_raise ArgumentError,
                   expected,
                   fn ->
                     VegaLiteUtils.encode_raw(vl.spec, :x, foo: 1)
                   end
    end

    test "encodes a channel" do
      expected = Vl.new() |> Vl.encode(:x, field: "x", type: :nominal)

      assert Tucan.VegaLiteUtils.encode_raw(Vl.new(), :x, field: "x", type: :nominal) == expected

      assert Tucan.VegaLiteUtils.encode_raw(Vl.new().spec, :x, field: "x", type: :nominal) ==
               expected.spec
    end
  end

  describe "encode_field_raw/4" do
    test "raises if not single view" do
      vl = Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :horizontal)

      expected =
        "encode_field_raw/4 expects a single view spec, multi view detected: :hconcat key is defined"

      assert_raise ArgumentError,
                   expected,
                   fn ->
                     VegaLiteUtils.encode_field_raw(vl, :x, "x", foo: 1)
                   end

      assert_raise ArgumentError,
                   expected,
                   fn ->
                     VegaLiteUtils.encode_field_raw(vl.spec, :x, "x", foo: 1)
                   end
    end

    test "encodes a channel" do
      expected = Vl.new() |> Vl.encode_field(:x, "x", type: :nominal)

      assert Tucan.VegaLiteUtils.encode_field_raw(Vl.new(), :x, "x", type: :nominal) == expected

      assert Tucan.VegaLiteUtils.encode_field_raw(Vl.new().spec, :x, "x", type: :nominal) ==
               expected.spec
    end
  end

  describe "prepend/append_layers/2" do
    test "raises with a non single view" do
      vl = Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :horizontal)

      expected =
        "append_layers/2 expects a single view spec, multi view detected: :hconcat key is defined"

      assert_raise ArgumentError,
                   expected,
                   fn ->
                     VegaLiteUtils.append_layers(vl, VegaLite.new())
                   end

      expected =
        "prepend_layers/2 expects a single view spec, multi view detected: :hconcat key is defined"

      assert_raise ArgumentError,
                   expected,
                   fn ->
                     VegaLiteUtils.prepend_layers(vl, VegaLite.new())
                   end
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

      assert VegaLiteUtils.append_layers(vl, layers) == expected_append

      expected_prepend =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers(layers ++ [input_layer])

      assert VegaLiteUtils.prepend_layers(vl, layers) == expected_prepend

      # with a single layer

      single_layer =
        Vl.new()
        |> Vl.mark(:area)
        |> Vl.encode_field(:x, "x")

      expected_append =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers([input_layer, single_layer])

      assert VegaLiteUtils.append_layers(vl, single_layer) == expected_append

      expected_prepend =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers([single_layer, input_layer])

      assert VegaLiteUtils.prepend_layers(vl, single_layer) == expected_prepend
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

      assert VegaLiteUtils.append_layers(vl, layers) == expected_append

      expected_prepend =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers(layers ++ input_layers)

      assert VegaLiteUtils.prepend_layers(vl, layers) == expected_prepend

      # with a single spec passed
      single_layer =
        Vl.new()
        |> Vl.mark(:area)
        |> Vl.encode_field(:x, "x")

      expected_append =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers(input_layers ++ [single_layer])

      assert VegaLiteUtils.append_layers(vl, single_layer) == expected_append

      expected_prepend =
        Vl.new()
        |> Vl.data_from_url("a_dataset")
        |> Vl.layers([single_layer] ++ input_layers)

      assert VegaLiteUtils.prepend_layers(vl, single_layer) == expected_prepend
    end
  end
end
