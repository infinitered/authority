defmodule Authority.Test.Token do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  defmodule Purpose do
    use Exnumerator, values: [:any, :recovery, :other]
  end

  schema "tokens" do
    belongs_to(:user, Authority.Test.User)

    field(:token, :string)
    field(:expires_at, :utc_datetime)
    field(:purpose, Purpose)

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:expires_at, :purpose])
    |> put_change(:token, Ecto.UUID.generate())
    |> put_expires_at()
  end

  defp put_expires_at(changeset) do
    expires_at =
      case get_field(changeset, :purpose) do
        :recovery ->
          # 24 hours
          add(DateTime.utc_now(), 86_400)

        _other ->
          # 2 weeks
          add(DateTime.utc_now(), 1_209_600)
      end

    put_change(changeset, :expires_at, expires_at)
  end

  defp add(datetime, seconds) do
    datetime
    |> DateTime.to_unix()
    |> Kernel.+(seconds)
    |> DateTime.from_unix!()
  end

  def sigil_K(token, _) do
    %__MODULE__{token: token}
  end
end
