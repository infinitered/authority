defmodule Authority.Authentication do
  @type id :: any
  @type credential :: {id, any} | any
  @type identity :: any
  @type purpose :: atom
  @type error :: {:error, term}

  @callback authenticate(credential, purpose) :: :ok | error

  @callback before_identify(id) :: {:ok, id} | error
  @callback identify(id) :: {:ok, identity} | error
  @callback before_validate(identity, purpose) :: :ok | error
  @callback validate(credential, identity, purpose) :: :ok | error
  @callback after_validate(identity, purpose) :: :ok | error
  @callback failed(identity, error) :: :ok | error

  defmacro __using__(_) do
    quote do
      @behaviour Authority.Authentication

      def authenticate(credential, purpose \\ :any) do
        Authority.Authentication.authenticate(__MODULE__, credential, purpose)
      end

      def before_identify(identifier), do: {:ok, identifier}
      def before_validate(_identity, _purpose), do: :ok
      def after_validate(_identity, _purpose), do: :ok
      def failed(_identity, _error), do: :ok

      defoverridable Authority.Authentication
    end
  end

  @doc false
  def authenticate(module, {identifier, credential}, purpose) do
    do_authenticate(module, identifier, credential, purpose)
  end

  def authenticate(module, credential, purpose) do
    do_authenticate(module, credential, credential, purpose)
  end

  defp do_authenticate(module, identifier, credential, purpose) do
    with {:ok, identifier} <- module.before_identify(identifier),
         {:ok, identity} <- module.identify(identifier) do
      with :ok <- module.before_validate(identity, purpose),
           :ok <- module.validate(credential, identity, purpose),
           :ok <- module.after_validate(identity, purpose) do
        {:ok, identity}
      else
        error ->
          module.failed(identity, error)
          error
      end
    end
  end
end