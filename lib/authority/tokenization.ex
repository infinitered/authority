defmodule Authority.Tokenization do
  @moduledoc """
  A behaviour for converting resources (or credentials) into tokens.

  ## Usage

      defmodule MyApp.Accounts.Tokenization do
        use Authority.Tokenization

        @impl Authority.Tokenization
        def tokenize(resource, purpose) do
          # create a token for the resource
        end
      end
  """

  @typedoc """
  A token. Can be any type that makes sense for your application.
  """
  @type token :: any

  @typedoc """
  A resource to be converted into a token. Can be any type that makes sense
  for the application.
  """
  @type resource :: any

  @typedoc """
  The purpose for the token.
  """
  @type purpose :: atom

  @doc """
  Creates a token, assuming the `:any` purpose, representing a given resource.
  """
  @callback tokenize(resource) :: {:ok, token} | {:error, term}

  @doc """
  Create a token with a given purpose, representing a given resource. For
  example, you might convert credentials (email/password) into a token
  representing a user.
  """
  @callback tokenize(resource, purpose) :: {:ok, token} | {:error, term}

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour Authority.Tokenization
    end
  end
end
