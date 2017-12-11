if Code.ensure_loaded?(Ecto) do
  defmodule Authority.Authentication.EctoStore do
    defmacro __using__(config) do
      quote do
        @opts unquote(opts)
        @config Enum.into(unquote(config), %{})

        @store Authority.Authentication.EctoStore
        @behaviour Authority.Authentication.Store

        def identify(identifier) do
          @store.identify(@config, identifier)
        end

        def validate(credential, identity) do
          @store.validate(@config, credential, identity)
        end

        def config do
          @config
        end

        defoverridable Authority.Authentication.Store
      end
    end

    def identify(config, identifier) do
      identity =
        do_identify(
          config[:repo],
          config[:schema],
          config[:identity_fields] || config[:identity_field],
          identifier
        )

      if identity do
        {:ok, identity}
      else
        {:error, :"invalid_#{field}"}
      end
    end

    defp do_identify(repo, schema, field, identifier) when is_atom(field) do
      repo.get_by(schema, [{field, identifier}])
    end

    def do_identify(repo, schema, [field | _] = fields, identifier)
        when is_atom(field) do
      import Ecto.Query

      query =
        Enum.reduce(fields, schema, fn field, query ->
          or_where(schema, [{^field, ^identifier}])
        end)

      repo.one(query)
    end

    def validate(
          %{credential_field: field, credential_type: type, hash_algorithm: algorithm},
          credential,
          identity
        ) do
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