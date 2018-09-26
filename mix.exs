defmodule Worker.MixProject do
  use Mix.Project

  def project do
    [
      app: :snapeth,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:honeybadger, :logger, :runtime_tools, :observer, :wx],
      mod: {Snapeth.Application, []}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end

  defp deps do
    [
      {:distillery, "~> 1.5"},
      {:honeybadger, "~> 0.1"},
      {:mox, "~> 0.4.0", only: :test},
      {:poison, "~> 3.0"},
      {:quantum, "~> 2.3"},
      {:slack, "~> 0.15"},
      {:timex, "~> 3.4.1"},
    ]
  end
end
