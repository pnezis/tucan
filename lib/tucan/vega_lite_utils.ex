defmodule Tucan.VegaLiteUtils do
  @moduledoc """
  Helper low level utilities for interacting with a `VegaLite` struct
  """

  @doc """
  Puts the given `opts` into the `encoding` options.

  * If encoding already has some options these will be deep merged with the provided ones.
  * If the encoding does not exist in the specification an `ArgumentError` will be raised.
  """
  @spec put_encoding_options!(vl :: VegaLite.t(), encoding :: atom(), opts :: keyword()) ::
          VegaLite.t()
  def put_encoding_options!(vl, encoding, opts) do
    encoding = to_vl_key(encoding)
    validate_encoding!(vl, encoding)

    spec =
      update_in(vl.spec, ["encoding", encoding], fn encoding_opts ->
        deep_merge(encoding_opts, opts_to_vl_props(opts))
      end)

    update_vl_spec(vl, spec)
  end

  defp update_vl_spec(vl, spec), do: %VegaLite{vl | spec: spec}

  defp validate_encoding!(vl, encoding) do
    encoding_opts = get_in(vl.spec, ["encoding", encoding])

    if is_nil(encoding_opts) do
      raise ArgumentError, "encoding #{inspect(encoding)} not found in the spec"
    end
  end

  # these are copied verbatim from VegaLite
  defp opts_to_vl_props(opts) do
    opts |> Map.new() |> to_vl()
  end

  defp to_vl(value) when value in [true, false, nil], do: value

  defp to_vl(atom) when is_atom(atom), do: to_vl_key(atom)

  defp to_vl(%_{} = struct), do: struct

  defp to_vl(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {to_vl(key), to_vl(value)}
    end)
  end

  defp to_vl([{key, _} | _] = keyword) when is_atom(key) do
    Map.new(keyword, fn {key, value} ->
      {to_vl(key), to_vl(value)}
    end)
  end

  defp to_vl(list) when is_list(list) do
    Enum.map(list, &to_vl/1)
  end

  defp to_vl(value), do: value
  defp to_vl_key(key) when is_binary(key), do: key

  defp to_vl_key(key) when is_atom(key) do
    key |> to_string() |> snake_to_camel()
  end

  defp snake_to_camel(string) do
    [part | parts] = String.split(string, "_")
    Enum.join([String.downcase(part, :ascii) | Enum.map(parts, &String.capitalize(&1, :ascii))])
  end

  defp deep_merge(left, right) do
    Map.merge(left, right, fn _key, value_left, value_right ->
      do_deep_merge(value_left, value_right)
    end)
  end

  defp do_deep_merge(%{} = left, %{} = right),
    do: deep_merge(left, right)

  # We must keep the right part in every other case
  defp do_deep_merge(_left, right), do: right
end
