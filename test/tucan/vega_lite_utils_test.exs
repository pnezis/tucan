defmodule Tucan.VegaLiteUtilsTest do
  use ExUnit.Case

  alias VegaLite, as: Vl
  alias Tucan.VegaLiteUtils

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
end
