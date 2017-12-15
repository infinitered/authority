defmodule Authority.Template do
  alias Authority.{
    Authentication,
    Tokenization,
    Template
  }

  @templates %{
    [Authentication] => Template.Authenticate,
    [Authentication, Tokenization] => Template.AuthenticateTokenize
  }

  defmodule Error do
    defexception [:message]
  end

  defmacro __using__(config) do
    {config, _} = Code.eval_quoted(config, [], __CALLER__)

    unless config[:behaviours] do
      raise Error, "You must specify :behaviours"
    end

    unless config[:config] do
      raise Error, "You must specify :config"
    end

    template = @templates[Enum.sort(config[:behaviours])]

    unless template do
      raise Error, "No template found for behaviours #{inspect(config[:behaviours])}"
    end

    quote do
      use unquote(template), unquote(config[:config])
    end
  end
end