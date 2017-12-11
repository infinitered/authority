defmodule Authority.AuthenticationTest do
  use ExUnit.Case

  defmodule Email do
    defstruct [:email]
  end

  defmodule Password do
    defstruct [:password]
  end

  defmodule User do
    defstruct [:email, :password]
  end

  defmodule Key do
    defstruct [:key]
  end

  defmodule TestStore do
    @behaviour Authority.Authentication.Store

    def identify(%Email{email: "existing@user.com"}, _opts) do
      {:ok, %User{password: "password"}}
    end

    def identify(%Email{}, _opts) do
      {:error, :invalid_email}
    end

    def identify(%Key{key: key}, _opts) when key in ["valid", "expired"] do
      {:ok, %User{}}
    end

    def identify(%Key{}, _opts) do
      {:error, :invalid_key}
    end

    def validate(%Password{password: password}, user, _opts) do
      if password == user.password do
        :ok
      else
        {:error, :invalid_password}
      end
    end

    def validate(%Key{key: "valid"}, _user, _opts), do: :ok
    def validate(%Key{key: "expired"}, _user, _opts), do: {:error, :key_expired}

    # Validate email, but only for the recovery context
    def validate(%Email{email: "existing@user.com"}, _user, opts) do
      if opts[:context] == :recovery do
        :ok
      else
        {:error, :credential_required}
      end
    end
  end

  defmodule TestAuth do
    use Authority.Authentication, store: TestStore
  end

  describe ".authenticate/2" do
    test "returns error if credential does not exist" do
      assert {:error, :invalid_key} = TestAuth.authenticate(~K[nonexistent])
    end

    test "returns error if credential exists, but is invalid" do
      assert {:error, :key_expired} = TestAuth.authenticate(~K[expired])
    end

    test "returns identity if credential is valid" do
      assert {:ok, %User{}} = TestAuth.authenticate(~K[valid])
    end

    test "returns identity for email if context is :recovery" do
      assert {:ok, %User{}} = TestAuth.authenticate(~E[existing@user.com], context: :recovery)
      assert {:error, :credential_required} = TestAuth.authenticate(~E[existing@user.com])
    end
  end

  describe ".authenticate/3" do
    test "returns error if identifier is invalid" do
      assert {:error, :invalid_email} =
               TestAuth.authenticate({~E[nonexistent@user.com], ~P[password]})
    end

    test "returns error if identifier is valid but credential is invalid" do
      assert {:error, _} = TestAuth.authenticate({~E[existing@user.com], ~P[invalid]})
    end

    test "returns identity if identifier and credential are valid" do
      assert {:ok, %User{}} = TestAuth.authenticate({~E[existing@user.com], ~P[password]})
    end
  end

  defp sigil_E(email, _) do
    %Email{email: email}
  end

  defp sigil_P(password, _) do
    %Password{password: password}
  end

  defp sigil_K(key, _) do
    %Key{key: key}
  end
end