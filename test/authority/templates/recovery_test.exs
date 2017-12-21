defmodule Authority.Template.RecoveryTest do
  use Authority.DataCase, async: true

  defmodule Accounts do
    use Authority.Template,
      behaviours: [
        Authority.Authentication,
        Authority.Recovery,
        Authority.Registration,
        Authority.Tokenization
      ],
      config: [
        repo: Authority.Test.Repo,
        user_schema: Authority.Test.User,
        token_schema: Authority.Test.Token,
        recovery_callback: {Authority.Template.RecoveryTest.Notifications, :forgot_password}
      ]
  end

  defmodule Notifications do
    def forgot_password(email, token) do
      send(self(), {email, token})
      :ok
    end
  end

  alias Authority.Test.{
    User,
    Token
  }

  describe ".recover/1" do
    setup do
      user = Factory.insert!(:user, email: "valid@email.com")
      {:ok, user: user}
    end

    test "returns error when email is invalid" do
      assert {:error, :invalid_email} = Accounts.recover("invalid@email.com")
    end

    test "generates recovery token and sends it to the user", %{user: user} do
      assert :ok == Accounts.recover("valid@email.com")
      assert_received {"valid@email.com", %Token{} = token}

      assert token.user_id == user.id
      assert token.purpose == :recovery

      # Token can be used to reset the user's password
      assert {:ok, %User{}} =
               Accounts.update_user(%Token{token: token.token}, %{
                 password: "new_password",
                 password_confirmation: "new_password"
               })

      assert {:error, :invalid_password} = Accounts.authenticate({"valid@email.com", "password"})
      assert {:ok, %User{}} = Accounts.authenticate({"valid@email.com", "new_password"})

      # Token cannot be used twice
      assert {:error, :invalid_token} =
               Accounts.update_user(token, %{
                 password: "third_password",
                 password_confirmation: "third_password"
               })
    end
  end
end