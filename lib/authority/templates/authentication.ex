defmodule Authority.Template.Authentication do
  @moduledoc false

  defmacro __using__(config) do
    quote location: :keep do
      @config unquote(config)
      @repo @config[:repo]

      @user_schema @config[:user_schema]
      @user_identity_field @config[:user_identity_field] || :email
      @user_password_field @config[:user_password_field] || :encrypted_password
      @user_password_algorithm @config[:user_password_algorithm] || :bcrypt

      use Authority.Authentication

      def authenticate(%@user_schema{} = user, _purpose) do
        {:ok, user}
      end

      def authenticate(credential, purpose) do
        super(credential, purpose)
      end

      @impl Authority.Authentication
      def identify(identifier) do
        case @repo.get_by(@user_schema, [{@user_identity_field, identifier}]) do
          nil -> {:error, :"invalid_#{@user_identity_field}"}
          user -> {:ok, user}
        end
      end

      if @user_password_algorithm == :bcrypt do
        @impl Authority.Authentication
        def validate(
              password,
              %@user_schema{@user_password_field => encrypted_password},
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