ExUnit.start()
Authority.Test.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(Authority.Test.Repo, :manual)