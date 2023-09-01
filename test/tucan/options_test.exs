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

  describe "docs/1" do
    test "properly rendered docs" do
      opts = [
        foo: [type: :string, doc: "an option", default: "a", section: :section1],
        bar: [type: :integer, doc: "another option", default: 1, section: :section1],
        baz: [type: :string, doc: "a baz option", required: true],
        xyz: [type: :string, doc: "an extra option", section: :other]
      ]

      # raises with invalid sections
      assert_raise KeyError, fn -> Tucan.Options.docs(opts) end

      # renders properly the docs if the sections are valid

      section_opts = [
        unknown: [order: -1],
        section1: [
          header: "Awesome Options",
          order: 100
        ],
        other: [
          header: "Another Section",
          order: 5,
          doc: "with some extra docs"
        ]
      ]

      expected = """
      * `:baz` (`t:String.t/0`) - Required. a baz option

      ### Another Section

      with some extra docs

      * `:xyz` (`t:String.t/0`) - an extra option

      ### Awesome Options

      * `:bar` (`t:integer/0`) - another option The default value is `1`.
      * `:foo` (`t:String.t/0`) - an option The default value is `"a"`.\
      """

      assert Tucan.Options.docs(opts, section_opts) == expected

      # sections order affects the output
      section_opts = [
        unknown: [order: -1],
        section1: [
          header: "Awesome Options",
          order: -100
        ],
        other: [
          header: "Another Section",
          order: 5,
          doc: "with some extra docs"
        ]
      ]

      expected = """
      ### Awesome Options

      * `:bar` (`t:integer/0`) - another option The default value is `1`.
      * `:foo` (`t:String.t/0`) - an option The default value is `"a"`.

      * `:baz` (`t:String.t/0`) - Required. a baz option

      ### Another Section

      with some extra docs

      * `:xyz` (`t:String.t/0`) - an extra option\
      """

      assert Tucan.Options.docs(opts, section_opts) == expected
    end
  end

  describe "custom validation functions" do
    test "number_between/3" do
      schema = [x: [type: {:custom, Tucan.Options, :number_between, [1, 5]}]]

      assert_valid_option([x: 3], schema, :x, 3)
      assert_valid_option([x: 3.6], schema, :x, 3.6)

      assert_invalid_option(
        [x: 0],
        schema,
        "expected a number between 1 and 5, got: 0"
      )

      assert_invalid_option(
        [x: 10],
        schema,
        "expected a number between 1 and 5, got: 10"
      )

      assert_invalid_option(
        [x: :an_atom],
        schema,
        "expected a number between 1 and 5, got: :an_atom"
      )
    end

    test "tooltip/1" do
      schema =
        opts_schema(
          tooltip: [
            type: {:custom, Tucan.Options, :tooltip, []}
          ]
        )

      assert_valid_option([tooltip: true], schema, :tooltip, true)
      assert_valid_option([tooltip: :encoding], schema, :tooltip, true)
      assert_valid_option([tooltip: :data], schema, :tooltip, content: :data)

      assert_invalid_option(
        [tooltip: 4],
        schema,
        "expected a boolean, :encoding or :data, got: 4"
      )
    end

    test "extent/1" do
      schema =
        opts_schema(
          extent: [
            type: {:custom, Tucan.Options, :extent, []}
          ]
        )

      assert_valid_option([extent: [5, 9]], schema, :extent, [5, 9])

      assert_invalid_option(
        [extent: [10, 5]],
        schema,
        "expected [min, max] where max > min, got: [10, 5]"
      )

      assert_invalid_option(
        [extent: :invalid],
        schema,
        "expected [min, max] where min, max numbers and max > min, got: :invalid"
      )
    end

    test "density_alias/1" do
      schema =
        opts_schema(
          alias: [
            type: {:custom, Tucan.Options, :density_alias, []}
          ]
        )

      assert_valid_option([alias: "hello"], schema, :alias, ["hello_value", "hello_density"])

      assert_invalid_option(
        [alias: 5],
        schema,
        "expected a string, got: 5"
      )
    end
  end

  defp opts_schema(opts), do: NimbleOptions.new!(opts)

  defp assert_valid_option(opts, schema, key, value) do
    assert {:ok, opts} = NimbleOptions.validate(opts, schema)
    assert opts[key] == value
  end

  defp assert_invalid_option(opts, schema, message) do
    assert {:error, %NimbleOptions.ValidationError{message: error}} =
             NimbleOptions.validate(opts, schema)

    assert error =~ message
  end
end
