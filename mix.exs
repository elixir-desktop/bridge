defmodule Bridge.MixProject do
  use Mix.Project

  @version "1.1.3"
  @url "https://github.com/elixir-desktop/bridge"
  def project do
    [
      app: :wx,
      version: @version,
      source_url: @url,
      description: """
      wxWidgets drop-in replacement API to make the /desktop package
      work on Android and iOS
      """,
      package: package(),
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
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
      {:jason, "~> 1.2"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: :bridge,
      maintainers: ["Dominic Letz"],
      licenses: ["MIT"],
      links: %{github: @url},
      files: ~w(include lib LICENSE.md mix.exs README.md)
    ]
  end

  defp aliases() do
    [
      lint: [
        "compile",
        "format --check-formatted",
        "credo"
      ]
    ]
  end
end
