defmodule Authority.Authentication do
  @callback authenticate(any, any) :: {:ok, any} | {:error, :term}

  def authenticate(module, credential) do
    %{store: store} = module.config()

    with {:ok, identity} <- store.identify(credential),
         :ok <- store.validate(credential, identity) do
      {:ok, identity}
    end
  end

  def authenticate(module, identifier, credential) do
    %{store: store} = module.config()

    with {:ok, identity} <- store.identify(identifier),
         :ok <- store.validate(credential, identity) do
      {:ok, identity}
    end
  end

  defmacro __using__(opts) do
    quote do
      @behaviour Authority.Authentication
      @opts unquote(opts)
      @otp_app @opts[:otp_app]

      def authenticate(credential) do
        Authority.Authentication.authenticate(__MODULE__, credential)
      end

      def authenticate(identifier, credential) do
        Authority.Authentication.authenticate(__MODULE__, identifier, credential)
      end

      def config do
        Application.get_env(@otp_app, __MODULE__)
      end

      defoverridable Authority.Authentication
    end
  end
end