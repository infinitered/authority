defmodule Authority.Registration do
  @moduledoc """
  A behaviour for registering and updating users.

  ## Usage

      defmodule MyApp.Accounts.Registration do
        use Authority.Registration

        @impl Authority.Registration
        def create_user(params) do
          # Create a user
        end

        @impl Authority.Registration
        def get_user(id) do
          # Get a user by ID
        end

        @impl Authority.Registration
        def update_user(user, params) do
          # Update the user
        end

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
  An error returned from creating/updating/deleting a user.
  """
  @type error :: {:error, term}

  @doc "Creates a user."
  @callback create_user(params) :: {:ok, user} | error

  @doc "Gets a user by ID."
  @callback get_user(integer) :: {:ok, user} | error

  @doc "Updates a user."
  @callback update_user(user, params) :: {:ok, term} | error

  @doc "Deletes a user."
  @callback delete_user(user) :: {:ok, user} | error

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour Authority.Registration
    end
  end
end