defmodule Authority.Test.Password do
  defstruct [:password]

  def sigil_P(password, _) do
    %__MODULE__{password: password}
  end
end