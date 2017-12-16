defmodule Authority.Test.Repo.Migrations.CreateLocks do
  use Ecto.Migration

  def change do
    create table(:locks) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:reason, :string)
      add(:expires_at, :utc_datetime)

      timestamps(type: :utc_datetime)
    end

    create index(:locks, [:user_id])
    create index(:locks, [:expires_at])
  end
end