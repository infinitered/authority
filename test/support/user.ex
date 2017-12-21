defmodule Authority.Test.User do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  schema "users" do
    field(:email, :string)
    field(:encrypted_password, :string)

    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :password, :password_confirmation])
    |> validate_required([:email, :password, :password_confirmation])
    |> validate_confirmation(:password)
    |> put_encrypted_password()
  end

  defp put_encrypted_password(changeset) do
    password = get_change(changeset, :password)

    if password do
      changeset
      |> put_change(:encrypted_password, Comeonin.Bcrypt.hashpwsalt(password))
      |> delete_change(:password)
      |> delete_change(:password_confirmation)
    else
      changeset
    end
  end
end
