defmodule Authority.Registration do
  @moduledoc """
  A behaviour for registering and updating users.

  The core callbacks are:

    - `create_user/1`
    - `get_user/1`
    - `update_user/2`
    - `delete_user/1`

  Applications which have a concept of changesets, (such as `Ecto.Changeset`
  for example) may find it useful to implement the optional callbacks as well:

    - `change_user/0`
    - `change_user/1`
    - `change_user/2`

  ## Example

      defmodule MyApp.Accounts.Registration do
        use Authority.Registration

        # OPTIONAL
        @impl Authority.Registration
        def change_user do
          # Return a changeset for a new user
        end

        # OPTIONAL
        @impl Authority.Registration
        def change_user(user, params \\ %{}) do
          # Return a changeset for an existing user
        end

        # REQUIRED
        @impl Authority.Registration
        def create_user(params) do
          # Create a user
        end

        # REQUIRED
        @impl Authority.Registration
        def get_user(id) do
          # Get a user by ID
        end

        # REQUIRED
        @impl Authority.Registration
        def update_user(user, params) do
          # Update the user
        end

        # REQUIRED
        @impl Authority.Registration
        def delete_user(user) do
          # Delete the user
        end
      end
  """

  @typedoc """
  Parameters needed to create a user. For example,

      %{
        email: "my@email.com",
        password: "password",
        password_confirmation: "password"
      }
  """
  @type params :: map

  @typedoc """
  An identifier for the user, such as an integer ID used as its primary
  key in the database.
  """
  @type id :: any

  @typedoc """
  A user. Can be any type that represents a user for your application.
  """
  @type user :: any

  @typedoc """
  Any type that represents a changeset.
  """
  @type changeset :: any

  @typedoc """
  An error returned from creating/updating/deleting a user.
  """
  @type error :: {:error, term}

  @doc "Creates a user."
  @callback create_user(params) :: {:ok, user} | error

  @doc "OPTIONAL. Returns a changeset for a new user."
  @callback change_user :: {:ok, changeset} | error

  @doc "OPTIONAL. Returns a changeset for a given user."
  @callback change_user(user) :: {:ok, changeset} | error

  @doc "OPTIONAL. Returns a changeset for a given user and params."
  @callback change_user(user, params :: map) :: {:ok, changeset} | error

  @doc "Gets a user by ID."
  @callback get_user(id) :: {:ok, user} | error

  @doc "Updates a user with the given parameters."
  @callback update_user(user, params) :: {:ok, term} | error

  @doc "Deletes a user."
  @callback delete_user(user) :: {:ok, user} | error

  @optional_callbacks change_user: 0, change_user: 1, change_user: 2

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour Authority.Registration
    end
  end
end