defmodule Tucan.ViewTest do
  use ExUnit.Case

  alias VegaLite, as: Vl

  test "set_background/2" do
    expected = Vl.new(background: "green")

    assert Tucan.View.set_background(Vl.new(), "green") == expected
  end

  test "set_view_background/2" do
    vl = Tucan.View.set_view_background(Vl.new(), "red")

    assert get_in(vl.spec, ["view"]) == %{"fill" => "red"}
  end
end
