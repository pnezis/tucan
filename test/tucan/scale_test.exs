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
end
