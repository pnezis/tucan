defmodule Tucan.Docs do
  @moduledoc """
  Helper doc utilities
  """

  @doc """
  Renders the original code and the vega-lite json spec

  It expects the input to be a `%VegaLite{}` struct.
  """
  def vl(code, _opts \\ []) do
    {%VegaLite{} = plot, _} = Code.eval_string(code, [], __ENV__)

    spec = VegaLite.to_spec(plot)

    """
    ```elixir
    #{code}
    ```

    ```vega-lite
    #{Jason.encode!(spec)}
    ```
    """
  end
end
