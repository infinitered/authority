defmodule Authority.Test.Email do
  defstruct [:email]

  def sigil_E(email, _) do
    %__MODULE__{email: email}
  end
end