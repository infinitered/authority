defmodule Authority.Test.Lock do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  defmodule Reason do
    use Exnumerator, values: [:too_many_attempts]
  end

  schema "locks" do
    belongs_to(:user, Authority.Test.User)

    field(:reason, Reason)
    field(:expires_at, :utc_datetime)

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:reason, :expires_at])
  end
end