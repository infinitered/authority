defmodule Authority.MixProject do
  use Mix.Project

  def project do
    [
      app: :authority,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp docs do
    [
      main: Authority,
      groups_for_modules: [
        "Common Usage": [
          Authority.Template
        ],
        Behaviours: [
          Authority.Authentication,
          Authority.Locking,
          Authority.Registration,
          Authority.Tokenization
        ]
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: [:dev, :test]},
      {:ecto, ">= 0.0.0", only: [:test]},
      {:postgrex, ">= 0.0.0", only: [:test]},
      {:exnumerator, ">= 0.0.0", only: [:test]},
      {:comeonin, ">= 0.0.0", only: [:test]},
      {:bcrypt_elixir, ">= 0.0.0", only: [:test]}
    ]
  end

  defp aliases do
    [test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]]
  end
end