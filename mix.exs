defmodule GoldenOrb.MixProject do
  use Mix.Project

  @source_url "https://github.com/RoyalIcing/GoldenOrb"

  def project do
    [
      app: :golden_orb,
      version: "0.0.1",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: Mix.env() != :test,
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

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:orb, "~> 0.2.2"},
      {:plug, "~> 1.17.0"},
      # {:orb, path: "../orb", override: true},
      # {:orb_wasmtime, "~> 0.1.10", only: :test},
      {:wasmex, "~> 0.9.2", only: :test},
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
        "README.md"
        # "guides/01-intro.livemd"
      ]
    ]
  end
end
