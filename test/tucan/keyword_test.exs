defmodule Tucan.KeywordTest do
  use ExUnit.Case

  test "put_new_conditionally/4" do
    opts = [a: 1]

    assert Tucan.Keyword.put_new_conditionally(opts, :a, 3, fn -> true end) == [a: 1]
    assert Tucan.Keyword.put_new_conditionally(opts, :b, 3, fn -> true end) == [b: 3, a: 1]
    assert Tucan.Keyword.put_new_conditionally(opts, :b, 3, fn -> false end) == [a: 1]
  end

  test "deep_merge/2" do
    # flat lists
    assert Tucan.Keyword.deep_merge([a: 1, b: 2], c: 11, d: 12) == [a: 1, b: 2, c: 11, d: 12]
    assert Tucan.Keyword.deep_merge([], c: 11, d: 12) == [c: 11, d: 12]
    assert Tucan.Keyword.deep_merge([a: 1, b: 2], []) == [a: 1, b: 2]

    # deep lists
    assert Tucan.Keyword.deep_merge([a: 1, b: 2], a: [c: 1]) == [b: 2, a: [c: 1]]

    assert Tucan.Keyword.deep_merge([a: [c: 2], b: 2, c: 3], a: [c: 1, d: 4], b: 3, f: 5) == [
             c: 3,
             a: [c: 1, d: 4],
             b: 3,
             f: 5
           ]

    message = "expected a keyword list as the first argument, got: [1, 2]"

    assert_raise ArgumentError, message, fn ->
      Tucan.Keyword.deep_merge([1, 2], c: 11, d: 12)
    end
  end
end
