defmodule Authority.Authentication do
  @moduledoc """
  A behaviour for authenticating users.

  ## Usage

  Authentication happens in stages in the following order, each with a
  callback:

  - `before_identify/1`
  - `identify/1`
  - `before_validate/2`
  - `validate/3`
  - `after_validate/2`
  - `failed/2`

  First, define your module:

      defmodule MyApp.Accounts.Authentication do
        use Authority.Authentication

        # OPTIONAL
        @impl Authority.Authentication
        def before_identify(identifier) do
          # Do anything you need to do to the identifier
          # before it is used to identify the user
        end

        # REQUIRED
        @impl Authority.Authentication
        def identify(identifier) do
          # Identify the user
        end

        # OPTIONAL
        @impl Authority.Authentication
        def before_validate(user, purpose) do
          # Define any additional checks that should determine
          # if authentication is permitted.
          #
          # For example, check if the user is active or if the
          # account is locked.
        end

        # REQUIRED
        @impl Authority.Authentication
        def validate(credential, user, purpose) do
          # check if the credential is valid for the user
        end

        # OPTIONAL
        @impl Authority.Authentication
        def after_validate(user, purpose) do
          # Clean up after a successful authentication
        end

        # OPTIONAL
        @impl Authority.Authentication
        def failed(user, error) do
          # Do anything that needs to be done on failure, such as
          # locking the user account on too many failed attempts
        end
      end

  Second, call the `authenticate/2` function:

      MyApp.Accounts.Authentication.authenticate({email, password})

      # Specify a purpose, the default is `:any`
      MyApp.Accounts.Authentication.authenticate({email, password}, :recovery)

  This will use all the callbacks defined and described above.
  """

  @typedoc """
  An identifier for a user.
  """
  @type id :: any

  @typedoc """
  A credential for a user, such as an email/password pair, or a token. 

  When a tuple, the first element is an identifier (like an email), which
  will be used to lookup the user. The second element is the credential.

  When not a tuple, (like a token) the credential will also be used for
  both purposes, to identify the user and validate the request.
  """
  @type credential :: {id, any} | any

  @typedoc """
  An authenticated user. Can be any type that represents a user in your system.
  """
  @type user :: any

  @typedoc """
  The purpose for the authentication request. This can be used as the basis to
  approve or deny the request. Defaults to `:any`.
  """
  @type purpose :: atom

  @typedoc """
  An authentication error.
  """
  @type error :: {:error, term}

  @doc """
  Converts a credential into a user. Assumes the purpose `:any`.
  """
  @callback authenticate(credential) :: :ok | error

  @doc """
  Converts a credential into a user, provided that the credential is valid for
  the given purpose.
  """
  @callback authenticate(credential, purpose) :: :ok | error

  @doc """
  This function will be called before `identify/1`. Use it to modify or refresh
  the identifier before it is used to lookup the user.
  """
  @callback before_identify(id) :: {:ok, id} | error

  @doc """
  Identifies the user from the given identifier.
  """
  @callback identify(id) :: {:ok, user} | error

  @doc """
  This function will be called before `validate/2`. Use it to add
  additional checks, such as whether the user is active or locked.
  """
  @callback before_validate(user, purpose) :: :ok | error

  @doc """
  Validates whether the given credential is valid for the identified user and 
  purpose.
  """
  @callback validate(credential, user, purpose) :: :ok | error

  @doc """
  This function will be called after `validate/2`, if validation was
  successful. Use it to clean up after a successful authentication.
  """
  @callback after_validate(user, purpose) :: :ok | error

  @doc """
  This function will be called if the authentication attempt fails
  for any reason. Use it to apply security locks or anything else
  that needs to be done on failure.
  """
  @callback failed(user, error) :: :ok | error

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour Authority.Authentication

      @impl Authority.Authentication
      def authenticate(credential, purpose \\ :any) do
        Authority.Authentication.authenticate(__MODULE__, credential, purpose)
      end

      @impl Authority.Authentication
      def before_identify(identifier), do: {:ok, identifier}

      @impl Authority.Authentication
      def before_validate(_user, _purpose), do: :ok

      @impl Authority.Authentication
      def after_validate(_user, _purpose), do: :ok

      @impl Authority.Authentication
      def failed(_user, _error), do: :ok

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
         {:ok, user} <- module.identify(identifier) do
      credential = combine_credential(identifier, credential)

      with :ok <- module.before_validate(user, purpose),
           :ok <- module.validate(credential, user, purpose),
           :ok <- module.after_validate(user, purpose) do
        {:ok, user}
      else
        error ->
          module.failed(user, error)
          error
      end
    end
  end

  # When credential and identifier are the same type, consider
  # the identifier to be the credential
  defp combine_credential(
         %{__struct__: _struct} = identifier,
         %{__struct__: _struct} = _credential
       ) do
    identifier
  end

  defp combine_credential(_identifier, credential) do
    credential
  end
end