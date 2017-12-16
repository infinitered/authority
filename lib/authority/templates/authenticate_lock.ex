defmodule Authority.Template.AuthenticateLock do
  @moduledoc false

  defmacro __using__(config) do
    quote do
      @config unquote(config)

      use Authority.Template.Authenticate, @config
      use Authority.Template.Locking, @config
    end
  end
end