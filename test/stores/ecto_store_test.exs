defmodule Authority.EctoStoreTest do
  use ExUnit.Case

  @password_hash "$2b$12$V2Pogh16L1BbvDOFS4oIbuavOq91u6XFD1mhFL.kaeAO8Nl4pNGdy"
  @future DateTime.from_naive!(~N[3000-01-01 00:00:00], "Etc/UTC")
  @past DateTime.from_naive!(~N[1000-01-01 00:00:00], "Etc/UTC")

  defmodule User do
    use Ecto.Schema

    embedded_schema do
      field(:email, :string)
      field(:encrypted_password, :string)
    end
  end

  defmodule Token do
    use Ecto.Schema

    embedded_schema do
      belongs_to(:user, User)

      field(:context, :string)
      field(:token, Ecto.UUID)
      field(:expires_at, :utc_datetime)
    end
  end

  defmodule Repo do
    @password_hash "$2b$12$V2Pogh16L1BbvDOFS4oIbuavOq91u6XFD1mhFL.kaeAO8Nl4pNGdy"
    @user %User{email: "existing@user.com", encrypted_password: @password_hash}
    @future DateTime.from_naive!(~N[3000-01-01 00:00:00], "Etc/UTC")
    @past DateTime.from_naive!(~N[1000-01-01 00:00:00], "Etc/UTC")

    def insert(struct) do
      {:ok, struct}
    end

    def get_by(User, conditions) do
      case conditions[:email] do
        "existing@user.com" ->
          %User{email: "existing@user.com", encrypted_password: @password_hash}

        _ ->
          nil
      end
    end

    def get_by(Token, token: "valid_identity") do
      %Token{
        context: :identity,
        user: @user,
        token: Ecto.UUID.generate(),
        expires_at: @future
      }
    end

    def get_by(Token, token: "expired_identity") do
      %Token{
        context: :identity,
        user: @user,
        token: Ecto.UUID.generate(),
        expires_at: @past
      }
    end

    def get_by(Token, token: "valid_recovery") do
      %Token{
        context: :recovery,
        user: @user,
        token: Ecto.UUID.generate(),
        expires_at: @future
      }
    end

    def preload(struct, _keys) do
      struct
    end
  end

  defmodule Store do
    use Authority.EctoStore,
      repo: Repo,
      authentication: %{
        schema: User,
        identity_field: :email,
        credential_field: :encrypted_password,
        credential_type: :hash,
        hash_algorithm: :bcrypt
      },
      exchange: %{
        schema: Token,
        identity_assoc: :user,
        token_field: :token,
        token_type: :uuid,
        context_field: :context,
        expiry_field: :expires_at,
        contexts: %{
          identity: %{
            default: true,
            expires_in_seconds: 60
          },
          recovery: %{
            expires_in_seconds: 60,
            skip_validation: [~r/@/]
          }
        }
      }
  end

  describe ".identify/2" do
    test "returns error if email is invalid" do
      assert {:error, :invalid_email} = Store.identify("invalid@email.com")
    end

    test "returns identity if email exists" do
      assert {:ok, %User{}} = Store.identify("existing@user.com")
    end

    test "returns identity if token exists" do
      for token <- ~w[valid_recovery valid_identity expired_identity] do
        assert {:ok, %User{}} = Store.identify(%Token{token: token})
      end
    end
  end

  describe ".validate/3" do
    test "returns error if password is invalid" do
      assert {:error, :invalid_encrypted_password} =
               Store.validate("invalid", %User{encrypted_password: @password_hash})
    end

    test "returns error if token has expired" do
      assert {:error, :token_expired} =
               Store.validate(%Token{context: :identity, expires_at: @past}, %User{})
    end

    test "returns error if token is invalid for context" do
      assert {:error, :token_invalid_for_context} =
               Store.validate(%Token{context: :recovery, expires_at: @future}, %User{})

      assert {:error, :token_invalid_for_context} =
               Store.validate(
                 %Token{context: :identity, expires_at: @future},
                 %User{},
                 context: :recovery
               )
    end

    # This allows us to exchange email addresses for recovery tokens
    test "returns ok if email is valid and context is recovery" do
      assert :ok == Store.validate("existing@email.com", %User{}, context: :recovery)
      assert {:error, _} = Store.validate("existing@email.com", %User{})
    end

    test "returns ok if password is valid" do
      assert :ok == Store.validate("password", %User{encrypted_password: @password_hash})
    end

    test "returns ok if token is valid" do
      assert :ok == Store.validate(%Token{context: :identity, expires_at: @future}, %User{})

      assert :ok ==
               Store.validate(
                 %Token{context: :recovery, expires_at: @future},
                 %User{},
                 context: :recovery
               )
    end
  end

  describe ".exchange/2" do
    test "generates a token" do
      assert {:ok, token} = Store.exchange(%User{id: 2}, context: :recovery)
      assert token.context == :recovery
      assert token.token
      assert token.user == %User{id: 2}
      assert DateTime.compare(DateTime.utc_now(), token.expires_at) == :lt
    end
  end
end