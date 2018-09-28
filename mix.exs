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
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:mox, "~> 0.4.0", only: :test},
      {:poison, "~> 3.0"},
      {:quantum, "~> 2.3"},
      {:slack, "~> 0.15"},
      {:timex, "~> 3.4.1"},
    ]
  end
end
