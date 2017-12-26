defmodule Authority.Registration do
  @moduledoc """
  A behaviour for registering and updating users.

  ## Usage

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

  @doc "Returns a changeset for a new user."
  @callback change_user :: {:ok, changeset} | error

  @doc "Returns a changeset for a given user."
  @callback change_user(user) :: {:ok, changeset} | error

  @doc "Returns a changeset for a given user and params."
  @callback change_user(user, params :: map) :: {:ok, changeset} | error

  @doc "Gets a user by ID."
  @callback get_user(integer) :: {:ok, user} | error

  @doc "Updates a user."
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