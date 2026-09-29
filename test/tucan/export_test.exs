defmodule Tucan.ExportTest do
  use ExUnit.Case

  @vl Tucan.scatter([x: [1, 2, 3], y: [4, 5, 6]], "x", "y")

  test "to_json/1" do
    assert %{"mark" => %{"type" => "point"}} = @vl |> Tucan.Export.to_json() |> Jason.decode!()
  end

  test "to_html/2" do
    for html <- [Tucan.Export.to_html(@vl), Tucan.Export.to_html(@vl, bundle: false)] do
      assert html =~ "<html"
      assert html =~ "vega"
    end
  end

  test "to_svg/1" do
    assert Tucan.Export.to_svg(@vl) =~ "<svg"
  end

  test "to_png/2" do
    assert <<0x89, "PNG", _rest::binary>> = Tucan.Export.to_png(@vl)
  end

  test "to_jpeg/2" do
    assert <<0xFF, 0xD8, _rest::binary>> = Tucan.Export.to_jpeg(@vl)
  end

  test "to_pdf/1" do
    assert <<"%PDF", _rest::binary>> = Tucan.Export.to_pdf(@vl)
  end

  @tag :tmp_dir
  test "save!/3 infers the format from the extension", %{tmp_dir: tmp_dir} do
    png = Path.join(tmp_dir, "plot.png")
    json = Path.join(tmp_dir, "plot.json")

    assert :ok = Tucan.Export.save!(@vl, png)
    assert :ok = Tucan.Export.save!(@vl, json)

    assert <<0x89, "PNG", _rest::binary>> = File.read!(png)
    assert %{"mark" => %{"type" => "point"}} = json |> File.read!() |> Jason.decode!()
  end

  @tag :tmp_dir
  test "save!/3 with an explicit format", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "plot.out")

    assert :ok = Tucan.Export.save!(@vl, path, format: :svg)
    assert File.read!(path) =~ "<svg"
  end
end
