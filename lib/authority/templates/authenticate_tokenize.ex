defmodule Authority.Template.AuthenticateTokenize do
  @moduledoc false

  defmacro __using__(config) do
    quote do
      @config unquote(config)
      @repo @config[:repo]

      @user_schema @config[:user_schema]
      @user_identity_field @config[:user_identity_field] || :email
      @user_password_field @config[:user_password_field] || :encrypted_password
      @user_password_algorithm @config[:user_password_algorithm] || :bcrypt

      @token_schema @config[:token_schema]
      @token_field @config[:token_field] || :token
      @token_user_assoc @config[:token_user_assoc] || :user
      @token_expiration_field @config[:token_expiration_field] || :expires_at
      @token_purpose_field @config[:token_purpose_field] || :purpose

      # AUTHENTICATION
      # —————————————————————————————————————————————————————————————————————————

      use Authority.Authentication

      # Refresh the token from the `token` attribute, so that you
      # don't have to pass the full token
      @impl Authority.Authentication
      def before_identify(%@token_schema{@token_field => value} = token) do
        token =
          @token_schema
          |> @repo.get_by([{@token_field, value}])
          |> @repo.preload(@token_user_assoc)

        case token do
          nil -> {:error, :invalid_token}
          token -> {:ok, token}
        end
      end

      def before_identify(identifier), do: {:ok, identifier}

      @impl Authority.Authentication
      def identify(%@token_schema{@token_user_assoc => %@user_schema{} = user}) do
        {:ok, user}
      end

      def identify(identifier) do
        case @repo.get_by(@user_schema, [{@user_identity_field, identifier}]) do
          nil -> {:error, :"invalid_#{@user_identity_field}"}
          user -> {:ok, user}
        end
      end

      @impl Authority.Authentication
      def validate(%@token_schema{@token_purpose_field => token_purpose} = token, _user, purpose)
          when token_purpose == :any or token_purpose == purpose do
        if DateTime.compare(DateTime.utc_now(), token[@token_expiration_field]) == :lt do
          :ok
        else
          {:error, :expired_token}
        end
      end

      def validate(%@token_schema{}, _user, _purpose) do
        {:error, :invalid_token_for_purpose}
      end

      if @user_password_algorithm == :bcrypt do
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

      # TOKENIZATION 
      # —————————————————————————————————————————————————————————————————————————

      use Authority.Tokenization

      @impl Authority.Tokenization
      def tokenize({identifier, password}, purpose) do
        with {:ok, user} <- authenticate({identifier, password}, purpose) do
          do_tokenize(user, purpose)
        end
      end

      def tokenize(identifier, :recovery) do
        with {:ok, user} <- identify(identifier) do
          do_tokenize(user, purpose)
        end
      end

      def tokenize(_other, _purpose) do
        {:error, :invalid_credential_for_purpose}
      end

      defp do_tokenize(user, purpose) do
        %@token_schema{@token_user_assoc => user}
        |> @token_schema.insert_changeset(%{@token_purpose_field => purpose})
        |> @repo.insert()
      end

      defoverridable Authority.Tokenization
    end
  end
end