defmodule Tucan.ThemesTest do
  use ExUnit.Case

  @valid_themes [
    :dark,
    :excel,
    :five_thirty_eight,
    :ggplot2,
    :google_charts,
    :latimes,
    :power_bi,
    :quartz,
    :urban_institute,
    :vox
  ]

  describe "theme/1" do
    test "all valid themes are loaded" do
      for theme <- @valid_themes do
        assert Keyword.keyword?(Tucan.Themes.theme(theme))
      end
    end

    test "raises if invalid theme" do
      message = "invalid theme :foo, supported: #{inspect(@valid_themes)}"

      assert_raise ArgumentError, message, fn -> Tucan.Themes.theme(:foo) end
    end
  end

  describe "set_theme/2 with keyword list" do
    test "applies custom theme config" do
      vl =
        Tucan.scatter(:iris, "petal_width", "petal_length")
        |> Tucan.set_theme(background: "#0E0E0E", axis: [grid: false])

      spec = VegaLite.to_spec(vl)
      assert spec["config"]["background"] == "#0E0E0E"
      assert spec["config"]["axis"]["grid"] == false
    end

    test "raises on empty list" do
      assert_raise ArgumentError, ~r/non-empty keyword list/, fn ->
        Tucan.scatter(:iris, "petal_width", "petal_length")
        |> Tucan.set_theme([])
      end
    end

    test "raises if wrapper format is passed" do
      assert_raise ArgumentError, ~r/not a theme definition/, fn ->
        Tucan.scatter(:iris, "petal_width", "petal_length")
        |> Tucan.set_theme(name: :my_theme, theme: [background: "#fff"])
      end
    end
  end
end
