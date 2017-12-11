defmodule Authority.ExchangeTest do
  use ExUnit.Case

  defmodule User do
    defstruct [:user]
  end

  defmodule Email do
    defstruct [:email]
  end

  defmodule Password do
    defstruct [:password]
  end

  defmodule Key do
    defstruct [:context]
  end

  defmodule TestStore do
    @behaviour Authority.Exchange.Store

    def exchange(%User{}, opts) do
      {:ok, struct(Key, %{context: opts[:context]})}
    end
  end

  defmodule TestAuth do
    @behaviour Authority.Authentication

    def authenticate(%Email{}, %Password{}, _opts) do
      {:ok, %User{}}
    end

    def authenticate(_, _, _), do: {:error, :invalid_credentials}

    def authenticate(%Email{}, opts) do
      if opts[:context] == :recovery do
        {:ok, %User{}}
      else
        {:error, :credential_required}
      end
    end

    def authenticate(_, _), do: {:error, :invalid_credentials}
  end

  defmodule TestExchange do
    use Authority.Exchange,
      store: TestStore,
      authentication: TestAuth
  end

  describe ".exchange/2" do
    test "exchanges an email for a key in the :recovery context" do
      assert {:ok, %Key{}} = TestExchange.exchange(~E[my@email.com], context: :recovery)

      assert {:error, :credential_required} =
               TestExchange.exchange(~E[my@email.com], context: :identity)

      assert {:error, :credential_required} = TestExchange.exchange(~E[my@email.com])
    end
  end

  defp sigil_E(email, _) do
    %Email{email: email}
  end
end