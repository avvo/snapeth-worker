defmodule Worker.MixProject do
  use Mix.Project

  def project do
    [
      app: :snapeth,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :runtime_tools, :observer, :wx],
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
      {:mox, "~> 0.3", only: :test},
      {:poison, "~> 3.1"},
      {:slack, "~> 0.13"},
      {:timex, "~> 3.1"},
    ]
  end
end
