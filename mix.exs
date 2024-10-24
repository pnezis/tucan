defmodule Tucan.MixProject do
  use Mix.Project

  @version "0.4.0"
  @scm_url "https://github.com/pnezis/tucan"

  def project do
    [
      app: :tucan,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: [
        maintainers: [
          "Panagiotis Nezis"
        ],
        licenses: ["MIT"],
        links: %{
          "GitHub" => @scm_url,
          "Changelog" => @scm_url <> "/blob/main/CHANGELOG.md"
        },
        files: ~w(lib themes mix.exs README.md)
      ],
      source_url: @scm_url,
      description: "A plotting library on top of VegaLite",
      test_coverage: [
        summary: [threshold: 95]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nimble_options, "~> 1.1"},
      {:vega_lite, "~> 0.1.9"},
      {:jason, "~> 1.4"},
      {:nx, "~> 0.6", optional: true},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:fancy_fences, "~> 0.3.1", only: :dev, runtime: false}
    ] ++ dev_deps()
  end

  defp dev_deps do
    case System.get_env("TUCAN_DEV") do
      "true" ->
        [
          {:doctor, "~> 0.21.0", only: :dev},
          {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
          {:dialyxir, "~> 1.4", only: :dev, runtime: false}
        ]

      _other ->
        []
    end
  end

  defp docs do
    [
      main: "readme",
      canonical: "http://hexdocs.pm/tucan",
      source_url_pattern: "#{@scm_url}/blob/v#{@version}/%{path}#L%{line}",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      groups_for_docs: [
        Construction: &(&1[:section] == :construction),
        Plots: &(&1[:section] == :plots),
        "Composite Plots": &(&1[:section] == :composite),
        Images: &(&1[:section] == :images),
        "Auxiliary Plots": &(&1[:section] == :auxiliary_plots),
        Layout: &(&1[:section] == :layout),
        Grouping: &(&1[:section] == :grouping),
        Utilities: &(&1[:section] == :utilities),
        Styling: &(&1[:section] == :styling)
      ],
      groups_for_modules: [
        Plots: [
          Tucan,
          Tucan.Geometry,
          Tucan.Finance
        ],
        Layout: [
          Tucan.Layers
        ],
        Styling: [
          Tucan.Axes,
          Tucan.Grid,
          Tucan.Legend,
          Tucan.Scale,
          Tucan.Themes,
          Tucan.View
        ],
        Utilities: [
          Tucan.Export
        ],
        Datasets: [
          Tucan.Datasets
        ]
      ],
      extras: [
        "README.md": [title: "Overview"],
        "CHANGELOG.md": [title: "Changelog"],
        LICENSE: [title: "License"],
        "notebooks/time_series_plots_in_tucan.livemd": [title: "Time series plots in Tucan"]
      ],
      groups_for_extras: [
        Guides: [
          "notebooks/time_series_plots_in_tucan.livemd"
        ]
      ],
      markdown_processor:
        {FancyFences,
         [
           fences: %{
             "tucan" => {Tucan.Docs, :tucan, []}
           }
         ]},
      before_closing_body_tag: fn
        :html ->
          """
          <script src="https://cdn.jsdelivr.net/npm/vega@5.30.0"></script>
          <script src="https://cdn.jsdelivr.net/npm/vega-lite@5.21.0"></script>
          <script src="https://cdn.jsdelivr.net/npm/vega-embed@6.26.0"></script>
          <script>
            document.addEventListener("DOMContentLoaded", function () {
              for (const codeEl of document.querySelectorAll("pre code.vega-lite")) {
                try {
                  const preEl = codeEl.parentElement;
                  const spec = JSON.parse(codeEl.textContent);
                  const plotEl = document.createElement("div");
                  preEl.insertAdjacentElement("afterend", plotEl);
                  vegaEmbed(plotEl, spec);
                  preEl.remove();
                } catch (error) {
                  console.log("Failed to render Vega-Lite plot: " + error)
                }
              }
            });
          </script>
          """

        _ ->
          ""
      end
    ]
  end
end
