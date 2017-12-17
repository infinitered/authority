defmodule Authority.Template.AuthenticationTest do
  use Authority.DataCase

  defmodule Accounts do
    use Authority.Template,
      behaviours: [Authority.Authentication],
      config: [
        repo: Authority.Test.Repo,
        user_schema: Authority.Test.User
      ]
  end

  setup do
    Factory.insert!(:user, email: "valid@email.com")

    :ok
  end

  describe ".authenticate/2" do
    test "returns error if email is invalid" do
      assert {:error, :invalid_email} = Accounts.authenticate({"invalid@email.com", "password"})
    end

    test "returns error if password is invalid" do
      assert {:error, :invalid_password} = Accounts.authenticate({"valid@email.com", "invalid"})
    end

    test "returns user if email/password are valid" do
      assert {:ok, %Authority.Test.User{}} =
               Accounts.authenticate({"valid@email.com", "password"})
    end
  end
end