defmodule Tucan.ScaleTest do
  use ExUnit.Case

  alias Tucan.Scale.Utils, as: ScaleUtils
  alias VegaLite, as: Vl

  describe "set_scheme/3" do
    test "sets a color range" do
      vl =
        Vl.new()
        |> Vl.encode_field(:color, "color")
        |> Tucan.Scale.set_scheme(["red", "yellow", "blue"])

      assert get_in(vl.spec, ["encoding", "color", "scale"]) == %{
               "range" => ["red", "yellow", "blue"]
             }
    end

    test "sets a predefined scheme" do
      vl =
        Vl.new()
        |> Vl.encode_field(:color, "color")
        |> Tucan.Scale.set_scheme(:blues)

      assert get_in(vl.spec, ["encoding", "color", "scale"]) == %{
               "reverse" => false,
               "scheme" => "blues"
             }
    end

    test "sets a predefined scheme with reverse true" do
      vl =
        Vl.new()
        |> Vl.encode_field(:color, "color")
        |> Tucan.Scale.set_scheme(:blues, reverse: true)

      assert get_in(vl.spec, ["encoding", "color", "scale"]) == %{
               "reverse" => true,
               "scheme" => "blues"
             }
    end

    test "raises if invalid scheme" do
      assert_raise ArgumentError,
                   "invalid scheme :other, check the Tucan.Scale docs for supported color schemes",
                   fn ->
                     Vl.new()
                     |> Vl.encode_field(:color, "color")
                     |> Tucan.Scale.set_scheme(:other)
                   end
    end

    test "raises if no color encoding" do
      assert_raise ArgumentError, "encoding for channel :color not found in the spec", fn ->
        Tucan.Scale.set_scheme(Vl.new(), :blues)
      end
    end
  end

  test "schemes docs" do
    docs = ScaleUtils.schemes_doc([:foo, :bar, :baz])

    assert docs =~ ":foo"
    assert docs =~ ":bar"
    assert docs =~ ":baz"
  end

  describe "set_x/y_scale" do
    test "raises if encoding does not exist" do
      vl = Vl.new()

      assert_raise ArgumentError, "encoding for channel :x not found in the spec", fn ->
        Tucan.Scale.set_x_scale(vl, :log)
      end

      assert_raise ArgumentError, "encoding for channel :y not found in the spec", fn ->
        Tucan.Scale.set_y_scale(vl, :log)
      end
    end

    test "sets the scales" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:y, "y", type: :quantitative)
        |> Tucan.Scale.set_x_scale(:log)
        |> Tucan.Scale.set_y_scale(:sqrt)

      assert get_in(vl.spec, ["encoding", "x", "scale", "type"]) == "log"
      assert get_in(vl.spec, ["encoding", "y", "scale", "type"]) == "sqrt"
    end
  end

  describe "set_domain" do
    test "raises if encoding does not exist" do
      vl = Vl.new()

      assert_raise ArgumentError, "encoding for channel :x not found in the spec", fn ->
        Tucan.Scale.set_x_domain(vl, 1, 5)
      end

      assert_raise ArgumentError, "encoding for channel :y not found in the spec", fn ->
        Tucan.Scale.set_y_domain(vl, 1, 5)
      end
    end

    test "raises if min >= max" do
      vl = Vl.new()

      assert_raise ArgumentError,
                   "a domain min value cannot be greater than the max value, got [10, 5]",
                   fn ->
                     Tucan.Scale.set_x_domain(vl, 10, 5)
                   end

      assert_raise ArgumentError,
                   "a domain min value cannot be greater than the max value, got [5, 5]",
                   fn ->
                     Tucan.Scale.set_y_domain(vl, 5, 5)
                   end
    end

    test "sets the domains" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:y, "y", type: :quantitative)
        |> Tucan.Scale.set_x_domain(1, 10)
        |> Tucan.Scale.set_y_domain(-1.12, 2.33)

      assert get_in(vl.spec, ["encoding", "x", "scale", "domain"]) == [1, 10]
      assert get_in(vl.spec, ["encoding", "y", "scale", "domain"]) == [-1.12, 2.33]
    end
  end
end
