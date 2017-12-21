defmodule Authority.Test.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:email, :string)
      add(:encrypted_password, :string)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
  end
end
