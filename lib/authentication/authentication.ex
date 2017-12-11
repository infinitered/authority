defmodule Authority.Authentication do
  @type id :: any
  @type credential :: {id, any} | any
  @type opts :: Keyword.t()

  @callback authenticate(credential, opts) :: {:ok, any} | {:error, term}

  @doc false
  def authenticate(%{store: store}, {identifier, credential}, opts) do
    with {:ok, identity} <- store.identify(identifier, opts),
         :ok <- store.validate(credential, identity, opts) do
      {:ok, identity}
    end
  end

  @doc false
  def authenticate(%{store: store}, credential, opts) do
    with {:ok, identity} <- store.identify(credential, opts),
         :ok <- store.validate(credential, identity, opts) do
      {:ok, identity}
    end
  end

  defmacro __using__(config) do
    quote do
      @behaviour Authority.Authentication
      @__authentication__ Enum.into(unquote(config), %{})

      def authenticate(credential, opts \\ []) do
        Authority.Authentication.authenticate(@__authentication__, credential, opts)
      end

      def __authentication__ do
        @__authentication__
      end

      defoverridable Authority.Authentication
    end
  end
end