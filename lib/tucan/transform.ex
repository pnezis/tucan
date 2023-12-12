defmodule Tucan.Transform do
  @moduledoc """
  An easy to use API for [`vega-lite` transforms](https://vega.github.io/vega-lite/docs/aggregate.html#transform).

  This module provides an interface for defining view-based transforms. The
  transformations are executed in the order in which they are specified in the
  array.
  """
  alias VegaLite, as: Vl

  aggregate_opts = [
    groupby: [
      type: {:list, :string},
      doc: """
      The data fields to group by. If not specified, a single group containing all data
      objects will be used.
      """
    ],
    operation: [
      type:
        {:in,
         [
           :count,
           :valid,
           :values,
           :missing,
           :distinct,
           :sum,
           :product,
           :mean,
           :variance,
           :variancep,
           :stdev,
           :stdevp,
           :stderr,
           :median,
           :q1,
           :q3,
           :ci0,
           :ci1,
           :min,
           :max,
           :argmin,
           :argmax
         ]},
      doc: """
      The aggregation operation to apply to the fields (e.g., `:sum`, `:mean`, or `:count`). The
      following aggregations are supported:

      * `:count` -	The total count of data objects in the group. Note that `Lcount` operates
      directly on the input objects and return the same value regardless of the provided field.
      * `:valid` -	The count of field values that are not null, undefined or NaN.
      * `:values` -	A list of data objects in the group.
      * `:missing` -	The count of null or undefined field values.
      * `:distinct` -	The count of distinct field values.
      * `:sum` -	The sum of field values.
      * `:product` - The product of field values.
      * `:mean` - The mean (average) field value.
      * `:average` - The mean (average) field value. Identical to mean.
      * `:variance` - The sample variance of field values.
      * `:variancep` - The population variance of field values.
      * `:stdev` - The sample standard deviation of field values.
      * `:stdevp` - The population standard deviation of field values.
      * `:stderr` - The standard error of field values.
      * `:median` -The median field value.
      * `:q1` - The lower quartile boundary of field values.
      * `:q3` - The upper quartile boundary of field values.
      * `:ci0` - The lower boundary of the bootstrapped 95% confidence interval of the mean
      field value.
      * `:ci1` - The upper boundary of the bootstrapped 95% confidence interval of the mean
      field value.
      * `:min` - The minimum field value.
      * `:max` - The maximum field value.
      * `:argmin` - An input data object containing the minimum field value.
      * `:argmax` - An input data object containing the maximum field value.
      """,
      required: true
    ],
    field: [
      type: :string,
      doc: """
      The data field for which to compute aggregate function. This is required for all aggregation
      operations except `:count`.
      """,
      required: true
    ],
    as: [
      type: :string,
      doc: """
      The output field names to use for each aggregated field.
      """,
      required: true
    ]
  ]

  @aggregate_schema NimbleOptions.new!(aggregate_opts)

  @doc """
  Applies an aggregate transform.

  ## Options

  #{NimbleOptions.docs(@aggregate_schema)}

  ## Examples

  ```tucan
  Tucan.new(:cars)
  |> Tucan.Transform.aggregate(
    operation: :mean,
    field: "Acceleration",
    as: "Mean Acceleration",
    groupby: ["Cylinders"]
  )
  |> Tucan.bar("Cylinders", "Mean Acceleration")
  ```
  """
  @spec aggregate(vl :: VegaLite.t(), opts :: Keyword.t()) :: VegaLite.t()
  def aggregate(vl, opts) do
    opts = NimbleOptions.validate!(opts, @aggregate_schema)

    Vl.transform(vl,
      aggregate: [[op: opts[:operation], field: opts[:field], as: opts[:as]]],
      groupby: opts[:groupby]
    )
  end
end
