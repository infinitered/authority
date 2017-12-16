defmodule Authority.Test.Repo.Migrations.CreateAttempts do
  use Ecto.Migration

  def change do
    create table(:attempts) do
      add(:user_id, references(:users, on_delete: :delete_all))
      timestamps(type: :utc_datetime)
    end

    create index(:attempts, [:user_id])
    create index(:attempts, [:inserted_at])
  end
end