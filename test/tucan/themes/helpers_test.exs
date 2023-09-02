defmodule Tucan.Themes.HelpersTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Tucan.Themes.Helpers

  setup tags do
    if tags[:fixture] do
      fixtures_path = Path.join(System.tmp_dir!(), "#{System.unique_integer([:positive])}")
      File.mkdir_p!(fixtures_path)

      on_exit(fn ->
        File.rm_rf!(fixtures_path)
      end)

      [fixtures_path: fixtures_path]
    else
      :ok
    end
  end

  describe "load_themes/1" do
    @tag :fixture
    test "loads valid themes", %{fixtures_path: fixtures_path} do
      foo = """
      [
        theme: [fill: "red"],
        name: :bar,
        doc: "a theme"
      ]
      """

      bar = """
      theme = [
        fill: "black"
      ]

      [
        theme: theme,
        name: :foo,
        doc: "a theme",
        source: "https://hexdocs.pm/tucan"
      ]
      """

      write_theme(fixtures_path, "bar.exs", foo)
      write_theme(fixtures_path, "foo.exs", bar)

      themes = Helpers.load_themes(fixtures_path)

      assert Keyword.has_key?(themes, :foo)
      assert Keyword.has_key?(themes, :bar)
    end

    @tag :fixture
    test "warns for invalid themes", %{fixtures_path: fixtures_path} do
      theme1 = """
      [
        name: :bar
      """

      theme2 = "[]"

      write_theme(fixtures_path, "theme1.exs", theme1)
      write_theme(fixtures_path, "theme2.exs", theme2)

      capture_io(:stderr, fn ->
        themes = Helpers.load_themes(fixtures_path)
        assert themes == []
      end)
    end
  end

  describe "validate_theme/1" do
    test "invalid themes" do
      assert {:error, _} = Helpers.validate_theme([])
      assert {:error, _} = Helpers.validate_theme(%{})
      assert {:error, _} = Helpers.validate_theme(theme: [], name: :foo, foo: 1)
    end
  end

  test "docs/2" do
    themes = [
      foo: [
        name: :foo,
        doc: "some docs",
        source: "http://hexdocs.pm/tucan",
        theme: [color: "red"]
      ],
      bar: [name: :bar, theme: [color: "black"]]
    ]

    example = "VegaLite.new()"

    docs = Helpers.docs(themes, example)

    assert docs =~ "some docs [[source](http://hexdocs.pm/tucan)]"
    assert docs =~ "### `:bar`"
    assert docs =~ ~s'"color":"red"'
    assert docs =~ ~s'"color":"black"'
  end

  defp write_theme(path, filename, content) do
    path = Path.join(path, filename)

    File.write!(path, content)
  end
end
