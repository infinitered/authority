defmodule Authority.Authentication do
  @moduledoc """
  A behaviour for looking up users and authenticating credentials.

  ## Implementation

  Simply `use Authority.Authentication` in your module:

      defmodule MyApp.Accounts do
        use Authority.Authentication
      end

  This will define a `MyApp.Accounts.authenticate/2` function, which will
  execute the following callback functions in this order:

    - `before_identify/1`
    - `identify/1`
    - `before_validate/2`
    - `validate/3`
    - `after_validate/2`

  If any of the callbacks return an `{:error, term}` response, the `failed/2`
  callback will execute. The `__using__/1` macro provides default, empty 
  implementations of all the callbacks except `validate/3`, which you must
  implement yourself.

  All the default callback implementations can be overriden.

  ## Execution Flow

  If you call `authenticate/2` with an `{email, password}` tuple, the
  callbacks will proceed as follows:

        MyApp.Accounts.authenticate({"test@example.com", "password"})

        # Will execute...
        before_identify("test@example.com")

        # This should return a user matching the email address
        identify("test@example.com")

        # If you need to do any checks on the user prior to validating
        # the password, do them here
        before_validate(user, :any)

        # Verify that the given password is valid for the given user
        validate("password", user, :any)

        # Do any cleanup needed after a successful validation
        after_validate(user, :any)

  The `:any` argument is the `purpose` of the authentication. It allows
  you to require different credentials for different purposes. It can be
  passed as the second argument to `authenticate/2`:

        # Sets the purpose to :recovery, e.g. account recovery
        MyApp.Accounts.authenticate({"test@example.com", "password"}, :recovery)

  ## Example

      defmodule MyApp.Accounts do
        use Authority.Authentication

        # OPTIONAL
        @impl Authority.Authentication
        def before_identify(identifier) do
          # Do anything you need to do to the identifier
          # before it is used to identify the user.
          # 
          # Return {:ok, identifier}
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
  """

  @typedoc """
  An identifier for a user, such as a username or email address.
  """
  @type id :: any

  @typedoc """
  A memorized secret known to the user and the system, such as a password
  or token value.
  """
  @type secret :: any

  @typedoc """
  A credential for a user.

  Credentials can either be tuples containing an id/secret pair,
  or a single value which serves both purposes, like an API token.

  ### ID/Secret Tuples

      {"test@email.com", "password"}

  When a tuple, the first element is considered the `id`,
  and will be passed to the following callbacks:

    - `before_identify/1`
    - `identify/1`

  The second element will be considered the `secret`, and will be
  passed as the first argument to `validate/3`.

  ### Single-Value Credentials

      %MyApp.Accounts.Token{token: "..."}

  When a non-tuple value is used as a credential, (like a token) the value
  will be used for _both_ purposes, both to identify the user and as a shared
  secret for validating the request. 

  The value will be passed as either the `id` and the `secret` to all relevant
  callbacks.

    - `before_identify/1`
    - `identify/1`
    - `validate/3`
  """
  @type credential :: {id, secret} | secret

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
  Verifies the credential and returns the associated user, if the credential is valid.
  Must assume that the `purpose` of the request is `:any`.
  """
  @callback authenticate(credential) :: {:ok, user} | error

  @doc """
  Verifies the credential and returns the associated user, if the credential is valid.
  The `purpose` is configurable.
  """
  @callback authenticate(credential, purpose) :: {:ok, user} | error

  @doc """
  This function will be called before `identify/1`. Use it to modify or refresh
  the `id` component of the credential before it is used to lookup the user.

  ## Example

      def before_identify(%Token{token: token}) do
        # Load the token from the database instead of relying on the
        # struct that was passed in, to ensure accuracy
      end
  """
  @callback before_identify(id) :: {:ok, id} | error

  @doc """
  Identifies and returns the user belonging to the given id.

  ## Example

      def identify(email) do
        # Look up the user by email
      end
  """
  @callback identify(id) :: {:ok, user} | error

  @doc """
  This function will be called before `validate/3`. Use it to verify
  any additional information beyond the user's secret: such as whether
  their account is active or locked.

  ## Example

      def before_validate(user, purpose) do
        if user.active, do: :ok, else: {:error, :inactive}
      end
  """
  @callback before_validate(user, purpose) :: :ok | error

  @doc """
  Validates whether the given secret is valid for the identified user and 
  purpose.

  ## Example

      def validate(password, user, purpose) do
        if hash(password) == user.encrypted_password do
          :ok
        else
          {:error, :invalid_password}
        end
      end
  """
  @callback validate(secret, user, purpose) :: :ok | error

  @doc """
  This function will be called after `validate/3`, if validation was
  successful. Use it to clean up after a successful authentication.

  ## Example

      def after_validate(user, purpose) do
        # Set failed login attempts for this user back to 0, since the user
        # successfully logged in
      end
  """
  @callback after_validate(user, purpose) :: :ok | error

  @doc """
  This function will be called if the authentication attempt fails
  for any reason. Use it to apply security locks or anything else
  that needs to be done on failure.

  ## Example

      def failed(user, error) do
        # Apply a lock to the user's account if they have failed to
        # log in too many times
      end
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