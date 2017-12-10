if Code.ensure_loaded?(Ecto) do
  defmodule Authority.Authentication.EctoStore do
    defmacro __using__(config) do
      quote do
        @opts unquote(opts)
        @config Enum.into(unquote(config), %{})

        @store Authority.Authentication.EctoStore
        @behaviour Authority.Authentication.Store

        def identify(identifier) do
          @store.identify(__MODULE__, identifier)
        end

        def validate(credential, identity) do
          @store.validate(__MODULE__, credential, identity)
        end

        def config do
          @config
        end

        defoverridable Authority.Authentication.Store
      end
    end

    def identify(module, identifier) do
      %{
        repo: repo,
        schema: schema,
        identity_field: field
      } = module.config()

      identity = repo.get_by(schema, [{field, identifier}])

      if identity do
        {:ok, identity}
      else
        {:error, :"invalid_#{field}"}
      end
    end

    def validate(module, credential, identity) do
      %{
        credential_field: field,
        credential_type: type,
        hash_algorithm: algorithm
      } = module.config()

      expected = identity[field]

      if equal?(credential, expected, type, algorithm) do
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
        Comeonin.Bcrypt.checkpw(expected, credential)
      end
    end
  end
end