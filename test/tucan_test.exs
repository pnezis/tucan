defmodule TucanTest do
  use ExUnit.Case
  doctest Tucan

  test "greets the world" do
    assert Tucan.hello() == :world
  end
end
