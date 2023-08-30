defmodule Tucan.OptionsTest do
  use ExUnit.Case

  describe "take!/2" do
    test "returns selected default options" do
      options = Tucan.Options.take!([:width, :height])

      assert Keyword.keys(options) == [:width, :height]
    end

    test "merges default options with custom ones" do
      options = Tucan.Options.take!([:width, :height], foo: [type: :string])

      assert Keyword.keys(options) == [:width, :height, :foo]
    end

    test "raises in case of duplicates" do
      message = "the following options were defined more than once: [:width]"

      assert_raise ArgumentError, message, fn ->
        Tucan.Options.take!([:width, :width])
      end
    end

    test "merges options if they have the same key" do
      options = Tucan.Options.take!([:width], width: [doc: "updated docs"])

      assert Keyword.keys(options) == [:width]
      assert options[:width][:doc] == "updated docs"
      refute is_nil(options[:width][:type])
    end
  end

  test "to_nimble_schema!/1" do
    opts = [
      foo: [
        type: :string,
        doc: "a doc",
        default: "hello",
        dest: :mark,
        section: :info
      ]
    ]

    %NimbleOptions{schema: schema} = Tucan.Options.to_nimble_schema!(opts)

    refute Keyword.has_key?(schema[:foo], :dest)
    refute Keyword.has_key?(schema[:foo], :section)
    assert Keyword.has_key?(schema[:foo], :type)
  end
end
