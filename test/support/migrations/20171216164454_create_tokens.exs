defmodule Authority.Test.Repo.Migrations.CreateTokens do
  use Ecto.Migration

  def change do
    create table(:tokens) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:token, :string)
      add(:purpose, :string)
      add(:expires_at, :utc_datetime)

      timestamps(type: :utc_datetime)
    end

    create index(:tokens, [:user_id])
    create index(:tokens, [:token])
  end
end
