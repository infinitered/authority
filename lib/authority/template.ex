defmodule Authority.Template do
  @moduledoc """
  `Authority` provides _implementations_, not just _behaviours_. Many apps will
  be able to use a template instead of implementing `Authority` behaviours
  manually.

  ## Definition

  `Authority` expects you to define a module in your application to hold all the
  `Authority`-related functions. This module could be called `Accounts`, for
  example.

      defmodule MyApp.Accounts do
        use Authority.Template,
          behaviours: [...], # A list of Authority behaviours
          config: [...] # A keyword list of configuration options
      end

  ### Global Configuration

      defmodule MyApp.Accounts do
        use Authority.Template,
          behaviours: [...],
          config: [repo: MyApp.Repo]
      end

  - `:repo`: (required) The `Ecto.Repo` to use for database lookups.

  ### `Authority.Authentication`
  _Provides basic email/password (or username/password) authentication._

      defmodule MyApp.Accounts do
        use Authority.Template,
          behaviours: [Authority.Authentication],
          config: [
            repo: MyApp.Repo,
            user_schema: MyApp.Accounts.Schema
          ]
      end

  - `:user_schema`: (required) the `Ecto.Schema` that represents a user in
  your app.

  - `:user_identity_field`: (optional) the identification field on
  `:user_schema`'s schema (Default: `:email`)

  - `:user_password_field`: (optional) the password field `:user_schema`'s
  schema (Default: `:encrypted_password`)

  - `:user_password_algorithm`: (optional) the password hashing algorithm
  (Default: `:bcrypt`)

  ### `Authority.Locking`
  _Provides automatic account locking after a configurable number of
  attempts. Must be used with `Authority.Authentication`_.

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

  ### `Authority.Recovery`
  _Provides account recovery. Requires `Authority.Tokenization`._

      defmodule MyApp.Accounts do
        use Authority.Template,
          behaviours: [
            Authority.Authentication,
            Authority.Recovery,
            Authority.Tokenization
          ],
          config: [
            repo: MyApp.Repo,
            user_schema: MyApp.Accounts.User,
            token_schema: MyApp.Accounts.Token,
            recovery_callback: {MyApp.Notifications, :forgot_password}
          ]
      end

      defmodule MyApp.Notifications do
        def forgot_password(email, token) do
          # Send the forgot password email
        end
      end

  - `:recovery_callback`: an atom function name or module/function tuple to
    be called after generating a recovery token. This function is actually
    responsible to send the "forgot password" email to the user.

  ### `Authority.Registration`
  _Provides user registration and updating._

      defmodule MyApp.Accounts do
        use Authority.Template,
          behaviours: [
            Authority.Registration
          ],
          config: [
            repo: MyApp.Repo,
            user_schema: MyApp.Accounts.User
          ]
      end

  - `:user_schema`: (required) the `Ecto.Schema` which represents a user.

  ### `Authority.Tokenization`
  _Provides tokenization for credentials. Must be used with
  `Authority.Authentication`_.

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

  - `:token_schema`: (required) the `Ecto.Schema` which represents a token.

  - `:token_field`: (optional) the field on `:token_schema` which stores the
  token value. (Default: `:token`)

  - `:token_user_assoc`: (optional) the association on `:token_schema` which
  relates a token to a user. (Default: `:user`)

  - `:token_expiration_field`: (optional) the field on `:token_schema` which
  stores the expiration date of the token. (Default: `:expires_at`)

  - `:token_purpose_field`: (optional) the field on `:token_schema` which
  stores the purpose of the token. (Default: `:purpose`)

  ## Using Your Module

  Once you've configured your module, you can call `Authority` behaviour
  functions, depending on the behaviours your chose.

      alias MyApp.Accounts

      Accounts.create_user(%{
        email: "my@email.com",
        password: "password",
        password_confirmation: "password"
      })
      # => {:ok, %MyApp.Accounts.User{}}
      
      Accounts.authenticate({"my@email.com", "password"})
      # => {:ok, %MyApp.Accounts.User{}}
      
      Accounts.authenticate(%MyApp.Accounts.Token{token: "valid"})
      # => {:ok, %MyApp.Accounts.User{}}
      
      Accounts.tokenize({"my@email.com", "password"})
      # => {:ok, %MyApp.Accounts.Token{}}
      
      # After too many failed attempts to log in:
      Accounts.authenticate({"my@email.com", "invalid"})
      # => {:error, %MyApp.Accounts.Lock{reason: :too_many_attempts}}
      
      Accounts.tokenize({"my@email.com", "invalid"})
      # => {:error, %MyApp.Accounts.Lock{reason: :too_many_attempts}}

      # Send a password reset email
      Accounts.recover("my@email.com")
    
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
        
        # Use `super` to fall back to the identify/1 function
        # provided by the template.
        def identify(other), do: super(other)
      end
    
  ## Without Ecto

  `Authority.Template` assumes you are using `Ecto`. However, nothing about
  the behaviours require you to use `Ecto`. You can simply implement the
  behaviours manually without using `Authority.Template`.

  See each behaviour's documentation for details.
  """

  alias Authority.{
    Authentication,
    Locking,
    Recovery,
    Registration,
    Tokenization,
    Template
  }

  @templates %{
    Authentication => Template.Authentication,
    Locking => Template.Locking,
    Recovery => Template.Recovery,
    Registration => Template.Registration,
    Tokenization => Template.Tokenization
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

    for behaviour <- config[:behaviours] do
      unless @templates[behaviour] do
        raise Error, "No template found for behaviour #{inspect(behaviour)}"
      end

      quote location: :keep do
        use unquote(@templates[behaviour]), unquote(config[:config])
      end
    end
  end

  @doc false
  def implements?(module, Authority.Authentication) do
    Module.defines?(module, {:authenticate, 2})
  end

  def implements?(module, Authority.Tokenization) do
    Module.defines?(module, {:tokenize, 2})
  end

  def implements?(_module, _behaviour), do: false
end