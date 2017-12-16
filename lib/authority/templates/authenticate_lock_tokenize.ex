defmodule Authority.Template.AuthenticateTokenizeLock do
  @moduledoc false

  defmacro __using__(config) do
    quote do
      @config unquote(config)

      use Authority.Template.AuthenticateTokenize, @config
      use Authority.Template.Locking, @config
    end
  end
end