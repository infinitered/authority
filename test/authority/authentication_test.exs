defmodule Authority.AuthenticationTest do
  use ExUnit.Case

  defmodule Auth do
    use Authority.Authentication

    alias Authority.Test.{
      Email,
      User,
      OAuthCode,
      Password,
      Token
    }

    def identify(%Email{email: "existing@user.com"}) do
      {:ok, %User{password: "password"}}
    end

    def identify(%Email{}) do
      {:error, :invalid_email}
    end

    def identify(%Token{token: token}) when token in ~w[valid expired] do
      {:ok, %User{}}
    end

    def identify(%Token{}) do
      {:error, :invalid_token}
    end

    def identify(%OAuthCode{provider: :facebook, code: "valid"}) do
      {:ok, %User{}}
    end

    def identify(%OAuthCode{provider: :facebook, code: "invalid"}) do
      {:error, :invalid_oauth_code}
    end

    def identify(%OAuthCode{}) do
      {:error, :invalid_oauth_provider}
    end

    def validate(%Password{password: password}, user, _purpose) do
      if password == user.password do
        :ok
      else
        {:error, :invalid_password}
      end
    end

    def validate(%Token{token: "valid"}, _user, _purpose), do: :ok

    def validate(%Token{token: "expired"}, _user, _purpose), do: {:error, :expired_token}

    def validate(%OAuthCode{}, _user, _purpose), do: :ok
  end

  import Authority.Test.{
    Email,
    Password,
    Token
  }

  alias Authority.Test.{
    OAuthCode,
    User
  }

  describe ".authenticate/2" do
    test "returns error if credential does not exist" do
      assert {:error, :invalid_token} = Auth.authenticate(~K[nonexistent])

      assert {:error, :invalid_oauth_provider} =
               Auth.authenticate(%OAuthCode{provider: :github, code: "valid"})
    end

    test "returns error if credential exists, but is invalid" do
      assert {:error, :expired_token} = Auth.authenticate(~K[expired])

      assert {:error, :invalid_oauth_code} =
               Auth.authenticate(%OAuthCode{provider: :facebook, code: "invalid"})
    end

    test "returns error if identifier is invalid" do
      assert {:error, :invalid_email} =
               Auth.authenticate({~E[nonexistent@user.com], ~P[password]})
    end

    test "returns error if identifier is valid but credential is invalid" do
      assert {:error, _} = Auth.authenticate({~E[existing@user.com], ~P[invalid]})
    end

    test "returns identity if credential is valid" do
      assert {:ok, %User{}} = Auth.authenticate(~K[valid])
      assert {:ok, %User{}} = Auth.authenticate(%OAuthCode{provider: :facebook, code: "valid"})
    end

    test "returns identity if identifier and credential are valid" do
      assert {:ok, %User{}} = Auth.authenticate({~E[existing@user.com], ~P[password]})
    end
  end
end