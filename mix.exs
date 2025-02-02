defmodule GoldenOrb.MixProject do
  use Mix.Project

  @source_url "https://github.com/RoyalIcing/GoldenOrb"

  def project do
    [
      app: :golden_orb,
      version: "0.0.1",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Gold-plated standard library for Orb",
      package: package(),

      # Docs
      name: "GoldenOrb",
      docs: docs(),
      source_url: @source_url,
      homepage_url: "https://calculated.world/orb"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:orb, "~> 0.0.17"},
      # {:orb, path: "../orb", override: true},
      {:orb_wasmtime, "~> 0.1.10", only: :test},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: :golden_orb,
      maintainers: ["Patrick George Wyndham Smith"],
      licenses: ["BSD-3-Clause"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      # The main page in the docs
      main: "GoldenOrb",
      # logo: "orb-logo-orange.svg",
      extras: [
        "README.md",
        # "guides/01-intro.livemd"
      ]
    ]
  end
end
