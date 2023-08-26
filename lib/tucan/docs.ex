defmodule Tucan.Docs do
  @moduledoc false

  @doc """
  Renders the original code and the vega-lite json spec

  It expects the input to be a `%VegaLite{}` struct.
  """
  @spec tucan(code :: binary(), opts :: keyword()) :: binary()
  def tucan(code, _opts \\ []) do
    {%VegaLite{} = plot, _} = Code.eval_string(code, [], __ENV__)

    spec = VegaLite.to_spec(plot)

    """
    ```elixir
    #{Code.format_string!(code)}
    ```

    ```vega-lite
    #{Jason.encode!(spec)}
    ```
    """
  end
end
