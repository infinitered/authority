defmodule Authority.Recovery do
  @moduledoc """
  A minimal behaviour for recovering a user account.

  ## Example

  If your `id` is an email address, your `Recovery` module might look
  something like this:

      defmodule MyApp.Accounts.Recovery do
        use Authority.Recovery

        @impl Authority.Recovery
        def recover(email) do
          # Send a password reset email to the user
        end
      end
  """

  @typedoc "An identifier representing a user, such as an email address."
  @type id :: any

  @doc """
  Initiates an account recovery process for the user associated with the
  identifier, however that looks for your application.
  """
  @callback recover(id) :: :ok | {:error, term}

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour Authority.Recovery
    end
  end
end