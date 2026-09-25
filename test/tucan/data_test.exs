defmodule Tucan.DataTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  describe "column_types/1" do
    test "infers types for row tables" do
      data = [
        %{name: "John", age: 30, city: "New York", birth_date: ~D[1990-01-01]},
        %{name: "Jane", age: 25, city: "Los Angeles", birth_date: ~D[1995-01-01]},
        %{name: "Jim", age: 35, city: "Chicago", birth_date: ~D[1985-01-01]}
      ]

      assert Tucan.Data.column_types(data) == %{
               "name" => :nominal,
               "age" => :quantitative,
               "city" => :nominal,
               "birth_date" => :temporal
             }
    end

    test "infers types for column tables" do
      data = [
        [name: "John", age: 30, city: "New York", birth_date: ~D[1990-01-01]],
        [name: "Jane", age: 25, city: "Los Angeles", birth_date: ~D[1995-01-01]],
        [name: "Jim", age: 35, city: "Chicago", birth_date: ~D[1985-01-01]]
      ]

      assert Tucan.Data.column_types(data) == %{
               "name" => :nominal,
               "age" => :quantitative,
               "city" => :nominal,
               "birth_date" => :temporal
             }
    end

    test "infers temporal data in various formats" do
      data = [
        [
          date: ~D[2020-01-01],
          naive_date_time: ~N[2020-01-01 10:00:00],
          date_time: ~U[2020-01-01 10:00:00Z],
          date_str: "2020-01-01",
          datetime_str: "2020-01-01T10:00:00Z"
        ]
      ]

      assert Tucan.Data.column_types(data) == %{
               "date" => :temporal,
               "naive_date_time" => :temporal,
               "date_time" => :temporal,
               "date_str" => :temporal,
               "datetime_str" => :temporal
             }
    end

    test "infers time data as :time" do
      data = [
        [time: ~T[10:00:00], time_str: "10:00:00"]
      ]

      assert Tucan.Data.column_types(data) == %{
               "time" => :time,
               "time_str" => :time
             }
    end

    test "atoms are inferred as nominal" do
      data = [
        [module: :foo]
      ]

      assert Tucan.Data.column_types(data) == %{
               "module" => :nominal
             }
    end

    test "numeric strings are inferred as quantitative" do
      data = [
        %{int: "42", float: " 1.5 ", exp: "1e3", neg: "-0.5", mixed: "1.5 kg", zip: "01234"}
      ]

      assert Tucan.Data.column_types(data) == %{
               "int" => :quantitative,
               "float" => :quantitative,
               "exp" => :quantitative,
               "neg" => :quantitative,
               "mixed" => :nominal,
               "zip" => :quantitative
             }
    end

    test "with inconsistent data" do
      assert Tucan.Data.column_types([%{x: 1}, %{x: 2, y: 1}]) == %{"x" => :quantitative}
    end

    test "with empty row data" do
      assert Tucan.Data.column_types([%{}]) == %{}
    end

    test "not supported types are inferred as nil" do
      data = [items: [[1, 2]]]

      assert Tucan.Data.column_types(data) == %{
               "items" => nil
             }
    end
  end

  describe "inferred types in plots" do
    test "temporal type is used instead of quantitative" do
      data = [
        %{x: ~D[2020-01-01], y: "2020-01-01T10:00:00Z"},
        %{x: ~D[2020-01-02], y: "2020-01-02T10:00:00Z"}
      ]

      %VegaLite{spec: spec} = Tucan.scatter(data, "x", "y")
      assert get_in(spec, ["encoding", "x", "type"]) == "temporal"
      assert get_in(spec, ["encoding", "y", "type"]) == "temporal"
    end

    test "time is mapped to temporal" do
      data = [
        %{x: ~T[10:00:00], y: "10:00:00"}
      ]

      %VegaLite{spec: spec} = Tucan.lineplot(data, "x", "y")
      assert get_in(spec, ["encoding", "x", "type"]) == "temporal"
      assert get_in(spec, ["encoding", "y", "type"]) == "temporal"
    end

    test "temporal inferred types do not replace nominal values" do
      data = [
        %{x: ~D[2020-01-01], y: "2020-01-01T10:00:00Z"},
        %{x: ~D[2020-01-02], y: "2020-01-02T10:00:00Z"}
      ]

      %VegaLite{spec: spec} = Tucan.bar(data, "x", "y")
      assert get_in(spec, ["encoding", "x", "type"]) == "nominal"
      assert get_in(spec, ["encoding", "y", "type"]) == "temporal"
    end
  end

  describe "non quantitative data in quantitative channels" do
    @data [%{cat: "a", val: 1, str_val: "1.5"}, %{cat: "b", val: 2, str_val: "2.5"}]

    test "warns if a nominal field is encoded as quantitative" do
      warning = capture_io(:stderr, fn -> Tucan.scatter(@data, "cat", "val") end)

      assert warning =~
               ~s(the "cat" field is encoded as quantitative in the :x channel but its values are not numbers)

      assert warning =~ "x: [type: :quantitative]"

      assert capture_io(:stderr, fn -> Tucan.pie(@data, "cat", "val") end) =~
               ~s(the "cat" field is encoded as quantitative in the :theta channel)
    end

    test "does not warn for valid encodings" do
      assert capture_io(:stderr, fn ->
               Tucan.scatter(@data, "val", "str_val")
               Tucan.bar(@data, "cat", "val")
               Tucan.countplot(@data, "cat")
               Tucan.heatmap(@data, "cat", "cat", nil)
             end) == ""
    end

    test "does not warn if the type is explicitly set" do
      assert capture_io(:stderr, fn ->
               Tucan.scatter(@data, "cat", "val", x: [type: :quantitative])
               Tucan.scatter(@data, "cat", "val", x: [type: :nominal])
             end) == ""
    end

    test "does not warn for aggregations valid on nominal data" do
      assert capture_io(:stderr, fn ->
               Tucan.new(@data)
               |> Tucan.Utils.encode_field(:x, "cat", [x: []],
                 type: :quantitative,
                 aggregate: :distinct
               )
               |> Tucan.Utils.encode_field(:y, "cat", [y: []],
                 type: :quantitative,
                 aggregate: "count"
               )
             end) == ""
    end
  end
end
