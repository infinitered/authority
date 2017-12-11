defmodule Authority.Authentication.Store do
  @type opts :: Keyword.t()
  @type id :: any
  @type identity :: any
  @type credential :: any

  @callback identify(id, opts) :: {:ok, identity} | {:error, term}
  @callback validate(credential, identity, opts) :: :ok | {:error, term}
end