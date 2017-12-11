if Code.ensure_loaded?(Ecto) do
  # use Authority.EctoStore,
  #   repo: MyApp.Repo,
  #   authentication: %{
  #     schema: MyApp.Accounts.User,
  #     identity_field: :email,
  #     credential_field: :password,
  #     credential_type: :hash,
  #     hash_algorithm: :bcrypt
  #   },
  #   exchange: %{
  #     schema: MyApp.Accounts.Token,
  #     identity_assoc: :user,
  #     token_field: :token,
  #     token_type: :uuid,
  #     expiry_field: :expires_at,
  #     context_field: :context,
  #     contexts: %{
  #       identity: %{
  #         default: true,
  #         expires_in_seconds: 60,
  #       },
  #       recovery: %{
  #         expires_in_seconds: 60
  #       }
  #     }
  #   }
  defmodule Authority.EctoStore do
    defmodule ConfigError do
      defexception [:message]
    end

    defmacro __using__(config) do
      {compile_config, _} = Code.eval_quoted(config, [], __CALLER__)
      validate_config!(compile_config)
      opts = default_opts(compile_config)

      quote do
        @config Enum.into(unquote(config), %{})
        @store Authority.EctoStore

        if @config[:authentication] do
          @behaviour Authority.Authentication.Store

          def identify(identifier, opts \\ unquote(opts)) do
            @store.identify(@config, identifier, Enum.into(opts, %{}))
          end

          def validate(credential, identity, opts \\ unquote(opts)) do
            @store.validate(@config, credential, identity, Enum.into(opts, %{}))
          end

          defoverridable Authority.Authentication.Store
        end

        if @config[:exchange] do
          @behaviour Authority.Exchange.Store

          def exchange(identity, opts \\ []) do
            @store.exchange(@config, identity, Enum.into(opts, %{}))
          end

          defoverridable Authority.Exchange.Store
        end

        def config do
          @config
        end
      end
    end

    @doc false
    def exchange(%{repo: repo, exchange: exchange}, identity, %{context: context}) do
      expires_in_seconds = exchange[:contexts][context][:expires_in_seconds]

      fields = %{
        exchange[:identity_assoc] => identity,
        exchange[:expiry_field] => generate_expires_at(expires_in_seconds),
        exchange[:context_field] => context,
        exchange[:token_field] => generate_token(exchange[:token_type])
      }

      exchange[:schema]
      |> struct(fields)
      |> repo.insert()
    end

    defp generate_token(:uuid) do
      Ecto.UUID.generate()
    end

    defp generate_expires_at(seconds) do
      DateTime.utc_now()
      |> DateTime.to_unix()
      |> Kernel.+(seconds)
      |> DateTime.from_unix!()
    end

    # Identify exchange schema
    @doc false
    def identify(
          %{
            repo: repo,
            exchange: %{
              schema: schema,
              token_field: token_field,
              identity_assoc: identity_assoc
            }
          },
          %{__struct__: schema} = token,
          _opts
        ) do
      token =
        schema
        |> repo.get_by([{token_field, Map.get(token, token_field)}])
        |> repo.preload(identity_assoc)

      if token do
        {:ok, Map.get(token, identity_assoc)}
      else
        {:error, :invalid_token}
      end
    end

    # Identify username, email
    @doc false
    def identify(%{repo: repo, authentication: %{schema: schema} = auth}, identifier, _opts) do
      identity =
        do_identify(
          repo,
          schema,
          auth[:identity_fields] || auth[:identity_field],
          identifier
        )

      if identity do
        {:ok, identity}
      else
        fields = auth[:identity_fields] || [auth[:identity_field]]

        fields =
          fields
          |> Enum.map(&to_string/1)
          |> Enum.join("_or_")

        {:error, :"invalid_#{fields}"}
      end
    end

    defp do_identify(repo, schema, field, identifier) when is_atom(field) do
      repo.get_by(schema, [{field, identifier}])
    end

    defp do_identify(repo, schema, [field | _] = fields, identifier)
         when is_atom(field) do
      import Ecto.Query

      query =
        Enum.reduce(fields, schema, fn field, query ->
          or_where(query, ^[{field, identifier}])
        end)

      repo.one(query)
    end

    @doc false
    def validate(
          %{
            exchange: %{
              schema: schema,
              context_field: context_field,
              expiry_field: expiry_field
            }
          },
          %{__struct__: schema} = token,
          _identity,
          %{context: context}
        ) do
      token_context = Map.get(token, context_field)
      expires_at = Map.get(token, expiry_field)

      cond do
        token_context != context ->
          {:error, :token_invalid_for_context}

        DateTime.compare(DateTime.utc_now(), expires_at) in [:gt, :eq] ->
          {:error, :token_expired}

        true ->
          :ok
      end
    end

    def validate(
          %{authentication: %{credential_field: field, credential_type: type} = auth},
          credential,
          identity,
          _opts
        ) do
      expected = Map.get(identity, field)

      if equal?(credential, expected, type, auth[:hash_algorithm]) do
        :ok
      else
        {:error, :"invalid_#{field}"}
      end
    end

    defp equal?(credential, expected, :string, _) do
      credential == expected
    end

    if Code.ensure_loaded?(Comeonin.Bcrypt) do
      defp equal?(credential, expected, :hash, :bcrypt) do
        Comeonin.Bcrypt.checkpw(credential, expected)
      end
    end

    defp validate_config!(config) do
      unless config[:repo], do: raise(ConfigError, ":repo module not set")
      validate_authentication!(config[:authentication])
      validate_exchange!(config[:exchange])
    end

    defp validate_authentication!(config) when is_map(config) do
      fields = [
        :schema,
        :identity_field,
        :credential_field,
        :credential_type
      ]

      for field <- fields do
        unless config[field],
          do: raise(ConfigError, "no #{inspect(field)} set for :authentication")
      end

      if config[:credential_type] == :hash && config[:hash_algorithm] != :bcrypt do
        raise ConfigError, """
        :hash_algorithm is required for :authentication when :credential_type == :hash. 
        Valid algorithms: :bcrypt
        """
      end
    end

    defp validate_authentication!(_other), do: :noop

    defp validate_exchange!(config) when is_map(config) do
      fields = [
        :schema,
        :identity_assoc,
        :token_field,
        :token_type,
        :expiry_field,
        :context_field,
        :contexts
      ]

      for field <- fields do
        unless config[field], do: raise(ConfigError, "no #{inspect(field)} set for :exchange")
      end

      for {context, settings} <- config[:contexts] do
        unless is_integer(settings[:expires_in_seconds]),
          do:
            raise(
              ConfigError,
              "invalid :expires_in_seconds in context #{inspect(context)} for :exchange"
            )
      end

      default_context =
        Enum.find(config[:contexts], fn {_context, settings} -> settings[:default] == true end)

      unless default_context do
        raise ConfigError, """
        no default context specified for :exchange.

            contexts: %{
              my_context: %{
                default: true, # add this line
                expires_in_seconds: 100
              }
            }
        """
      end
    end

    defp validate_exchange!(_other), do: :noop

    defp default_opts(config) do
      if config[:authentication] && config[:exchange] do
        default_context =
          Enum.find_value(config[:exchange][:contexts], fn {context, settings} ->
            if settings[:default] do
              context
            end
          end)

        [context: default_context]
      else
        []
      end
    end
  end
end