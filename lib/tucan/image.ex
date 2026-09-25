defmodule Tucan.Image do
  @moduledoc false
  alias VegaLite, as: Vl

  @compile {:no_warn_undefined, Nx}

  @doc """
  vega-lite representation for the input grayscale, RGB or RGBA image tensor
  """
  @spec show(tensor :: Nx.Tensor.t(), opts :: keyword()) :: VegaLite.t()
  def show(tensor, opts) when is_struct(tensor, Nx.Tensor) do
    assert_nx!()

    type = Nx.type(tensor)

    if type not in [{:u, 8}, {:f, 32}] do
      raise ArgumentError,
            "expected Nx.Tensor to have type {:u, 8} or {:f, 32}, got: #{inspect(type)}"
    end

    {tensor, channels} =
      case Nx.shape(tensor) do
        {_height, _width, channels} when channels in [1, 3, 4] ->
          {tensor, channels}

        {height, width} ->
          {Nx.reshape(tensor, {height, width, 1}), 1}

        shape ->
          raise ArgumentError,
                "expected Nx.Tensor to have shape {height, width} or {height, width, channels} " <>
                  "with 1 (grayscale), 3 (RGB) or 4 (RGBA) channels, got: #{inspect(shape)}"
      end

    {height, width, _channels} = Nx.shape(tensor)

    x =
      Nx.tensor(Enum.to_list(0..(width - 1)))
      |> Nx.broadcast({height, width}, axes: [1])
      |> Nx.to_flat_list()

    {start_index, end_index} =
      case opts[:origin] do
        :upper -> {0, height - 1}
        :lower -> {height - 1, 0}
      end

    step = if start_index <= end_index, do: 1, else: -1

    y =
      Nx.tensor(Enum.to_list(start_index..end_index//step))
      |> Nx.broadcast({height, width}, axes: [0])
      |> Nx.to_flat_list()

    v = pixel_values(tensor, channels)

    spec_opts = Keyword.take(opts, [:width, :height, :title])
    mark_opts = Keyword.take(opts, [:tooltip])

    Vl.new(spec_opts)
    |> Vl.data_from_values(x: x, y: y, v: v)
    |> Vl.mark(:rect, mark_opts)
    |> Vl.encode_field(:x, "x", type: :ordinal)
    |> Vl.encode_field(:y, "y", type: :ordinal)
    |> encode_color(channels, opts)
    |> Tucan.Axes.set_enabled(false)
  end

  defp pixel_values(tensor, 1), do: Nx.to_flat_list(tensor)

  defp pixel_values(tensor, channels) do
    tensor
    |> to_u8()
    |> Nx.to_flat_list()
    |> Enum.chunk_every(channels)
    |> Enum.map(&css_color/1)
  end

  # float images are expected to be in the [0, 1] range
  defp to_u8(tensor) do
    case Nx.type(tensor) do
      {:u, 8} ->
        tensor

      _float ->
        tensor
        |> Nx.clip(0, 1)
        |> Nx.multiply(255)
        |> Nx.round()
        |> Nx.as_type({:u, 8})
    end
  end

  defp css_color([r, g, b]), do: "#" <> Base.encode16(<<r, g, b>>, case: :lower)
  defp css_color([r, g, b, a]), do: "rgba(#{r}, #{g}, #{b}, #{Float.round(a / 255, 3)})"

  # grayscale data are mapped to the color scheme, RGB(A) pixels are used as is
  defp encode_color(vl, 1, opts) do
    vl
    |> Vl.encode_field(:color, "v", type: :quantitative)
    |> Tucan.Scale.set_color_scheme(opts[:color_scheme], reverse: opts[:reverse])
    |> Tucan.Legend.set_title(:color, nil)
    |> Tucan.Legend.set_enabled(:color, opts[:show_scale])
  end

  defp encode_color(vl, _channels, _opts) do
    Vl.encode_field(vl, :color, "v", type: :nominal, scale: nil, legend: nil)
  end

  defp assert_nx! do
    if !Code.ensure_loaded?(Nx) do
      raise RuntimeError, """
      Tucan.imshow/2 depends on the :nx package.

      You can install it by adding

          {:nx, "~> 0.6"}

      to your dependency list.
      """
    end
  end
end
