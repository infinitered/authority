defmodule Authority.Template.RegistrationTest do
  use Authority.DataCase, async: true

  defmodule Accounts do
    use Authority.Template,
      behaviours: [
        Authority.Registration
      ],
      config: [
        repo: Authority.Test.Repo,
        user_schema: Authority.Test.User
      ]
  end

  defmodule Auth do
    use Authority.Template,
      behaviours: [
        Authority.Authentication,
        Authority.Registration,
        Authority.Tokenization
      ],
      config: [
        repo: Authority.Test.Repo,
        user_schema: Authority.Test.User,
        token_schema: Authority.Test.Token
      ]
  end

  alias Authority.Test.{User, Token}
  alias Ecto.Changeset

  describe ".change_user/0" do
    test "returns a changeset for a new user" do
      for module <- [Accounts, Auth] do
        assert {:ok, %Ecto.Changeset{data: %User{id: nil}}} = module.change_user()
      end
    end
  end

  describe ".change_user/1" do
    setup :create_user

    test "returns a changeset for an existing user" do
      for module <- [Accounts, Auth] do
        assert {:ok, %Ecto.Changeset{data: %User{id: 123}}} = module.change_user(%User{id: 123})
      end
    end

    test "returns a changeset for a valid token" do
      {:ok, token} = Auth.tokenize({"test@email.com", "password"})
      assert {:ok, %Ecto.Changeset{data: %User{id: id}}} = Auth.change_user(token)
      assert id != nil
    end

    test "returns an error for an invalid token" do
      assert {:error, :invalid_token} = Auth.change_user(%Token{token: "invalid"})
    end
  end

  describe ".change_user/2" do
    setup :create_user

    test "returns a changeset for an existing user with params" do
      for module <- [Accounts, Auth] do
        assert {:ok, %Ecto.Changeset{data: %User{id: 123}, changes: %{email: "test@email.com"}}} =
                 module.change_user(%User{id: 123}, %{email: "test@email.com"})
      end
    end

    test "returns a changeset for a valid token with params" do
      {:ok, token} = Auth.tokenize({"test@email.com", "password"})

      assert {:ok, %Ecto.Changeset{data: %User{id: id}, changes: %{email: "new@email.com"}}} =
               Auth.change_user(token, %{email: "new@email.com"})

      assert id != nil
    end

    test "returns an error for an invalid token" do
      assert {:error, :invalid_token} =
               Auth.change_user(%Token{token: "invalid"}, %{email: "new@email.com"})
    end
  end

  describe ".create_user/1" do
    test "returns error if required fields are not passed" do
      assert {:error, %Changeset{}} = Accounts.create_user(%{email: "test@email.com"})

      assert {:error, %Changeset{}} =
               Accounts.create_user(%{email: "test@email.com", password: "password"})
    end

    test "returns user when parameters are valid" do
      assert {:ok, %User{}} =
               Accounts.create_user(%{
                 email: "test@email.com",
                 password: "password",
                 password_confirmation: "password"
               })
    end
  end

  describe ".get_user/1" do
    setup :create_user

    test "returns error if no user with ID exists" do
      assert {:error, :not_found} == Accounts.get_user(123)
      assert {:error, :not_found} == Auth.get_user(123)
    end

    test "returns user if exists", %{user: user} do
      assert {:ok, %User{}} = Accounts.get_user(user.id)
      assert {:ok, %User{}} = Auth.get_user(user.id)
    end
  end

  describe ".update_user/2" do
    setup :create_user

    test "updates user password when given user", %{user: user} do
      {:ok, _token} = Auth.tokenize({"test@email.com", "password"})
      {:ok, _token} = Auth.tokenize({"test@email.com", "password"})

      assert {:ok, %User{}} =
               Accounts.update_user(user, %{
                 password: "new_password",
                 password_confirmation: "new_password"
               })

      assert {:ok, %User{}} =
               Auth.update_user(user, %{
                 password: "third_password",
                 password_confirmation: "third_password"
               })

      assert Repo.aggregate(Token, :count, :id) == 0
    end

    test "when used with tokenization, accepts tokens" do
      {:ok, token} = Auth.tokenize({"test@email.com", "password"})

      assert {:ok, %User{}} =
               Auth.update_user(token, %{
                 password: "new_password",
                 password_confirmation: "new_password"
               })

      assert Repo.aggregate(Token, :count, :id) == 1
      {:ok, recovery} = Auth.tokenize({"test@email.com", "new_password"}, :recovery)

      assert {:ok, %User{}} =
               Auth.update_user(recovery, %{
                 password: "new_password",
                 password_confirmation: "new_password"
               })

      assert {:error, :invalid_token} =
               Auth.update_user(%Token{token: "invalid"}, %{
                 password: "third_password",
                 password_confirmation: "third_password"
               })

      assert Repo.aggregate(Token, :count, :id) == 0
      {:ok, other} = Auth.tokenize({"test@email.com", "new_password"}, :other)

      assert {:error, :invalid_token_for_purpose} =
               Auth.update_user(other, %{
                 password: "fourth_password",
                 password_confirmation: "fourth_password"
               })
    end
  end

  describe ".delete_user/1" do
    setup :create_user

    test "deletes a user", %{user: user} do
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert Repo.aggregate(User, :count, :id) == 0
    end

    test "when used with tokenization, accepts all-purpose tokens" do
      {:ok, any} = Auth.tokenize({"test@email.com", "password"})
      assert {:ok, %User{}} = Auth.delete_user(any)
      assert Repo.aggregate(Token, :count, :id) == 0
    end

    test "when used with tokenization, rejects restricted-purpose tokens" do
      {:ok, recovery} = Auth.tokenize("test@email.com", :recovery)
      {:ok, other} = Auth.tokenize({"test@email.com", "password"}, :other)
      assert {:error, :invalid_token_for_purpose} = Auth.delete_user(recovery)
      assert {:error, :invalid_token_for_purpose} = Auth.delete_user(other)
    end
  end

  defp create_user(_) do
    {:ok, user} =
      Accounts.create_user(%{
        email: "test@email.com",
        password: "password",
        password_confirmation: "password"
      })

    {:ok, user: user}
  end
end