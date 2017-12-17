# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :logger, level: :info

config :authority, ecto_repos: [Authority.Test.Repo]

config :authority, Authority.Test.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "authority_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "test/support/"