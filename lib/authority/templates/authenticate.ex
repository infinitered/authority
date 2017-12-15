defmodule Authority.Template.Authenticate do
  defmacro __using__(config) do
    quote do
      @config unquote(config)
      @repo @config[:repo]

      @user_module @config[:user_module]
      @user_identity_field @config[:user_identity_field]
      @user_password_field @config[:user_password_field]
      @user_password_algorithm @config[:user_password_algorithm] || :bcrypt

      use Authority.Authentication

      def identify(identifier) do
        case @repo.get_by(@user_module, [{@user_identity_field, identifier}]) do
          nil -> {:error, :"invalid_#{@user_identity_field}"}
          user -> {:ok, user}
        end
      end

      if @user_password_algorithm == :bcrypt do
        def validate(
              password,
              %@user_module{@user_password_field => encrypted_password},
              _purpose
            ) do
          case Comeonin.Bcrypt.checkpw(password, encrypted_password) do
            true -> :ok
            false -> {:error, :invalid_password}
          end
        end
      end

      defoverridable Authority.Authentication
    end
  end
end