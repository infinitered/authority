defmodule Authority.Template do
  @moduledoc """
  `Authority` offers _implementations_, not just _behaviours_. Many
  applications will be able to use a template instead of implementing
  `Authority` behaviours manually.

  ## Templates

  `Authority` ships with the following templates. All _existing_ templates
  assume you are using Ecto for persistence. However, nothing about
  `Authority`'s _behaviours_ require you to use `Ecto`.

  ### Email/Password
  _Basic email/password authentication only._

  Definition:

      defmodule MyApp.Accounts do
        use Authentication.Template,
          behaviours: [
            Authority.Authentication
          ],
          config: [
            repo: MyApp.Repo, 
            user_schema: MyApp.Accounts.User
          ]
      end

  Usage:
    
      MyApp.Accounts.authenticate({email, password})
      # => {:ok, %MyApp.Accounts.User{}}

  Options:

  - `:repo`: (required) the `Ecto.Repo` to use for database lookups.

  - `:user_schema`: (required) the `Ecto.Schema` that represents a user in your app.

  - `:user_identity_field`: (optional) the identification field on `:user_schema`'s schema
    (Default: `:email`)

  - `:user_password_field`: (optional) the password field `:user_schema`'s schema
    (Default: `:encrypted_password`)

  - `:user_password_algorithm`: (option) the password hashing algorithm
    (Default: `:bcrypt`)

  ### Email/Password + Locking
  _Email/password authentication, plus automatic account locking after
    a configurable number of attempts during a given time period._

  Definition:

      defmodule MyApp.Accounts do
        use Authentication.Template,
          behaviours: [
            Authority.Authentication,
            Authority.Locking
          ],
          config: [
            repo: MyApp.Repo,
            user_schema: MyApp.Accounts.User,
            lock_schema: MyApp.Accounts.Lock,
            lock_attempt_schema: MyApp.Accounts.LoginAttempt,
            lock_max_attempts: 5,
            lock_interval_seconds: 120,
            lock_duration_seconds: 6_000
          ]
      end

  Usage

      MyApp.Accounts.authenticate({email, password})
      # => {:ok, %MyApp.Accounts.User{}}

      # After too many failures
      MyApp.Accounts.authenticate({"valid@email.com", "invalid"})
      # => {:error, %MyApp.Accounts.Lock{reason: :too_many_attempts}}

  Options:

  - `:lock_schema`: (required) the `Ecto.Schema` which represents a lock

  - `:lock_attempt_schema`: (required) the `Ecto.Schema` which represents
    a failed attempt to log in.

  - `:lock_expiration_field`: (optional) the expiration field on the
    `:lock_schema` schema (Default: `:expires_at`)

  - `:lock_user_assoc`: (optional) the association on `:lock_schema` which
    relates the lock to a user. (Default: `:user`)

  - `:lock_reason_field`: (optional) the field on `:lock_schema`'s schema
    which stores the reason for the lock. (Default: `:reason`)

  - `:lock_max_attempts`: (optional) the number of failed attempts that will
    create a lock. (Default: `5`)

  - `:lock_interval_seconds`: (optional) the interval in which attempts
    are counted. For example, '5 failures in 10 minutes'. (Default: `6000`)

  - `:lock_duration_seconds`: (optional) the duration that a user account
    will be locked. (Default: `6000`)

  ### Email/Password + Tokenization
  _Email/password authentication, plus credential tokenization._

  Definition:

      defmodule MyApp.Accounts do
        use Authentication.Template,
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

  Usage:

      MyApp.Accounts.authenticate({email, password})
      # => {:ok, %MyApp.Accounts.User{}}

      MyApp.Accounts.tokenize({email, password})
      # => {:ok, %MyApp.Accounts.Token{}}

  Options:

  - `:token_schema`: (required) the `Ecto.Schema` which represents a token.

  - `:token_field`: (optional) the field on `:token_schema` which stores the
    token value. (Default: `:token`)

  - `:token_user_assoc`: (optional) the association on `:token_schema` which
    relates a token to a user. (Default: `:user`)

  - `:token_expiration_field`: (optional) the field on `:token_schema` which
    stores the expiration date of the token. (Default: `:expires_at`)

  - `:token_purpose_field`: (optional) the field on `:token_schema` which
    stores the purpose of the token. (Default: `:purpose`)

  ### Email/Password + Locking + Tokenization

  _Email/password authentication, plus credential tokenization._

  Definition:

      defmodule MyApp.Accounts do
        use Authentication.Template,
          behaviours: [
            Authority.Authentication, 
            Authority.Locking,
            Authority.Tokenization
          ],
          config: [
            repo: MyApp.Repo,
            user_schema: MyApp.Accounts.User,
            token_schema: MyApp.Accounts.Token,
            lock_schema: MyApp.Accounts.Lock,
            lock_attempt_schema: MyApp.Accounts.LoginAttempt
          ]
      end

  Usage:

      MyApp.Accounts.authenticate({email, password})
      # => {:ok, %MyApp.Accounts.User{}}

      MyApp.Accounts.tokenize({email, password})
      # => {:ok, %MyApp.Accounts.Token{}}

      # Too many login attempts
      MyApp.Accounts.authenticate({"valid@email.com", "invalid"})
      # => {:error, %MyApp.Accounts.Lock{reason: :too_many_attempts}}

      MyApp.Accounts.tokenize({"valid@email.com", "invalid"})
      # => {:error, %MyApp.Accounts.Lock{reason: :too_many_attempts}}

  Options:

  _All of the options described above can be used._
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