defmodule Tucan.Keyword do
  @moduledoc false

  # Helper keyword utility functions

  @doc false
  @spec put_new_conditionally(
          keywords :: keyword(),
          key :: atom(),
          value :: term(),
          fun :: (-> boolean())
        ) :: keyword()
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

  @doc false
  @spec deep_merge(config1 :: keyword(), config2 :: keyword()) :: keyword()
  def deep_merge(config1, config2) when is_list(config1) and is_list(config2) do
    Keyword.merge(config1, config2, fn _, value1, value2 ->
      if Keyword.keyword?(value1) and Keyword.keyword?(value2) do
        deep_merge(value1, value2)
      else
        value2
      end
    end)
  end
end
