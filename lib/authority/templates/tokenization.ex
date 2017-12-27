defmodule Authority.Template.Tokenization do
  @moduledoc false

  defmacro __using__(config) do
    quote location: :keep do
      @config unquote(config)
      @repo @config[:repo]

      @token_schema @config[:token_schema] || raise(":token_schema is required")
      @user_identity_field @config[:user_identity_field] || :email
      @token_field @config[:token_field] || :token
      @token_user_assoc @config[:token_user_assoc] || :user
      @token_expiration_field @config[:token_expiration_field] || :expires_at
      @token_purpose_field @config[:token_purpose_field] || :purpose

      # AUTHENTICATION
      # —————————————————————————————————————————————————————————————————————————

      # Refresh the token from the `token` attribute, so that you
      # don't have to pass the full token
      @doc false
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

      def before_identify(other), do: super(other)

      @impl Authority.Authentication
      def identify(%@token_schema{@token_user_assoc => %@user_schema{} = user}) do
        {:ok, user}
      end

      def identify(identifier), do: super(identifier)

      @doc false
      @impl Authority.Authentication
      def validate(%@token_schema{@token_purpose_field => token_purpose} = token, _user, purpose)
          when token_purpose == :any or token_purpose == purpose do
        if DateTime.compare(DateTime.utc_now(), Map.get(token, @token_expiration_field)) == :lt do
          :ok
        else
          {:error, :expired_token}
        end
      end

      def validate(%@token_schema{} = schema, _user, _purpose) do
        {:error, :invalid_token_for_purpose}
      end

      def validate(credential, user, purpose), do: super(credential, user, purpose)

      # TOKENIZATION 
      # —————————————————————————————————————————————————————————————————————————

      use Authority.Tokenization

      @doc """
      Converts an #{@user_identity_field}/password combination into a `#{inspect(@token_schema)}`.

      ## Examples

          #{inspect(__MODULE__)}.tokenize({"valid_#{@user_identity_field}", "password"})
          # => {:ok, %#{inspect(@token_schema)}{}}

          #{inspect(__MODULE__)}.tokenize({"valid_#{@user_identity_field}", "invalid_password"})
          # => {:error, :invalid_password}

          #{inspect(__MODULE__)}.tokenize("valid_#{@user_identity_field}", :recovery)
          # => {:ok, %#{inspect(@token_schema)}{}}

          #{inspect(__MODULE__)}.tokenize("valid_#{@user_identity_field}")
          # => {:error, :invalid_credential_for_purpose}
      """
      @impl Authority.Tokenization
      def tokenize(credential, purpose \\ :any)

      def tokenize({identifier, password}, purpose) do
        with {:ok, user} <- authenticate({identifier, password}, purpose) do
          do_tokenize(user, purpose)
        end
      end

      def tokenize(identifier, :recovery) do
        with {:ok, user} <- identify(identifier) do
          do_tokenize(user, :recovery)
        end
      end

      def tokenize(_other, _purpose) do
        {:error, :invalid_credential_for_purpose}
      end

      defp do_tokenize(user, purpose) do
        %@token_schema{@token_user_assoc => user}
        |> @token_schema.changeset(%{@token_purpose_field => purpose})
        |> @repo.insert()
      end

      @doc """
      Gets a `#{inspect(@token_schema)}` by its string `#{inspect(@token_field)}` field.

      ## Examples

          #{inspect(__MODULE__)}.get_token("valid")
          # => {:ok, %#{inspect(@token_schema)}{}}

          #{inspect(__MODULE__)}.get_token("invalid")
          # => {:error, :not_found}
      """
      @spec get_token(String.t()) :: {:ok, @token_schema.t()} | {:error, :not_found}
      def get_token(token) when is_binary(token) do
        case @repo.get_by(@token_schema, [{@token_field, token}]) do
          nil ->
            {:error, :not_found}

          token ->
            {:ok, token}
        end
      end

      def get_token(_token) do
        {:error, :not_found}
      end

      defoverridable Authority.Tokenization
    end
  end
end