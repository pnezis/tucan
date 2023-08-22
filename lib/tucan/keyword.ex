defmodule Tucan.Keyword do
  @moduledoc false

  # Helper keyword utility functions

  @doc false
  def put_new_conditionally(keywords, key, value, fun) do
    cond do
      Keyword.has_key?(keywords, key) ->
        keywords

      fun.() ->
        Keyword.put(keywords, key, value)

      true ->
        keywords
    end
  end
end
