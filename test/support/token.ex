defmodule Authority.Test.Token do
  defstruct [:token, :purpose]

  def sigil_K(token, _) do
    %__MODULE__{token: token}
  end
end