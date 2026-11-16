defmodule RefractCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :refract_cli,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      releases: [refract_cli: [include_executables_for: [:unix], steps: [:assemble]]],
      dialyzer: dialyzer()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp dialyzer do
    [
      plt_local_path: "priv/plts",
      plt_core_path: "priv/plts",
      plt_add_apps: [:ex_unit],
      list_unused_filters: true
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      refract_dep(:refract, "refract_core", "v0.1.0"),
      {:yaml_elixir, "~> 2.12"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_slop, "~> 0.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp refract_dep(app, repo, tag, opts \\ []) do
    case System.get_env("#{String.upcase(to_string(app))}_PATH") do
      nil -> {app, [github: "williamthom-as/#{repo}", tag: tag] ++ opts}
      path -> {app, [path: path, override: true] ++ opts}
    end
  end
end
