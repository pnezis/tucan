defmodule Tucan.MixProject do
  use Mix.Project

  @version "0.1.0"
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
        license: ["MIT"],
        links: %{"GitHub" => @scm_url},
        files: ~w(lib themes mix.exs README.md)
      ],
      source_url: @scm_url,
      description: "A plotting library on top of VegaLite"
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
      {:nimble_options, "~> 1.0"},
      {:vega_lite, "~> 0.1.7"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:fancy_fences, "~> 0.2", only: :dev, runtime: false}
    ] ++ dev_deps()
  end

  defp dev_deps do
    case System.get_env("TUCAN_DEV") do
      "true" ->
        [
          {:doctor, "~> 0.21.0", only: :dev},
          {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
          {:dialyxir, "~> 1.3", only: :dev, runtime: false}
        ]

      _other ->
        []
    end
  end

  defp docs do
    [
      groups_for_docs: [
        Plots: &(&1[:section] == :plots),
        "Composite Plots": &(&1[:section] == :composite),
        Grouping: &(&1[:section] == :grouping),
        Utilities: &(&1[:section] == :utilities)
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
          <script src="https://cdn.jsdelivr.net/npm/vega@5.25.0"></script>
          <script src="https://cdn.jsdelivr.net/npm/vega-lite@5.12.0"></script>
          <script src="https://cdn.jsdelivr.net/npm/vega-embed@6.22.2"></script>
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
