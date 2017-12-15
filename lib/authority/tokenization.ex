defmodule Authority.Tokenization do
  @type token :: any
  @type identity :: any
  @type purpose :: atom
  @callback tokenize(identity, purpose) :: {:ok, token} | {:error, term}

  defmacro __using__(_) do
    quote do
      @behaviour Authority.Tokenization
    end
  end
end