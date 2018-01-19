defmodule Authority.Tokenization do
  @moduledoc """
  A behaviour for creating tokens to represent resources (or credentials).

  Most commonly, this will be used to exchange credentials for a temporary
  token which will be used to authenticate future requests.

  ## Example

      defmodule MyApp.Accounts.Tokenization do
        use Authority.Tokenization

        @impl Authority.Tokenization
        def tokenize(credential, purpose \\\\ :any) do
          with {:ok, user} <- MyApp.Accounts.authenticate(credential, purpose) do
            # create a token associated with the user
          end
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
  Gets a token by an identifier, such as a string version of it.
  """
  @callback get_token(token) :: {:ok, token} | {:error, term}

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

  @optional_callbacks get_token: 1

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour Authority.Tokenization
    end
  end
end