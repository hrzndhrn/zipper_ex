defmodule ZipperEx.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/hrzndhrn/cron"

  def project do
    [
      app: :zipper_ex,
      version: @version,
      elixir: "~> 1.11",
      source_ulr: @source_url,
      name: "ZipperEx",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "ZipperEx",
      formatters: ["html"]
    ]
  end

  def preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  end

  defp elixirc_paths(env) do
    case env do
      :test -> ["lib", "test/support"]
      _else -> ["lib"]
    end
  end

  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Marcus Kruse"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
