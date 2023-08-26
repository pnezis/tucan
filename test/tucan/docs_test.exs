defmodule Tucan.DocsTest do
  use ExUnit.Case

  test "properly translates tucan code block" do
    code = """
    Tucan.scatter("http://a.dataset", "x", "y")
    """

    spec =
      Tucan.scatter("http://a.dataset", "x", "y")
      |> VegaLite.to_spec()
      |> Jason.encode!()

    expected = """
    ```elixir
    Tucan.scatter("http://a.dataset", "x", "y")
    ```

    ```vega-lite
    #{spec}
    ```
    """

    assert Tucan.Docs.tucan(code) == expected
  end
end
