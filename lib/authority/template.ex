defmodule Authority.Template do
  @moduledoc """
  `Authority` provides _implementations_, not just _behaviours_. Many apps will
  be able to use a template instead of implementing `Authority` behaviours
  manually.

  ## Configuration

  `Authority.Template` takes two options:

  1. `:behaviours`: A list of behaviours to implement
  2. `:config`: A list of options for those behaviours

  With this information, it will automatically implement the behaviours for
  you.

    defmodule MyApp.Accounts do
      use Authority.Template,
        behaviours: [...],
        config: [...]
    end
    
  Each behaviour requires configuration settings.

  #### Global Configuration

  - `:repo`: (required) the `Ecto.Repo` to use for database lookups. All
  `Authority` implementations currently assume you are using `Ecto`.

  Example:

    defmodule MyApp.Accounts do
      use Authority.Template,
        behaviours: [...],
        config: [repo: MyApp.Repo]
    end

  #### `Authority.Authentication`
  _Provides basic email/password (or username/password) authentication._

  - `:user_schema`: (required) the `Ecto.Schema` that represents a user in
  your app.

  - `:user_identity_field`: (optional) the identification field on
  `:user_schema`'s schema (Default: `:email`)

  - `:user_password_field`: (optional) the password field `:user_schema`'s
  schema (Default: `:encrypted_password`)

  - `:user_password_algorithm`: (option) the password hashing algorithm
  (Default: `:bcrypt`)

  Example:

    defmodule MyApp.Accounts do
      use Authority.Template,
        behaviours: [Authority.Authentication],
        config: [
          repo: MyApp.Repo,
          user_schema: MyApp.Accounts.Schema
        ]
    end

  #### `Authority.Locking`
  _Provides automatic account locking after a configurable number of
  attempts. Must be used with `Authority.Authentication`_.

  - `:lock_schema`: (required) the `Ecto.Schema` which represents a lock

  - `:lock_attempt_schema`: (required) the `Ecto.Schema` which represents a
  failed attempt to log in.

  - `:lock_expiration_field`: (optional) the expiration field on the
  `:lock_schema` schema (Default: `:expires_at`)

  - `:lock_user_assoc`: (optional) the association on `:lock_schema` which
  relates the lock to a user. (Default: `:user`)

  - `:lock_reason_field`: (optional) the field on `:lock_schema`'s schema
  which stores the reason for the lock. (Default: `:reason`)

  - `:lock_max_attempts`: (optional) the number of failed attempts that will
  create a lock. (Default: `5`)

  - `:lock_interval_seconds`: (optional) the interval in which attempts are
  counted. For example, '5 failures in 10 minutes'. (Default: `6000`, 10
  minutes)

  - `:lock_duration_seconds`: (optional) the duration that a user account
  will be locked. (Default: `6000`, 10 minutes)

  Example:

    defmodule MyApp.Accounts do
      use Authority.Template,
        behaviours: [
          Authority.Authentication,
          Authority.Locking
        ],
        config: [
          repo: MyApp.Repo,
          user_schema: MyApp.Accounts.User,
          lock_schema: MyApp.Accounts.Lock,
          lock_attempt_schema: MyApp.Accounts.LoginAttempt
        ]
    end


  #### `Authority.Tokenization`
  _Provides tokenization for credentials. Must be used with
  `Authority.Authentication`_.

  - `:token_schema`: (required) the `Ecto.Schema` which represents a token.

  - `:token_field`: (optional) the field on `:token_schema` which stores the
  token value. (Default: `:token`)

  - `:token_user_assoc`: (optional) the association on `:token_schema` which
  relates a token to a user. (Default: `:user`)

  - `:token_expiration_field`: (optional) the field on `:token_schema` which
  stores the expiration date of the token. (Default: `:expires_at`)

  - `:token_purpose_field`: (optional) the field on `:token_schema` which
  stores the purpose of the token. (Default: `:purpose`)

  Example:

    defmodule MyApp.Accounts do
      use Authority.Template,
        behaviours: [
          Authority.Authentication,
          Authority.Tokenization
        ],
        config: [
          repo: MyApp.Repo,
          user_schema: MyApp.Accounts.User,
          token_schema: MyApp.Accounts.Token
        ]
    end

  ## Usage

  Once you've configured your module, you can call `Authority` behaviour
  functions, depending on the behaviours your chose.

    alias MyApp.Accounts
    
    Accounts.authenticate({email, password})
    # => {:ok, %MyApp.Accounts.User{}}
    
    Accounts.authenticate(%MyApp.Accounts.Token{token: "valid"})
    # => {:ok, %MyApp.Accounts.User{}}
    
    Accounts.tokenize({email, password})
    # => {:ok, %MyApp.Accounts.Token{}}
    
    # After too many failed attempts to log in:
    Accounts.authenticate({email, password})
    # => {:error, %MyApp.Accounts.Lock{reason: :too_many_attempts}}
    
    Accounts.tokenize({email, password})
    # => {:error, %MyApp.Accounts.Lock{reason: :too_many_attempts}}
    
  ## Overriding

  You can override any callback function to add support for new data types.
  For example, you can override `identify` to provide support for custom
  types.

    defmodule MyApp.Accounts do
      use Authority.Template,
        behaviours: [Authority.Authentication],
        config: [repo: MyApp.Repo, user_schema: MyApp.Accounts.User]
        
      def identify(%MyApp.CustomStruct{} = struct) do
        # find user
      end
      
      def identify(other), do: super(other)
    end
    
  ## Without Ecto

  `Authority.Template` assumes you are using `Ecto`. However, nothing about
  the behaviours require you to use `Ecto`. You can simply implement the
  behaviours manually without using `Authority.Template`.
  """

  alias Authority.{
    Authentication,
    Tokenization,
    Template
  }

  @templates %{
    [Authentication] => Template.Authenticate,
    [Authentication, Locking] => Template.AuthenticateLock,
    [Authentication, Tokenization] => Template.AuthenticateTokenize,
    [Authentication, Locking, Tokenization] => Template.AuthenticateLockTokenize
  }

  defmodule Error do
    defexception [:message]
  end

  defmacro __using__(config) do
    {config, _} = Code.eval_quoted(config, [], __CALLER__)

    unless config[:behaviours] do
      raise Error, "You must specify :behaviours"
    end

    unless config[:config] do
      raise Error, "You must specify :config"
    end

    template = @templates[Enum.sort(config[:behaviours])]

    unless template do
      raise Error, "No template found for behaviours #{inspect(config[:behaviours])}"
    end

    quote do
      use unquote(template), unquote(config[:config])
    end
  end
end