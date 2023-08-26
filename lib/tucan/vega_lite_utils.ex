defmodule Tucan.VegaLiteUtils do
  @moduledoc """
  Helper low level utilities for interacting with a `VegaLite` struct
  """

  @doc """
  Gets the configured encoding options for the given `channel` or `nil` if not set.

  Raises in case of a non single view.

  ## Examples

      iex> VegaLite.new()
      ...> |> VegaLite.encode_field(:x, "x", foo: "bar")
      ...> |> Tucan.VegaLiteUtils.encoding_options(:x)
      %{"field" => "x", "foo" => "bar"}
  """
  @spec encoding_options(vl :: VegaLite.t(), channel :: atom()) :: map() | nil
  def encoding_options(vl, channel) do
    validate_single_view!(vl, "encoding_options/2")

    channel = to_vl_key(channel)
    get_in(vl.spec, ["encoding", channel])
  end

  @doc """
  Returns true if the given single view plot has the provided `channel` encoded, `false`
  otherwise.

  Raises in case of a non single view.

  ## Examples

      iex> Tucan.VegaLiteUtils.has_encoding?(VegaLite.new(), :x)
      false

      iex> Tucan.VegaLiteUtils.has_encoding?(VegaLite.encode_field(VegaLite.new(), :x, "x"), :x)
      true
  """
  @spec has_encoding?(vl :: VegaLite.t(), channel :: atom()) :: boolean()
  def has_encoding?(%VegaLite{spec: spec} = vl, channel) when is_atom(channel) do
    validate_single_view!(vl, "has_encoding?/2")

    spec
    |> Map.get("encoding", %{})
    |> Map.has_key?(to_vl_key(channel))
  end

  @doc """
  Puts and merges the given `opts` into the `encoding` options.

  The input can either by a `VegaLite` struct or the spec map. The options will be
  deep merged with the existing ones.

  The input vega lite representation must be a single view.

  It will raise an `ArgumentError` if:

  * The input `vl` is not a single view.
  * The encoding does not exist in the specification an `ArgumentError` will be raised.
  """
  @spec put_encoding_options(vl :: VegaLite.t() | map(), encoding :: atom(), opts :: keyword()) ::
          VegaLite.t()
  def put_encoding_options(%VegaLite{} = vl, channel, opts)
      when is_atom(channel) and is_list(opts) do
    %VegaLite{vl | spec: put_encoding_options(vl.spec, channel, opts)}
  end

  def put_encoding_options(%{} = spec, channel, opts) when is_atom(channel) and is_list(opts) do
    validate_single_view!(spec, "put_encoding_options/3")
    validate_channel!(spec, channel)
    validate_channel!(spec, channel)

    update_in(spec, ["encoding", to_vl_key(channel)], fn encoding_opts ->
      deep_merge(encoding_opts, opts_to_vl_props(opts))
    end)
  end

  @doc """
  Puts the given `opts` under the given `key` in the provided `VegaLite` struct.

  This is a destructive operation, any existing value for the provided `key` will be
  replaced by `opts`.
  """
  @spec put_in_spec(vl :: VegaLite.t(), key :: atom(), opts :: term()) :: VegaLite.t()
  def put_in_spec(%VegaLite{spec: spec} = vl, key, opts) do
    key = to_vl_key(key)
    opts = to_vl(opts)

    %VegaLite{vl | spec: Map.merge(spec, %{key => opts})}
  end

  @multi_view_only_keys ~w(layer hconcat vconcat concat repeat facet spec)a

  # validates that the specification corresponds to a single view plot
  defp validate_single_view!(%VegaLite{spec: spec}, caller),
    do: validate_single_view!(spec, caller)

  defp validate_single_view!(%{} = spec, caller) do
    for key <- @multi_view_only_keys, Map.has_key?(spec, to_vl_key(key)) do
      raise ArgumentError,
            "#{caller} expects a single view spec, multi view detected: #{inspect(key)} key is defined"
    end
  end

  # validates that the channel exists in the encoding options
  defp validate_channel!(%VegaLite{spec: spec}, channel) when is_atom(channel),
    do: validate_channel!(spec, channel)

  defp validate_channel!(%{} = spec, channel) when is_atom(channel) do
    encoding_opts = get_in(spec, ["encoding", to_vl_key(channel)])

    if is_nil(encoding_opts) do
      raise ArgumentError, "encoding for channel #{inspect(channel)} not found in the spec"
    end
  end

  @doc """
  Similar to `VegaLite.encode_field/4` but handles also plain maps.

  Accepts as input either a `VegaLite` struct or a plain map that is assumed to be
  a `VegaLite` spec, and encodes the given field.

  If the input is a `VegaLite` struct then a `VegaLite` is returned, otherwise a
  map is returned.

  This is useful in case you want to modify an existing multi-layer/multi-plot spec
  where you cannot call directly `VegaLite.encode_field/4`

  All provided options are converted to channel properties.
  """
  @spec encode_field_raw(
          vl :: VegaLite.t() | map(),
          channel :: atom(),
          field :: binary(),
          opts :: keyword()
        ) :: VegaLite.t() | map()
  def encode_field_raw(vl, channel, field, opts) do
    validate_single_view!(vl, "encode_field_raw/4")

    opts = Keyword.put(opts, :field, field)
    encode_raw(vl, channel, opts)
  end

  @doc """
  Similar to `VegaLite.encode/3` but handles also plain maps.

  Accepts as input either a `VegaLite` struct or a plain map that is assumed to be
  a `VegaLite` spec, and encodes the given field.

  If the input is a `VegaLite` struct then a `VegaLite` is returned, otherwise a
  map is returned.

  This is useful in case you want to modify an existing multi-layer/multi-plot spec
  where you cannot call directly `VegaLite.encode/3`

  All provided options are converted to channel properties.
  """
  @spec encode_raw(vl :: VegaLite.t() | map(), channel :: atom(), opts :: keyword()) ::
          VegaLite.t() | map()
  def encode_raw(%VegaLite{} = vl, channel, opts) do
    update_in(vl.spec, fn spec -> encode_raw(spec, channel, opts) end)
  end

  def encode_raw(%{} = spec, channel, opts) do
    validate_single_view!(spec, "encode_raw/3")

    channel = to_vl_key(channel)
    opts = to_vl(opts)

    encoding =
      spec
      |> Map.get("encoding", %{})
      |> Map.put(channel, opts)

    Map.put(spec, "encoding", encoding)
  end

  @doc """
  Drops the given encoding channel or channels.

  An error is raised if `vl` is not a single view.
  """
  @spec drop_encoding_channels(vl :: VegaLite.t(), channel :: atom() | [atom()]) :: VegaLite.t()
  def drop_encoding_channels(vl, channel) when is_atom(channel),
    do: drop_encoding_channels(vl, [channel])

  def drop_encoding_channels(vl, channels) when is_list(channels) do
    validate_single_view!(vl, "drop_encoding_channels/2")

    channels = Enum.map(channels, &to_vl_key/1)

    update_in(vl.spec, fn spec ->
      encoding =
        spec
        |> Map.get("encoding", %{})
        |> Map.drop(channels)

      if encoding == %{} do
        Map.drop(spec, ["encoding"])
      else
        Map.put(spec, "encoding", encoding)
      end
    end)
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
