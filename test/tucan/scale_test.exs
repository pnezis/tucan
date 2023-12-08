defmodule Tucan.ScaleTest do
  use ExUnit.Case

  alias Tucan.Scale.Utils, as: ScaleUtils
  alias VegaLite, as: Vl

  describe "set_color_scheme/3" do
    test "sets a color range" do
      vl =
        Vl.new()
        |> Vl.encode_field(:color, "color")
        |> Tucan.Scale.set_color_scheme(["red", "yellow", "blue"])

      assert get_in(vl.spec, ["encoding", "color", "scale"]) == %{
               "range" => ["red", "yellow", "blue"]
             }
    end

    test "sets a predefined scheme" do
      vl =
        Vl.new()
        |> Vl.encode_field(:color, "color")
        |> Tucan.Scale.set_color_scheme(:blues)

      assert get_in(vl.spec, ["encoding", "color", "scale"]) == %{
               "reverse" => false,
               "scheme" => "blues"
             }
    end

    test "sets a predefined scheme with reverse true" do
      vl =
        Vl.new()
        |> Vl.encode_field(:color, "color")
        |> Tucan.Scale.set_color_scheme(:blues, reverse: true)

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
                     |> Tucan.Scale.set_color_scheme(:other)
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

    test "raises if not supported encoding type" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :nominal)

      message =
        "a scale can be applied only on a quantitative or temporal encoding , :x is defined as :nominal"

      assert_raise ArgumentError, message, fn ->
        Tucan.Scale.set_x_scale(vl, :log)
      end
    end

    test "raises if invalid scale" do
      message =
        "scale can be one of [:linear, :pow, :sqrt, :symlog, :log, :time, :utc], got: :long"

      assert_raise ArgumentError, message, fn ->
        Tucan.Scale.set_x_scale(Vl.new(), :long)
      end

      assert_raise ArgumentError, message, fn ->
        Tucan.Scale.set_y_scale(Vl.new(), :long)
      end
    end

    test "raises if invalid scale for temporal encoding" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :temporal)
        |> Vl.encode_field(:y, "y", type: :temporal)

      message = ":sqrt cannot be applied on a temporal encoding, valid scales: [:time, :utc]"

      assert_raise ArgumentError, message, fn ->
        Tucan.Scale.set_x_scale(vl, :sqrt)
      end

      assert_raise ArgumentError, message, fn ->
        Tucan.Scale.set_y_scale(vl, :sqrt)
      end
    end

    test "raises if invalid scale for quantitative encoding" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:y, "y", type: :quantitative)

      message =
        ":time cannot be applied on a quantitative encoding, valid scales: [:linear, " <>
          ":pow, :sqrt, :symlog, :log]"

      assert_raise ArgumentError, message, fn ->
        Tucan.Scale.set_x_scale(vl, :time)
      end

      assert_raise ArgumentError, message, fn ->
        Tucan.Scale.set_y_scale(vl, :time)
      end
    end

    test "raises if invalid scale options set" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:x, "y", type: :quantitative)

      message = "unknown keys [:constant] in [constant: 1], the allowed keys are: [:exponent]"

      assert_raise ArgumentError, message, fn ->
        Tucan.Scale.set_x_scale(vl, :pow, constant: 1)
      end

      message = "unknown keys [:constant] in [constant: 1], the allowed keys are: [:base]"

      assert_raise ArgumentError, message, fn ->
        Tucan.Scale.set_y_scale(vl, :log, constant: 1)
      end

      message = "unknown keys [:base] in [base: 1], the allowed keys are: [:constant]"

      assert_raise ArgumentError, message, fn ->
        Tucan.Scale.set_y_scale(vl, :symlog, base: 1)
      end
    end

    test "sets the scales" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:y, "y", type: :quantitative)
        |> Vl.encode_field(:color, "z", type: :quantitative)
        |> Tucan.Scale.set_x_scale(:log)
        |> Tucan.Scale.set_y_scale(:sqrt)
        |> Tucan.Scale.set_scale(:color, :symlog)

      assert get_in(vl.spec, ["encoding", "x", "scale", "type"]) == "log"
      assert get_in(vl.spec, ["encoding", "y", "scale", "type"]) == "sqrt"
      assert get_in(vl.spec, ["encoding", "color", "scale", "type"]) == "symlog"
    end

    test "sets the scales with custom options" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:y, "y", type: :quantitative)
        |> Vl.encode_field(:color, "z", type: :quantitative)
        |> Tucan.Scale.set_x_scale(:log, base: 2)
        |> Tucan.Scale.set_y_scale(:pow, exponent: 0.3)
        |> Tucan.Scale.set_scale(:color, :symlog, constant: 2)

      assert get_in(vl.spec, ["encoding", "x", "scale"]) == %{"base" => 2, "type" => "log"}
      assert get_in(vl.spec, ["encoding", "y", "scale"]) == %{"exponent" => 0.3, "type" => "pow"}

      assert get_in(vl.spec, ["encoding", "color", "scale"]) == %{
               "constant" => 2,
               "type" => "symlog"
             }
    end
  end

  describe "set_domain" do
    test "raises if min >= max for x,y domain helpers" do
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
        |> Tucan.Scale.set_domain(:color, [-1.12, 2.33])

      assert get_in(vl.spec, ["encoding", "x", "scale", "domain"]) == [1, 10]
      assert get_in(vl.spec, ["encoding", "y", "scale", "domain"]) == [-1.12, 2.33]
      assert get_in(vl.spec, ["encoding", "color", "scale", "domain"]) == nil
    end

    test "set_xy_domain/3" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:y, "y", type: :quantitative)
        |> Tucan.Scale.set_xy_domain(1, 10)

      assert get_in(vl.spec, ["encoding", "x", "scale", "domain"]) == [1, 10]
      assert get_in(vl.spec, ["encoding", "y", "scale", "domain"]) == [1, 10]
    end

    test "set_domain can set arbitrary domains" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:y, "y", type: :temporal)
        |> Vl.encode_field(:color, "color", type: :nominal)
        |> Tucan.Scale.set_domain(:x, [1, 10])
        |> Tucan.Scale.set_domain(:y, [%{hours: 0}, %{hours: 24}])
        |> Tucan.Scale.set_domain(:color, ["a", "b", "c"])

      assert get_in(vl.spec, ["encoding", "x", "scale", "domain"]) == [1, 10]

      assert get_in(vl.spec, ["encoding", "y", "scale", "domain"]) == [
               %{"hours" => 0},
               %{"hours" => 24}
             ]

      assert get_in(vl.spec, ["encoding", "color", "scale", "domain"]) == ["a", "b", "c"]
    end
  end

  describe "put_options/3" do
    test "puts the given options if no scale is set" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Tucan.Scale.put_options(:x, domain: [1, 5], foo: "bar", bar: 1)

      assert get_in(vl.spec, ["encoding", "x", "scale"]) == %{
               "domain" => [1, 5],
               "foo" => "bar",
               "bar" => 1
             }
    end

    test "deep merges the existing options with the new ones" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Tucan.Scale.put_options(:x, domain: [1, 5], foo: "bar", bar: [a: 1, b: 2])
        |> Tucan.Scale.put_options(:x, domain: [5, 10], test: 2, bar: [a: 3, c: 2])

      assert get_in(vl.spec, ["encoding", "x", "scale"]) == %{
               "bar" => %{"a" => 3, "b" => 2, "c" => 2},
               "foo" => "bar",
               "test" => 2,
               "domain" => [5, 10]
             }
    end
  end
end
