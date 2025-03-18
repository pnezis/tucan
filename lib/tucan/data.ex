defmodule Tucan.Data do
  @moduledoc false

  # Module for inferring types from input data
  #
  # Copied from https://github.com/livebook-dev/vega_lite/blob/main/lib/vega_lite/data.ex

  @doc """
  Returns a map with each column and its respective inferred type for the given data.
  """
  @spec column_types(Table.Reader.t()) :: map() | nil
  def column_types(data) do
    with true <- implements?(Table.Reader, data),
         data = {_, %{columns: [_ | _] = columns}, _} <- Table.Reader.init(data),
         true <- Enum.all?(columns, &implements?(String.Chars, &1)) do
      types = infer_types(data)
      Enum.zip_with(columns, types, fn column, type -> {to_string(column), type} end) |> Map.new()
    else
      _ -> nil
    end
  end

  defp implements?(protocol, value), do: protocol.impl_for(value) != nil

  defp infer_types({:columns, %{columns: _columns}, data}) do
    Enum.map(data, fn data -> data |> Enum.at(0) |> type_of() end)
  end

  defp infer_types({:rows, %{columns: _columns}, data}) do
    {:ok, row} = Enum.fetch(data, 0)
    Enum.map(row, &type_of/1)
  end

  defp type_of(%mod{}) when mod in [Date, NaiveDateTime, DateTime], do: :temporal

  defp type_of(data) when is_number(data), do: :quantitative

  defp type_of(data) when is_binary(data) do
    if date?(data) or date_time?(data), do: :temporal, else: :nominal
  end

  defp type_of(data) when is_atom(data), do: :nominal

  defp type_of(_), do: nil

  defp date?(value), do: match?({:ok, _}, Date.from_iso8601(value))
  defp date_time?(value), do: match?({:ok, _, _}, DateTime.from_iso8601(value))
end
