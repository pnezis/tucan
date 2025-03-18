defmodule Tucan.Utils do
  @moduledoc false

  @doc """
  Gets the encoding options for the given channel.

  Raises an `ArgumentError` if the channel does not exist.
  """
  @spec encoding_options!(vl :: VegaLite.t(), channel :: atom()) :: map()
  def encoding_options!(vl, channel) do
    validate_channel!(vl.spec, channel)

    encoding_options(vl, channel)
  end

  @doc """
  Gets the configured encoding options for the given `channel` or `nil` if not set.

  Raises in case of a non single view.

  ## Examples

      iex> VegaLite.new()
      ...> |> VegaLite.encode_field(:x, "x", foo: "bar")
      ...> |> Tucan.Utils.encoding_options(:x)
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

      iex> Tucan.Utils.has_encoding?(VegaLite.new(), :x)
      false

      iex> Tucan.Utils.has_encoding?(VegaLite.encode_field(VegaLite.new(), :x, "x"), :x)
      true
  """
  @spec has_encoding?(vl :: VegaLite.t() | map(), channel :: atom()) :: boolean()
  def has_encoding?(%VegaLite{spec: spec}, channel) when is_atom(channel) do
    has_encoding?(spec, channel)
  end

  def has_encoding?(%{} = spec, channel) when is_atom(channel) do
    validate_single_view!(spec, "has_encoding?/2")

    spec
    |> Map.get("encoding", %{})
    |> Map.has_key?(to_vl_key(channel))
  end

  @doc """
  Puts and merges the given `opts` into the `encoding` options.

  The input can either by a `VegaLite` struct or the spec map. The options will be
  deep merged with the existing ones.

  The input vega lite representation must be a single view or a multi-layer plot.

  If the input is a multi-layer plot then the options will be applied to all
  layers containing the given containing channel.

  If the encoding does not exist the opts will not be set. Use `put_encoding_options!/3`
  for a more strict version.

  It will raise an `ArgumentError` if the input `vl` is not a single view or a
  multi-layer plot.
  """
  @spec put_encoding_options(vl :: VegaLite.t() | map(), encoding :: atom(), opts :: keyword()) ::
          VegaLite.t()
  def put_encoding_options(%VegaLite{} = vl, channel, opts)
      when is_atom(channel) and is_list(opts) do
    %VegaLite{vl | spec: put_encoding_options(vl.spec, channel, opts)}
  end

  def put_encoding_options(%{} = spec, channel, opts) when is_atom(channel) and is_list(opts) do
    validate_single_or_layered_view!(spec, "put_encoding_options/3")

    if Map.has_key?(spec, "layer") do
      layers = spec["layer"]

      layers =
        for layer <- layers do
          put_encoding_options_single_layer(layer, channel, opts)
        end

      Map.put(spec, "layer", layers)
    else
      put_encoding_options_single_layer(spec, channel, opts)
    end
  end

  defp put_encoding_options_single_layer(spec, channel, opts) do
    validate_single_view!(spec, "")

    case has_encoding?(spec, channel) do
      true ->
        update_in(spec, ["encoding", to_vl_key(channel)], fn encoding_opts ->
          deep_merge(encoding_opts, opts_to_vl_props(opts))
        end)

      false ->
        spec
    end
  end

  @doc """
  Puts the given `opts` under the given `key` in the provided `VegaLite` struct.

  This is a destructive operation, any existing value for the provided `key` will be
  replaced by `opts`.

  See also `put_in_spec_new/3`
  """
  @spec put_in_spec(vl :: VegaLite.t(), key :: atom() | String.t(), opts :: term()) ::
          VegaLite.t()
  def put_in_spec(%VegaLite{spec: spec} = vl, key, opts) do
    key = to_vl_key(key)
    opts = to_vl(opts)

    %VegaLite{vl | spec: Map.merge(spec, %{key => opts})}
  end

  @doc """
  Puts the given `opts` under the given `key` in the provided `VegaLite` struct if it does not already exist..
  """
  @spec put_in_spec_new(vl :: VegaLite.t(), key :: atom() | String.t(), opts :: term()) ::
          VegaLite.t()
  def put_in_spec_new(%VegaLite{spec: spec} = vl, key, opts) do
    key = to_vl_key(key)
    opts = to_vl(opts)

    %VegaLite{vl | spec: Map.put_new(spec, key, opts)}
  end

  @doc """
  Puts the given metadata key-value pair in the provided `VegaLite` struct.

  This will overwrite any existing metadata for the given key.
  """
  @spec put_tucan_metadata(vl :: VegaLite.t(), key :: atom(), value :: term()) ::
          VegaLite.t()
  def put_tucan_metadata(%VegaLite{spec: spec} = vl, key, value) do
    current_metadata = get_in(spec, ["__tucan__"]) || %{}
    key = to_vl_key(key)
    metadata = to_vl(value)

    put_in_spec(vl, "__tucan__", Map.put(current_metadata, key, metadata))
  end

  @multi_view_only_keys ~w(layer hconcat vconcat concat repeat facet spec)a

  @doc false
  @spec multi_view?(vl :: VegaLite.t()) :: boolean()
  def multi_view?(%VegaLite{spec: spec}) do
    Enum.any?(@multi_view_only_keys, &Map.has_key?(spec, to_vl_key(&1)))
  end

  @doc false
  @spec single_view?(vl :: VegaLite.t()) :: boolean()
  def single_view?(vl), do: !multi_view?(vl)

  @doc false
  @spec layered_view?(vl :: VegaLite.t()) :: boolean()
  def layered_view?(%VegaLite{spec: spec}), do: Map.has_key?(spec, "layer")

  # validates that the specification corresponds to a single view plot
  @doc false
  @spec validate_single_view!(
          vl :: VegaLite.t() | map(),
          caller :: String.t(),
          forbidden :: [atom()]
        ) ::
          :ok
  def validate_single_view!(vl, caller, forbidden \\ @multi_view_only_keys)

  def validate_single_view!(%VegaLite{spec: spec}, caller, forbidden),
    do: validate_single_view!(spec, caller, forbidden)

  def validate_single_view!(%{} = spec, caller, forbidden) do
    for key <- forbidden, Map.has_key?(spec, to_vl_key(key)) do
      raise ArgumentError,
            "#{caller} expects a single view spec, multi view detected: #{inspect(key)} key is defined"
    end

    :ok
  end

  @doc false
  @spec validate_single_or_layered_view!(vl :: VegaLite.t() | map(), caller :: String.t()) :: :ok
  def validate_single_or_layered_view!(vl, caller) do
    validate_single_view!(vl, caller, @multi_view_only_keys -- [:layer])
  end

  @doc false
  @spec validate_layered_view!(vl :: VegaLite.t() | map(), caller :: String.t()) :: :ok
  def validate_layered_view!(%VegaLite{} = vl, caller) do
    validate_layered_view!(vl.spec, caller)
  end

  def validate_layered_view!(spec, caller) do
    prefix =
      case caller do
        "" -> ""
        caller -> caller <> " "
      end

    case Map.has_key?(spec, "layer") do
      true -> :ok
      false -> raise ArgumentError, "#{prefix}expected a layered view"
    end
  end

  # validates that the channel exists in the encoding options
  defp validate_channel!(%{} = spec, channel) when is_atom(channel) do
    encoding_opts = get_in(spec, ["encoding", to_vl_key(channel)])

    if is_nil(encoding_opts) do
      raise ArgumentError, "encoding for channel #{inspect(channel)} not found in the spec"
    end
  end

  @doc """
  Override of `VegaLite.encode_field/4`.

  we use `encode_field` and `encode` instead of `Vl.encode_field` and `Vl.encode` in all
  tucan plots for the following reason:

  - we want to support setting custom vega-lite options on each encoding
    that may be included in the specification.
  - these options are passed in the options of the plots as encoding: [options]
    e.g. x: [...], y: []
  - by having this custom function we can ensure that:
     - the encoding options are extracted by the opts on each call and merged
    with the extra_opts the function call may set
     - if they are missing the tests will raise ensuring that we have properly
     set all possible options for each plot type
     - they are set with the proper precedence and deep merged with the extra
     - we can adjust the encoding type based on the inferred type of the field (if any)
  """
  @spec encode_field(
          vl :: VegaLite.t(),
          encoding :: atom(),
          field :: String.t(),
          opts :: keyword(),
          extra_opts :: keyword()
        ) :: VegaLite.t()
  def encode_field(vl, encoding, field, opts, extra_opts \\ []) do
    # encoding overrides are set by the user and take precedence over the inferred types
    encoding_overrides = Keyword.fetch!(opts, encoding)

    # if we have inferred the column type as temporal and it is marked as quantitative
    # we can safelyupdate it
    # TODO: we can do more checks here, e.g. raise if invalid inferred type
    field_type = get_in(vl.spec, ["__tucan__", "types", field])

    extra_opts =
      if field_type == "temporal" && extra_opts[:type] == :quantitative do
        Keyword.put(extra_opts, :type, :temporal)
      else
        extra_opts
      end

    encoding_opts = Tucan.Keyword.deep_merge(extra_opts, encoding_overrides)

    VegaLite.encode_field(vl, encoding, field, encoding_opts)
  end

  @doc """
  Similar override to `encode_field/5`
  """
  @spec encode(vl :: VegaLite.t(), encoding :: atom(), opts :: keyword(), extra_opts :: keyword()) ::
          VegaLite.t()
  def encode(vl, encoding, opts, extra_opts) do
    encoding_opts = Tucan.Keyword.deep_merge(extra_opts, Keyword.fetch!(opts, encoding))

    VegaLite.encode(vl, encoding, encoding_opts)
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
          channel :: atom() | String.t(),
          field :: String.t(),
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
  @spec encode_raw(vl :: VegaLite.t() | map(), channel :: atom() | String.t(), opts :: keyword()) ::
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

  @doc """
  If enabled adds a param for making the plot zoomable
  """
  @spec maybe_zoomable(vl :: VegaLite.t(), enable :: boolean()) :: VegaLite.t()
  def maybe_zoomable(vl, false), do: vl

  def maybe_zoomable(vl, true),
    do: VegaLite.param(vl, "_grid", select: "interval", bind: "scales")
end
