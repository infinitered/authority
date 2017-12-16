defmodule Authority.Test.User do
  @moduledoc false

  use Ecto.Schema

  schema "users" do
    field(:email, :string)
    field(:encrypted_password, :string)

    timestamps(type: :utc_datetime)
  end
end