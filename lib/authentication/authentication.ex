defmodule Authority.Authentication do
  @type id :: any
  @type credential :: any

  @callback authenticate(credential) :: {:ok, any} | {:error, term}
  @callback authenticate(id, credential) :: {:ok, any} | {:error, term}

  @doc false
  def authenticate(%{store: store}, credential) do
    with {:ok, identity} <- store.identify(credential),
         :ok <- store.validate(credential, identity) do
      {:ok, identity}
    end
  end

  @doc false
  def authenticate(%{store: store}, identifier, credential) do
    with {:ok, identity} <- store.identify(identifier),
         :ok <- store.validate(credential, identity) do
      {:ok, identity}
    end
  end

  defmacro __using__(config) do
    quote do
      @behaviour Authority.Authentication
      @config Enum.into(unquote(config), %{})

      def authenticate(credential) do
        Authority.Authentication.authenticate(@config, credential)
      end

      def authenticate(identifier, credential) do
        Authority.Authentication.authenticate(@config, identifier, credential)
      end

      defoverridable Authority.Authentication
    end
  end
end