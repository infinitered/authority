defmodule Authority.Template.TokenizationTest do
  use Authority.DataCase, async: true

  defmodule Accounts do
    use Authority.Template,
      behaviours: [
        Authority.Authentication,
        Authority.Tokenization
      ],
      config: [
        repo: Authority.Test.Repo,
        user_schema: Authority.Test.User,
        token_schema: Authority.Test.Token
      ]
  end

  alias Authority.Test.{Token, User}

  setup do
    user = Factory.insert!(:user, email: "valid@email.com")
    {:ok, user: user}
  end

  describe ".tokenize/2" do
    test "returns error if credentials are invalid" do
      assert {:error, :invalid_email} = Accounts.tokenize({"invalid@email.com", "password"})
      assert {:error, :invalid_password} = Accounts.tokenize({"valid@email.com", "invalid"})
    end

    test "returns token if credentials are valid" do
      assert {:ok, %Token{}} = Accounts.tokenize({"valid@email.com", "password"})
    end

    test "tokenizes email address for recovery only" do
      assert {:ok, %Token{}} = Accounts.tokenize("valid@email.com", :recovery)
      assert {:error, :invalid_email} = Accounts.tokenize("invalid@email.com", :recovery)
      assert {:error, :invalid_credential_for_purpose} = Accounts.tokenize("valid@email.com")
    end
  end

  describe ".authenticate/2" do
    test "accepts valid tokens" do
      {:ok, token} = Accounts.tokenize({"valid@email.com", "password"})
      assert {:ok, %User{}} = Accounts.authenticate(token)
      assert {:ok, %User{}} = Accounts.authenticate(%Token{token: token.token})

      {:ok, token} = Accounts.tokenize("valid@email.com", :recovery)
      assert {:ok, %User{}} = Accounts.authenticate(token, :recovery)
      assert {:error, :invalid_token_for_purpose} = Accounts.authenticate(token)
    end
  end
end
