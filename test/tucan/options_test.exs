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
end
