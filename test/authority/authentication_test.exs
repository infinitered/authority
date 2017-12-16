defmodule Authority.AuthenticationTest do
  defmodule Auth do
    use Authority.Authentication
    alias Authority.Test.User

    def before_identify(identifier) do
      send(self(), {:before_identify, [identifier]})
      {:ok, identifier}
    end

    def identify(identifier) do
      send(self(), {:identify, [identifier]})
      {:ok, %User{}}
    end

    def before_validate(user, purpose) do
      send(self(), {:before_validate, [user, purpose]})
      :ok
    end

    def validate("invalid", _user, _purpose) do
      {:error, :invalid_password}
    end

    def validate(credential, user, purpose) do
      send(self(), {:validate, [credential, user, purpose]})
      :ok
    end

    def after_validate(user, purpose) do
      send(self(), {:after_validate, [user, purpose]})
      :ok
    end

    def failed(user, error) do
      send(self(), {:failed, [user, error]})
    end
  end

  use ExUnit.Case

  alias Authority.Test.User

  describe ".authenticate/2" do
    test "executes all of the behaviour callbacks" do
      Auth.authenticate({"username", "password"})
      assert_received {:before_identify, ["username"]}
      assert_received {:identify, ["username"]}
      assert_received {:before_validate, [%User{}, :any]}
      assert_received {:validate, ["password", %User{}, :any]}
      assert_received {:after_validate, [%User{}, :any]}
      refute_received {:failed, _args}

      # Calls the failed callback when a step fails
      Auth.authenticate({"username", "invalid"})
      assert_received({:failed, [%User{}, {:error, :invalid_password}]})

      # Passes custom purpose down
      Auth.authenticate({"username", "password"}, :recovery)
      assert_received {:before_validate, [%User{}, :recovery]}
      assert_received {:validate, ["password", %User{}, :recovery]}
      assert_received {:after_validate, [%User{}, :recovery]}
    end
  end
end