defmodule Authority.Exchange.Store do
  alias Authority.Authentication

  @type opts :: Keyword.t()

  @callback exchange(Authentication.identity(), opts) ::
              {:ok, Authentication.credential()}
              | {:error, term}
end