defmodule Tucan.UtilsTest do
  use ExUnit.Case

  alias Tucan.Utils
  alias VegaLite, as: Vl

  doctest Tucan.Utils

  describe "encoding_options/2" do
    test "with multi children views" do
      vl = Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :horizontal)

      assert_raise ArgumentError,
                   "encoding_options/2 expects a single view spec, multi view detected: :hconcat key is defined",
                   fn ->
                     Utils.encoding_options(vl, :x)
                   end
    end

    test "with a proper view" do
      vl = Vl.new() |> Vl.encode_field(:x, "x", foo: 1, bar: "abc")

      assert Utils.encoding_options(vl, :x) == %{
               "bar" => "abc",
               "field" => "x",
               "foo" => 1
             }
    end

    test "! version raises if the encoding does not exist" do
      assert_raise ArgumentError, "encoding for channel :x not found in the spec", fn ->
        Utils.encoding_options!(Vl.new(), :x)
      end
    end
  end

  describe "has_encoding?/2" do
    test "with multi children views" do
      vl = Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :horizontal)

      assert_raise ArgumentError,
                   "has_encoding?/2 expects a single view spec, multi view detected: :hconcat key is defined",
                   fn ->
                     Utils.has_encoding?(vl, :x)
                   end
    end

    test "with a proper view" do
      vl = Vl.new() |> Vl.encode_field(:x, "x", foo: 1, bar: "abc")

      assert Utils.has_encoding?(vl, :x)
      refute Utils.has_encoding?(vl, :y)
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
                     Utils.put_encoding_options(vl, :x, foo: "bar")
                   end

      assert_raise ArgumentError,
                   expected,
                   fn ->
                     Utils.put_encoding_options(vl.spec, :x, foo: "bar")
                   end
    end

    test "with missing encoding channel" do
      assert Utils.put_encoding_options(Vl.new(), :x, foo: "bar") == Vl.new()
    end

    test "merges options" do
      vl = Vl.new() |> Vl.encode_field(:x, "x", axis: [title: nil], type: :nominal)

      updated = Utils.put_encoding_options(vl, :x, axis: [subtitle: "title"])

      assert Utils.encoding_options(updated, :x) == %{
               "axis" => %{"subtitle" => "title", "title" => nil},
               "field" => "x",
               "type" => "nominal"
             }

      updated =
        Utils.put_encoding_options(vl, :x, axis: [title: "title", ticks: true], foo: 1)

      assert Utils.encoding_options(updated, :x) == %{
               "axis" => %{"title" => "title", "ticks" => true},
               "field" => "x",
               "type" => "nominal",
               "foo" => 1
             }

      updated = Utils.put_encoding_options(vl, :x, axis: nil)

      assert Utils.encoding_options(updated, :x) == %{
               "axis" => nil,
               "field" => "x",
               "type" => "nominal"
             }
    end

    test "deep merging" do
      vl = Vl.new() |> Vl.encode_field(:x, "x", foo: [bar: [baz: [value: 1]]], type: :nominal)

      updated =
        Utils.put_encoding_options(vl, :x, foo: [tmp: 2, bar: [baz: [value: 3, another: 4]]])

      assert Utils.encoding_options(updated, :x) == %{
               "foo" => %{"bar" => %{"baz" => %{"another" => 4, "value" => 3}}, "tmp" => 2},
               "field" => "x",
               "type" => "nominal"
             }
    end

    test "is applied recursively in all valid layers if multi-layer tucan plot" do
      vl =
        Vl.new()
        |> Vl.layers([
          Vl.new() |> Vl.encode_field(:x, "x"),
          Vl.new() |> Vl.encode_field(:x, "x2"),
          Vl.new() |> Vl.encode_field(:y, "y")
        ])

      expected =
        Vl.new()
        |> Vl.layers([
          Vl.new() |> Vl.encode_field(:x, "x", foo: 1),
          Vl.new() |> Vl.encode_field(:x, "x2", foo: 1),
          Vl.new() |> Vl.encode_field(:y, "y")
        ])

      assert Utils.put_encoding_options(vl, :x, foo: 1) == expected
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
                     Utils.drop_encoding_channels(vl, :x)
                   end
    end

    test "drops a single channel" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x")

      assert Utils.drop_encoding_channels(vl, :x) == Vl.new()
    end

    test "drops multiple channels" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x")
        |> Vl.encode_field(:y, "y")
        |> Vl.encode_field(:color, "y")

      assert Utils.drop_encoding_channels(vl, [:x, :color]) ==
               Vl.encode_field(Vl.new(), :y, "y")
    end
  end

  describe "put_in_spec/3" do
    test "adds non existing options" do
      expected = Vl.new(width: 100)

      assert Utils.put_in_spec(Vl.new(), :width, 100) == expected
      assert Utils.put_in_spec(Vl.new(), "width", 100) == expected
      assert Utils.put_in_spec(Vl.new(), "struct", Vl.new()).spec["struct"] == Vl.new()
    end

    test "replaces existing options" do
      expected = Vl.new(width: 100, height: 20)

      assert Utils.put_in_spec(Vl.new(width: 50, height: 20), :width, 100) == expected
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
                     Utils.encode_raw(vl, :x, foo: 1)
                   end

      assert_raise ArgumentError,
                   expected,
                   fn ->
                     Utils.encode_raw(vl.spec, :x, foo: 1)
                   end
    end

    test "encodes a channel" do
      expected = Vl.new() |> Vl.encode(:x, field: "x", type: :nominal)

      assert Tucan.Utils.encode_raw(Vl.new(), :x, field: "x", type: :nominal) == expected

      assert Tucan.Utils.encode_raw(Vl.new().spec, :x, field: "x", type: :nominal) ==
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
                     Utils.encode_field_raw(vl, :x, "x", foo: 1)
                   end

      assert_raise ArgumentError,
                   expected,
                   fn ->
                     Utils.encode_field_raw(vl.spec, :x, "x", foo: 1)
                   end
    end

    test "encodes a channel" do
      expected = Vl.new() |> Vl.encode_field(:x, "x", type: :nominal)

      assert Tucan.Utils.encode_field_raw(Vl.new(), :x, "x", type: :nominal) == expected

      assert Tucan.Utils.encode_field_raw(Vl.new().spec, :x, "x", type: :nominal) ==
               expected.spec
    end
  end

  describe "validate_layered_view/2" do
    test "raises with a non layered plot" do
      assert_raise ArgumentError, "expected a layered view", fn ->
        Utils.validate_layered_view!(Vl.new(), "")
      end

      assert_raise ArgumentError, "caller/2 expected a layered view", fn ->
        Utils.validate_layered_view!(Vl.new(), "caller/2")
      end
    end

    test "with a layered view" do
      vl = Vl.layers(Vl.new(), [])

      assert Utils.validate_layered_view!(vl, "") == :ok
    end
  end

  @multilayer_plot Vl.layers(Vl.new(), [Vl.new(), Vl.new()])
  @concatenated_plot Vl.concat(Vl.new(), [Vl.new(), Vl.new()], :horizontal)

  test "single_view?/1" do
    assert Utils.single_view?(Vl.new())
    refute Utils.single_view?(@multilayer_plot)
    refute Utils.single_view?(@concatenated_plot)
  end

  test "layered_view?/1" do
    refute Utils.layered_view?(Vl.new())
    assert Utils.layered_view?(@multilayer_plot)
    refute Utils.layered_view?(@concatenated_plot)
  end

  test "multi_view?/1" do
    refute Utils.multi_view?(Vl.new())
    assert Utils.multi_view?(@multilayer_plot)
    assert Utils.multi_view?(@concatenated_plot)
  end
end
