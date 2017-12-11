defmodule Authority.Exchange do
  # MyModule.exchange("user@email.com", for: MyApp.Token, context: :recovery)
  # MyModule.Exchange.exchange(OAuthCode{provider: :facebook, code: "..."}, for: MyApp.Token, context: :identity)
  # MyModule.Exchange.exchange({"user@email.com", "password"}, for: MyApp.Token, context: :identity)

  alias Authority.Authentication

  @type opts :: Keyword.t()

  @callback exchange(Authentication.credential()) ::
              {:ok, Authentication.credential()}
              | {:error, term}

  @callback exchange(Authentication.credential(), opts) ::
              {:ok, Authentication.credential()}
              | {:error, term}

  @doc false
  def exchange(%{store: store, authentication: authentication}, credential, opts) do
    with {:ok, identity} <- authentication.authenticate(credential, opts) do
      store.exchange(identity, opts)
    end
  end

  @doc false
  def exchange(
        %{store: store, authentication: authentication},
        identifier,
        credential,
        opts
      ) do
    with {:ok, identity} <- authentication.authenticate(identifier, credential, opts) do
      store.exchange(identity, opts)
    end
  end

  defmacro __using__(config) do
    quote do
      @behaviour Authority.Exchange
      @__exchange__ Enum.into(unquote(config), %{})

      def exchange(credential, opts \\ []) do
        Authority.Exchange.exchange(@__exchange__, credential, opts)
      end

      def __exchange__ do
        @__exchange__
      end
    end
  end
end