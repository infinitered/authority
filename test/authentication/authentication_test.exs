defmodule Authority.AuthenticationTest do
  use ExUnit.Case

  import Authority.Authentication

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

    def identify(%Email{email: "existing@user.com"}) do
      {:ok, %User{password: "password"}}
    end

    def identify(%Email{}) do
      {:error, :invalid_email}
    end

    def identify(%Key{key: key}) when key in ["valid", "expired"] do
      {:ok, %User{}}
    end

    def identify(%Key{}) do
      {:error, :invalid_key}
    end

    def validate(%Password{password: password}, user) do
      if password == user.password do
        :ok
      else
        {:error, :invalid_password}
      end
    end

    def validate(%Key{key: "valid"}, _user), do: :ok
    def validate(%Key{key: "expired"}, _user), do: {:error, :key_expired}
  end

  @config %{store: TestStore}

  describe ".authenticate/2" do
    test "returns error if credential does not exist" do
      assert {:error, :invalid_key} = authenticate(@config, ~K[nonexistent])
    end

    test "returns error if credential exists, but is invalid" do
      assert {:error, :key_expired} = authenticate(@config, ~K[expired])
    end

    test "returns identity if credential is valid" do
      assert {:ok, %User{}} = authenticate(@config, ~K[valid])
    end
  end

  describe ".authenticate/3" do
    test "returns error if identifier is invalid" do
      assert {:error, :invalid_email} =
               authenticate(@config, ~E[nonexistent@user.com], ~P[password])
    end

    test "returns error if identifier is valid but credential is invalid" do
      assert {:error, _} = authenticate(@config, ~E[existing@user.com], ~P[invalid])
    end

    test "returns identity if identifier and credential are valid" do
      assert {:ok, %User{}} = authenticate(@config, ~E[existing@user.com], ~P[password])
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