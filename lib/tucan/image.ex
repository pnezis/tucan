defmodule Tucan.Image do
  @moduledoc false
  alias VegaLite, as: Vl

  @compile {:no_warn_undefined, Nx}

  @doc """
  vega-lite representation for the input 2d-tensor
  """
  @spec show(tensor :: Nx.Tensor.t(), opts :: keyword()) :: VegaLite.t()
  def show(tensor, opts) when is_struct(tensor, Nx.Tensor) do
    assert_nx!()

    type = Nx.type(tensor)

    unless type in [{:u, 8}, {:f, 32}] do
      raise ArgumentError,
            "expected Nx.Tensor to have type {:u, 8} or {:f, 32}, got: #{inspect(type)}"
    end

    # TODO: maybe support RGB/RGBA images in the future
    {tensor, shape} =
      case Nx.shape(tensor) do
        shape = {_height, _width, channels} when channels == 1 ->
          {tensor, shape}

        {height, width} ->
          {Nx.reshape(tensor, {height, width, 1}), {height, width, 1}}

        shape ->
          raise ArgumentError,
                "expected Nx.Tensor to have shape {height, width} or {height, width, 1}, got: #{inspect(shape)}"
      end

    {height, width, 1} = shape

    x =
      Nx.tensor(Enum.to_list(0..(width - 1)))
      |> Nx.broadcast({height, width}, axes: [1])
      |> Nx.to_flat_list()

    y =
      Nx.tensor(Enum.to_list(0..(height - 1)))
      |> Nx.broadcast({height, width}, axes: [0])
      |> Nx.to_flat_list()

    v = Nx.to_flat_list(tensor)

    Vl.new(Keyword.take(opts, [:width, :height]))
    |> Vl.data_from_values(x: x, y: y, v: v)
    |> Vl.mark(:rect)
    |> Vl.encode_field(:x, "x", type: :ordinal)
    |> Vl.encode_field(:y, "y", type: :ordinal)
    |> Vl.encode_field(:color, "v", type: :quantitative)
    |> Tucan.Axes.set_enabled(false)
    |> Tucan.Scale.set_color_scheme(opts[:color_scheme] || :greys,
      reverse: Keyword.get(opts, :reverse, true)
    )
    |> Tucan.Legend.set_enabled(:color, false)
  end

  defp assert_nx! do
    unless Code.ensure_loaded?(Nx) do
      raise RuntimeError, """
      Tucan.imshow/2 depends on the :kino package.

      You can install it by adding

          {:nx, "~> 0.6"}

      to your dependency list.
      """
    end
  end
end
