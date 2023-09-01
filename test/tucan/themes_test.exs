defmodule Tucan.ThemesTest do
  use ExUnit.Case

  @valid_themes [:excel, :ggplot2, :latimes]

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
end
