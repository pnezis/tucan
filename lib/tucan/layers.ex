defmodule Tucan.Layers do
  @moduledoc """
  Utility functions for working with layered plots.
  """

  @doc """
  Prepends the given layer or layers to the input specification.

  If no `layer` exists in the input spec, a new layer object will be added
  with the `encoding` and `mark` options of the input spec.

  Raises if the input `vl` is not a single view or layered specification.
  """
  @spec prepend(vl :: VegaLite.t(), VegaLite.t() | [VegaLite.t()]) :: VegaLite.t()
  def prepend(vl, layers), do: add_layers(vl, layers, :prepend, "Tucan.Layers.prepend/2")

  @doc """
  Appends the given layer or layers to the input specification.

  If no `layer` exists in the input spec, a new layer object will be added
  with the `encoding` and `mark` options of the input spec.

  Raises if the input `vl` is not a single view or layered specification.
  """
  @spec append(vl :: VegaLite.t(), VegaLite.t() | [VegaLite.t()]) :: VegaLite.t()
  def append(vl, layers), do: add_layers(vl, layers, :append, "Tucan.Layers.append/2")

  defp add_layers(vl, %VegaLite{} = layer, mode, caller),
    do: add_layers(vl, [layer], mode, caller)

  defp add_layers(vl, layers, mode, caller) when is_list(layers) do
    Tucan.Utils.validate_single_or_layered_view!(vl, caller)

    layers = extract_raw_layers(layers)

    update_in(vl.spec, fn spec ->
      spec
      |> maybe_enlayer()
      |> Map.update("layer", layers, fn input_layers ->
        case mode do
          :append -> input_layers ++ layers
          :prepend -> layers ++ input_layers
        end
      end)
    end)
  end

  defp extract_raw_layers(layers),
    do: Enum.map(layers, &(&1 |> VegaLite.to_spec() |> Map.delete("$schema")))

  @doc """
  Converts a single view plot to a layered plot.

  `encoding`, `mark` and `data` will be extracted and added to a new layer.
  """
  @spec to_layered(vl :: VegaLite.t()) :: VegaLite.t()
  def to_layered(vl) do
    Tucan.Utils.validate_single_view!(vl, "to_layered/1")

    update_in(vl.spec, fn spec -> maybe_enlayer(spec) end)
  end

  defp maybe_enlayer(%{"layer" => _layers} = spec), do: spec

  defp maybe_enlayer(spec) do
    layer_fields = ["encoding", "mark"]

    layer_spec = Map.take(spec, layer_fields)

    spec
    |> then(fn spec ->
      if layer_spec == %{} do
        spec
      else
        Map.put(spec, "layer", [layer_spec])
      end
    end)
    |> Map.drop(layer_fields)
  end
end
