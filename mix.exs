defmodule Tucan.MixProject do
  use Mix.Project

  def project do
    [
      app: :tucan,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:nimble_options, "~> 0.5.0"},
      {:vega_lite, "~> 0.1.5"}
    ]
  end
end
