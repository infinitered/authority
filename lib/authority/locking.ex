defmodule Authority.Locking do
  @moduledoc """
  A behaviour for locking and unlocking resources, such as user accounts.

  ## Usage

      defmodule MyApp.Accounts.Locking do
        use Authority.Locking

        @impl Authority.Locking
        def get_lock(user) do
          # get the current active lock on the user
        end

        @impl Authority.Locking
        def lock(user, reason) do
          # apply a lock to the user for a given reason
        end

        @impl Authority.Locking
        def unlock(user) do
          # remove any active locks from the user's account
        end
      end

  Once you have this module, you can use it within your authentication module:

      defmodule MyApp.Accounts.Authentication do
        use Authority.Authentication

        alias MyApp.Accounts.Locking

        # Check for active locks on the user's account before
        # validating their credentials
        def before_validate(user, _purpose) do
          case Locking.get_lock(user) do
            {:ok, lock} -> {:error, lock}
            _other -> :ok
          end
        end

        def failed(user) do
          # Lock the user account after too many 
          # failed attempts
        end

        # ...
      end
  """

  @typedoc """
  A resource that can be locked/unlocked.
  """
  @type resource :: any

  @typedoc """
  A lock on a resource. Can be any type or struct that makes sense for your
  application.
  """
  @type lock :: any

  @typedoc """
  The reason a lock was applied to a resource.
  """
  @type reason :: atom

  @type error :: {:error, term}

  @doc """
  Get the currently active lock on a given resource, if any.
  """
  @callback get_lock(resource) :: {:ok, lock} | error

  @doc """
  Lock a given resource for a given reason. The reason should be stored with
  and returned with the lock.
  """
  @callback lock(resource, reason) :: {:ok, lock} | error

  @doc """
  Unlock a given resource.
  """
  @callback unlock(resource) :: :ok | error

  defmacro __using__(_) do
    quote do
      @behaviour Authority.Locking
    end
  end
end