defmodule Authority.Authentication.Store do
  @type identity :: any
  @type credential :: any

  @callback identify(any) :: {:ok, identity} | {:error, term}
  @callback validate(credential, identity) :: :ok | {:error, term}
end