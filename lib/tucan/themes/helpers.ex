defmodule Tucan.Themes.Helpers do
  @moduledoc false

  # helper functions for loading themes from the themes top level folder

  @doc false
  @spec load_themes(path :: Path.t()) :: keyword()
  def load_themes(path) do
    themes_pattern = Path.join(path, "*.exs")

    Path.wildcard(themes_pattern)
    |> Enum.map(&load_theme/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn theme -> {theme[:name], theme} end)
  end

  defp load_theme(path) do
    with {:ok, theme} <- eval_theme(path),
         {:ok, theme} <- validate_theme(theme) do
      theme
    else
      {:error, reason} ->
        IO.warn(reason)
        nil
    end
  end

  defp eval_theme(path) do
    {theme, _bindings} = Code.eval_file(path)
    {:ok, theme}
  rescue
    _e -> {:error, "failed to load theme from #{path}"}
  end

  @doc false
  @spec validate_theme(theme :: keyword()) :: {:ok, keyword()} | {:error, binary()}
  def validate_theme(theme) do
    cond do
      not Keyword.keyword?(theme) ->
        {:error, "theme definition must be a keyword"}

      not has_required_keys?(theme) ->
        {:error, "theme definition must contain a :name and a :theme"}

      true ->
        case Keyword.validate(theme, [:theme, :name, :doc, :source]) do
          {:ok, theme} ->
            {:ok, theme}

          {:error, invalid} ->
            {:error, "the following theme attributes are not supported: #{inspect(invalid)}"}
        end
    end
  end

  defp has_required_keys?(theme),
    do: Keyword.has_key?(theme, :theme) and Keyword.has_key?(theme, :name)

  @doc false
  @spec docs(themes :: keyword(), example :: binary()) :: binary()
  def docs(themes, example),
    do: Enum.map_join(themes, "\n\n", fn {_name, opts} -> theme_docs(opts, example) end)

  defp theme_docs(opts, example) do
    theme_name =
      case opts[:source] do
        nil -> inspect(opts[:name])
        source -> "[#{opts[:name]}](#{source})"
      end

    {%VegaLite{} = vl, _} = Code.eval_string(example, [], __ENV__)

    spec =
      vl
      |> VegaLite.config(opts[:theme])
      |> VegaLite.config(legend: [disable: true])
      |> VegaLite.resolve(:scale, color: :independent)
      |> VegaLite.to_spec()
      |> Jason.encode!()

    """
    * #{theme_name} - #{opts[:doc]}

    ```vega-lite
    #{spec}
    ```
    """
  end
end
