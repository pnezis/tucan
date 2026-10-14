defmodule Tucan.GeoTest do
  use ExUnit.Case

  @us Tucan.Datasets.dataset(:us_10m)
  @world Tucan.Datasets.dataset(:world_110m)

  describe "basemap/2" do
    test "draws the states of the us with an albers usa projection" do
      spec = Tucan.Geo.basemap(:us_10m) |> VegaLite.to_spec()

      assert spec == %{
               "$schema" => "https://vega.github.io/schema/vega-lite/v5.json",
               "data" => %{
                 "url" => @us,
                 "format" => %{"type" => "topojson", "feature" => "states"}
               },
               "mark" => %{
                 "type" => "geoshape",
                 "fill" => "#e3e3e3",
                 "stroke" => "white",
                 "strokeWidth" => 0.5
               },
               "projection" => %{"type" => "albersUsa"},
               "width" => 500,
               "height" => 300
             }
    end

    test "draws the countries of the world with an equal earth projection" do
      spec = Tucan.Geo.basemap(:world_110m) |> VegaLite.to_spec()

      assert spec["data"] == %{
               "url" => @world,
               "format" => %{"type" => "topojson", "feature" => "countries"}
             }

      assert spec["projection"] == %{"type" => "equalEarth"}
    end

    test "with features, meshes and geojson data" do
      spec = Tucan.Geo.basemap(:us_10m, feature: "counties") |> VegaLite.to_spec()
      assert spec["data"]["format"] == %{"type" => "topojson", "feature" => "counties"}

      spec = Tucan.Geo.basemap(:us_10m, mesh: "states") |> VegaLite.to_spec()
      assert spec["data"]["format"] == %{"type" => "topojson", "mesh" => "states"}
      assert spec["mark"]["fill"] == nil

      spec = Tucan.Geo.basemap("https://example.com/map.geojson") |> VegaLite.to_spec()

      assert spec["data"] == %{
               "url" => "https://example.com/map.geojson",
               "format" => %{"type" => "json", "property" => "features"}
             }

      assert spec["projection"] == %{"type" => "equalEarth"}
    end

    test "with a sphere and a graticule" do
      spec = Tucan.Geo.basemap(:world_110m, sphere: true, graticule: true) |> VegaLite.to_spec()

      assert spec["projection"] == %{"type" => "equalEarth"}
      assert spec["width"] == 500
      refute Map.has_key?(spec, "data")

      assert [sphere, graticule, countries] = spec["layer"]

      assert sphere == %{
               "projection" => %{"type" => "equalEarth"},
               "data" => %{"sphere" => true},
               "mark" => %{
                 "type" => "geoshape",
                 "fill" => "#e8f1f8",
                 "stroke" => "#cccccc",
                 "strokeWidth" => 0.5
               }
             }

      assert graticule == %{
               "projection" => %{"type" => "equalEarth"},
               "data" => %{"graticule" => %{"step" => [15, 15]}},
               "mark" => %{
                 "type" => "geoshape",
                 "fill" => nil,
                 "stroke" => "#cccccc",
                 "strokeWidth" => 0.3
               }
             }

      assert countries["data"]["format"]["feature"] == "countries"

      spec = Tucan.Geo.basemap(:world_110m, graticule: true) |> VegaLite.to_spec()
      assert [%{"data" => %{"graticule" => _}}, _countries] = spec["layer"]
    end

    test "with projection, size, title and styling options" do
      spec =
        Tucan.Geo.basemap(:world_110m,
          projection: :orthographic,
          projection_opts: [rotate: [-15, -50, 0], scale: 500],
          width: 400,
          height: 200,
          title: "Europe",
          fill_color: "green",
          line_color: "black",
          stroke_width: 1,
          sphere_color: "blue",
          sphere: true,
          tooltip: true
        )
        |> VegaLite.to_spec()

      assert spec["projection"] == %{
               "type" => "orthographic",
               "rotate" => [-15, -50, 0],
               "scale" => 500
             }

      assert %{"width" => 400, "height" => 200, "title" => %{"text" => "Europe"}} = spec

      [sphere, countries] = spec["layer"]
      assert sphere["mark"]["fill"] == "blue"

      assert countries["mark"] == %{
               "type" => "geoshape",
               "fill" => "green",
               "stroke" => "black",
               "strokeWidth" => 1,
               "tooltip" => true
             }
    end

    test "raises with invalid options" do
      for opts <- [[projection: :flat], [invalid: 1], [width: 0]] do
        assert_raise NimbleOptions.ValidationError, fn -> Tucan.Geo.basemap(:us_10m, opts) end
      end

      assert_raise ArgumentError, ~r/not supported dataset/, fn -> Tucan.Geo.basemap(:mars) end
    end
  end

  describe "combining maps" do
    test "layered maps keep their projection when combined" do
      vl =
        Tucan.layers([
          Tucan.Geo.basemap(:world_110m, sphere: true, graticule: true, projection: :mercator),
          Tucan.Geo.basemap(:world_110m, mesh: "countries", projection: :mercator)
        ])

      layers = VegaLite.to_spec(vl)["layer"]

      assert length(layers) == 4

      for layer <- layers do
        assert layer["projection"] == %{"type" => "mercator"}
      end
    end
  end
end
