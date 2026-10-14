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

  describe "choropleth/5" do
    @unemployment Tucan.Datasets.dataset(:us_county_unemployment)

    test "colors the features by the joined values" do
      spec =
        Tucan.Geo.choropleth(:us_10m, :us_county_unemployment, "id", "rate", feature: "counties")
        |> VegaLite.to_spec()

      data = %{"url" => @us, "format" => %{"type" => "topojson", "feature" => "counties"}}

      assert spec["projection"] == %{"type" => "albersUsa"}
      assert %{"width" => 500, "height" => 300} = spec

      assert [missing, values] = spec["layer"]

      assert missing == %{
               "projection" => %{"type" => "albersUsa"},
               "data" => data,
               "mark" => %{
                 "type" => "geoshape",
                 "fill" => "#e3e3e3",
                 "stroke" => "white",
                 "strokeWidth" => 0.3
               }
             }

      assert values == %{
               "projection" => %{"type" => "albersUsa"},
               "data" => data,
               "transform" => [
                 %{
                   "lookup" => "id",
                   "from" => %{
                     "data" => %{"url" => @unemployment},
                     "key" => "id",
                     "fields" => ["rate"]
                   }
                 }
               ],
               "mark" => %{"type" => "geoshape", "stroke" => "white", "strokeWidth" => 0.3},
               "encoding" => %{"color" => %{"field" => "rate", "type" => "quantitative"}}
             }
    end

    test "with the default options" do
      spec = Tucan.Geo.choropleth(:us_10m, :us_state_population, "id", "population")
      [missing, _values] = VegaLite.to_spec(spec)["layer"]

      assert missing["data"]["format"]["feature"] == "states"
    end

    test "with inline data, extra fields, tooltips and styling options" do
      data = [%{name: "a", fips: 1, v: 2}]

      spec =
        Tucan.Geo.choropleth("https://example.com/map.geojson", data, "name", "v",
          feature_key: "properties.name",
          fields: ["fips"],
          color_scheme: :greens,
          missing_color: "white",
          line_color: "black",
          stroke_width: 1,
          projection: :mercator,
          tooltip: true
        )
        |> VegaLite.to_spec()

      assert spec["projection"] == %{"type" => "mercator"}
      assert [missing, values] = spec["layer"]

      assert missing["data"]["format"] == %{"type" => "json", "property" => "features"}
      assert missing["mark"]["fill"] == "white"

      assert hd(values["transform"]) == %{
               "lookup" => "properties.name",
               "from" => %{
                 "data" => %{"values" => [%{"name" => "a", "fips" => 1, "v" => 2}]},
                 "key" => "name",
                 "fields" => ["v", "fips"]
               }
             }

      assert values["mark"] == %{
               "type" => "geoshape",
               "stroke" => "black",
               "strokeWidth" => 1,
               "tooltip" => true
             }

      assert values["encoding"] == %{
               "color" => %{
                 "field" => "v",
                 "type" => "quantitative",
                 "scale" => %{"scheme" => "greens", "reverse" => false}
               },
               "tooltip" => [%{"field" => "v"}, %{"field" => "fips"}]
             }
    end

    test "raises with an invalid color scheme" do
      assert_raise ArgumentError, ~r/invalid scheme/, fn ->
        Tucan.Geo.choropleth(:us_10m, :us_state_population, "id", "population",
          color_scheme: :rainbows
        )
      end
    end
  end

  describe "scatter/4" do
    @airports Tucan.Datasets.dataset(:airports)

    test "draws points at the coordinates" do
      spec = Tucan.Geo.scatter(:airports, "longitude", "latitude") |> VegaLite.to_spec()

      assert spec == %{
               "$schema" => "https://vega.github.io/schema/vega-lite/v5.json",
               "data" => %{"url" => @airports},
               "mark" => %{"type" => "point", "filled" => true, "fillOpacity" => 0.7},
               "encoding" => %{
                 "longitude" => %{"field" => "longitude", "type" => "quantitative"},
                 "latitude" => %{"field" => "latitude", "type" => "quantitative"}
               },
               "projection" => %{"type" => "albersUsa"},
               "width" => 500,
               "height" => 300
             }
    end

    test "with grouping and styling options" do
      data = [%{lon: 1, lat: 2, c: "a", s: 3}]

      spec =
        Tucan.Geo.scatter(data, "lon", "lat",
          color_by: "c",
          size_by: "s",
          point_color: "red",
          point_size: 10,
          point_shape: "square",
          filled: false,
          fill_opacity: 0.5,
          tooltip: true,
          title: "Points"
        )
        |> VegaLite.to_spec()

      assert spec["projection"] == %{"type" => "equalEarth"}
      assert spec["title"] == %{"text" => "Points"}

      assert spec["mark"] == %{
               "type" => "point",
               "filled" => false,
               "fillOpacity" => 0.5,
               "color" => "red",
               "size" => 10,
               "shape" => "square",
               "tooltip" => true
             }

      assert spec["encoding"]["color"] == %{"field" => "c", "type" => "nominal"}
      assert spec["encoding"]["size"] == %{"field" => "s", "type" => "quantitative"}
    end

    test "can be layered on a basemap" do
      vl =
        Tucan.layers([
          Tucan.Geo.basemap(:us_10m),
          Tucan.Geo.scatter(:airports, "longitude", "latitude")
        ])

      assert [basemap, points] = VegaLite.to_spec(vl)["layer"]
      assert basemap["projection"] == points["projection"]
    end

    test "with a data tooltip and invalid options" do
      spec = Tucan.Geo.scatter([%{lon: 1, lat: 2}], "lon", "lat", tooltip: :data)
      assert VegaLite.to_spec(spec)["mark"]["tooltip"] == %{"content" => "data"}

      assert_raise NimbleOptions.ValidationError, fn ->
        Tucan.Geo.scatter([%{lon: 1, lat: 2}], "lon", "lat", point_shape: "star")
      end
    end

    test "the points are projected on the plane" do
      # with an equirectangular projection longitude and latitude are linear in x and y
      data = for lon <- [-90, -30, 30, 90], lat <- [-20, 40], do: %{lon: lon, lat: lat}

      svg =
        Tucan.Geo.scatter(data, "lon", "lat", projection: :equirectangular)
        |> Tucan.Export.to_svg()

      [symbols] = Regex.run(~r/class="mark-symbol.*?<\/g>/s, svg)

      positions =
        Regex.scan(~r/transform="translate\(([^,]+),([^)]+)\)"/, symbols, capture: :all_but_first)
        |> Enum.map(fn [x, y] -> {round_number(x), round_number(y)} end)

      assert length(positions) == 8

      xs = positions |> Enum.map(&elem(&1, 0)) |> Enum.uniq() |> Enum.sort()
      ys = positions |> Enum.map(&elem(&1, 1)) |> Enum.uniq() |> Enum.sort()

      # four columns equally spaced, one per longitude, and two rows
      assert length(xs) == 4
      assert length(ys) == 2

      [step | steps] = Enum.chunk_every(xs, 2, 1, :discard) |> Enum.map(fn [a, b] -> b - a end)
      for s <- steps, do: assert_in_delta(s, step, 0.01)

      # 60 degrees of longitude and 60 of latitude have the same length
      assert_in_delta Enum.at(ys, 1) - Enum.at(ys, 0), step, 0.01
    end
  end

  describe "connections/6" do
    @routes [%{a: 1, b: 2, c: 3, d: 4, g: "x", n: 5}]

    test "draws lines between the coordinates" do
      spec = Tucan.Geo.connections(@routes, "a", "b", "c", "d") |> VegaLite.to_spec()

      assert spec["mark"] == %{"type" => "rule", "opacity" => 0.6, "strokeWidth" => 1}

      assert spec["encoding"] == %{
               "longitude" => %{"field" => "a", "type" => "quantitative"},
               "latitude" => %{"field" => "b", "type" => "quantitative"},
               "longitude2" => %{"field" => "c"},
               "latitude2" => %{"field" => "d"}
             }

      assert spec["projection"] == %{"type" => "equalEarth"}
    end

    test "with grouping and styling options" do
      spec =
        Tucan.Geo.connections(@routes, "a", "b", "c", "d",
          color_by: "g",
          size_by: "n",
          line_color: "red",
          stroke_width: 2,
          opacity: 1,
          tooltip: true,
          projection: :albers_usa
        )
        |> VegaLite.to_spec()

      assert spec["mark"] == %{
               "type" => "rule",
               "opacity" => 1,
               "strokeWidth" => 2,
               "color" => "red",
               "tooltip" => true
             }

      assert spec["encoding"]["color"] == %{"field" => "g", "type" => "nominal"}
      assert spec["encoding"]["size"] == %{"field" => "n", "type" => "quantitative"}
      assert spec["projection"] == %{"type" => "albersUsa"}
    end

    test "the lines join the projected locations" do
      # along the equator and along the prime meridian, with an equirectangular projection
      data = [%{a: -90, b: 0, c: 90, d: 0}, %{a: 0, b: -45, c: 0, d: 45}]

      svg =
        Tucan.Geo.connections(data, "a", "b", "c", "d", projection: :equirectangular)
        |> Tucan.Export.to_svg()

      [rules] = Regex.run(~r/class="mark-rule.*?<\/g>/s, svg)

      [{x1, y1, dx1, dy1}, {x2, y2, dx2, dy2}] =
        Regex.scan(~r/translate\(([^,]+),([^)]+)\)" x2="([^"]+)" y2="([^"]+)"/, rules,
          capture: :all_but_first
        )
        |> Enum.map(fn values -> values |> Enum.map(&round_number/1) |> List.to_tuple() end)

      # the equator is horizontal and the meridian vertical, pointing north
      assert dy1 == 0
      assert dx1 > 0
      assert dx2 == 0
      assert dy2 < 0

      # 180 degrees of longitude are twice as long as 90 degrees of latitude
      assert_in_delta dx1, -2 * dy2, 0.01

      # the lines cross at their middle points
      assert_in_delta x1 + dx1 / 2, x2, 0.01
      assert_in_delta y2 + dy2 / 2, y1, 0.01
    end
  end

  describe "combining maps" do
    test "layered maps keep their projection when combined" do
      vl =
        Tucan.layers([
          Tucan.Geo.basemap(:world_110m, sphere: true, graticule: true, projection: :mercator),
          Tucan.Geo.choropleth(:world_110m, [%{id: 4, v: 1}], "id", "v", projection: :mercator),
          Tucan.Geo.basemap(:world_110m, mesh: "countries", projection: :mercator),
          Tucan.Geo.scatter([%{lon: 1, lat: 2}], "lon", "lat", projection: :mercator)
        ])

      layers = VegaLite.to_spec(vl)["layer"]

      assert length(layers) == 7

      for layer <- layers do
        assert layer["projection"] == %{"type" => "mercator"}
      end
    end
  end

  defp round_number(string) do
    {number, ""} = Float.parse(string)
    Float.round(number, 6)
  end
end
