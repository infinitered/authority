defmodule Authority.Template.Recovery do
  @moduledoc false

  defmacro __using__(config) do
    quote location: :keep do
      @config unquote(config)
      @repo @config[:repo] || raise(":repo is required")
      @recovery_callback @config[:recovery_callback] || raise(":recovery_callback is required")

      {recovery_callback_module, recovery_callback_function} =
        case @recovery_callback do
          function when is_atom(function) ->
            {__MODULE__, function}

          {module, function} ->
            {module, function}
        end

      @recovery_callback_module recovery_callback_module
      @recovery_callback_function recovery_callback_function

      unless is_atom(@recovery_callback) || is_tuple(@recovery_callback) do
        raise(":recovery_callback must be an atom or tuple")
      end

      use Authority.Recovery

      @doc """
      Starts the password recovery process for a user.
      """
      @impl Authority.Recovery
      @spec recover(String.t()) :: :ok | {:error, term}
      def recover(identifier) do
        with {:ok, token} <- tokenize(identifier, :recovery) do
          apply(@recovery_callback_module, @recovery_callback_function, [identifier, token])
        end
      end

      defoverridable Authority.Recovery
    end
  end
end