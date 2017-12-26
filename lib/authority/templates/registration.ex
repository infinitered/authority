defmodule Authority.Template.Registration do
  @moduledoc false

  alias Authority.Template

  defmacro __using__(config) do
    quote do
      use Authority.Registration

      @config unquote(config)

      # Inject different versions of update_user/2 and delete_user/1
      # based on what other behaviours you are using
      @before_compile unquote(__MODULE__)

      @repo @config[:repo] || raise(":repo is required")
      @user_schema @config[:user_schema] || raise(":user_schema is required")

      @doc """
      Create a `#{inspect(@user_schema)}` from the parameters.
      """
      @impl Authority.Registration
      @spec create_user(map) :: {:ok, @user_schema.t()} | {:error, Ecto.Changeset.t()}
      def create_user(params) do
        %@user_schema{}
        |> @user_schema.changeset(params)
        |> @repo.insert()
      end

      @doc """
      Gets a `#{inspect(@user_schema)}` by ID.
      """
      @impl Authority.Registration
      @spec get_user(integer) :: {:ok, @user_schema.t} | {:error, :not_found}
      def get_user(id) do
        case @repo.get(@user_schema, id) do
          nil ->
            {:error, :not_found}

          user ->
            {:ok, user}
        end
      end

      defoverridable Authority.Registration
    end
  end

  defmacro __before_compile__(env) do
    behaviours =
      [Authority.Authentication, Authority.Tokenization]
      |> Enum.filter(&Template.implements?(env.module, &1))

    inject_functions(behaviours)
  end

  # When Registration is used with Authentication and Tokenization, we should accept
  # tokens as the first argument to update_user/2 and delete_user/1.
  defp inject_functions([Authority.Authentication, Authority.Tokenization]) do
    quote do
      import Ecto.Query
      alias Ecto.Multi

      @token_schema @config[:token_schema] || raise(":token_schema is required")
      @token_user_assoc @config[:token_user_assoc] || :user
      @user_password_field @config[:user_password_field] || :encrypted_password
      @user_identity_field @config[:user_identity_field] || :email

      @type user_or_credential :: @user_schema.t() | @token_schema.t() | {String.t(), String.t()}
      @type auth_failure ::
              {:error, :invalid_email}
              | {:error, :invalid_password}
              | {:error, :invalid_token}
              | {:error, :invalid_token_for_purpose}

      unless Module.defines?(__MODULE__, {:update_user, 2}) do
        @doc """
        Updates a `#{inspect(@user_schema)}` with the given parameters. The first argument
        can be any kind of credential accepted by `authenticate/2`, including
        `#{inspect(@token_schema)}`.
        """
        @impl Authority.Registration
        @spec update_user(user_or_credential, map) ::
                {:ok, @user_schema.t()}
                | {:error, Ecto.Changeset.t()}
                | auth_failure
        def update_user(user_or_credential, params) do
          with {:ok, user} <- authenticate(user_or_credential, :recovery),
               {:ok, user_or_credential} <- before_identify(user_or_credential) do
            do_update_user(user_or_credential, user, params)
          end
        end

        defp do_update_user(user_or_credential, user, params) do
          changeset = @user_schema.changeset(user, params)

          # Remove all other tokens if the password changed, so that the user
          # will need to log in again.
          token_query =
            @config[:token_schema]
            |> where([t], field(t, ^:"#{@token_user_assoc}_id") == ^changeset.data.id)
            |> where([t], t.id != ^user_or_credential.id)
            |> or_where([t], t.purpose == ^:recovery)

          result =
            Multi.new()
            |> Multi.update(:user, changeset)
            |> Multi.delete_all(:tokens, token_query)
            |> @repo.transaction()

          case result do
            {:ok, %{user: user}} ->
              {:ok, user}

            {:error, _operation, reason, _changes} ->
              {:error, reason}
          end
        end
      end

      unless Module.defines?(__MODULE__, {:delete_user, 1}) do
        @doc """
        Deletes a `#{inspect(@user_schema)}`. Accepts any credential type supported by
        `authenticate/2`.
        """
        @impl Authority.Registration
        @spec delete_user(user_or_credential) ::
                {:ok, @user_schema.t}
                | {:error, Ecto.Changeset.t()}
                | auth_failure
        def delete_user(user_or_credential) do
          with {:ok, user} <- authenticate(user_or_credential) do
            @repo.delete(user)
          end
        end
      end

      unless Module.defines?(__MODULE__, {:change_user, 0}) do
        @doc """
        Returns a changeset for a given `#{inspect(@user_schema)}` or `#{inspect(@token_schema)}`.
        """
        @impl Authority.Registration
        @spec change_user :: {:ok, Ecto.Changeset.t()} | auth_failure
        @spec change_user(@user_schema.t() | @token_schema.t()) ::
                {:ok, Ecto.Changeset.t()} | auth_failure
        @spec change_user(@user_schema.t() | @token_schema.t(), map) ::
                {:ok, Ecto.Changeset.t()} | auth_failure
        def change_user(user_or_token \\ nil, params \\ %{})

        def change_user(nil, params) do
          {:ok, @user_schema.changeset(%@user_schema{}, params)}
        end

        def change_user(%@user_schema{} = user, params) do
          {:ok, @user_schema.changeset(user, params)}
        end

        def change_user(%@token_schema{} = token, params) do
          with {:ok, user} <- authenticate(token) do
            change_user(user, params)
          end
        end
      end

      defoverridable Authority.Registration
    end
  end

  # When Registration is not used with Authentication and Tokenization, we should
  # inject very simple functions that assume the first argument is a user.
  defp inject_functions(_) do
    quote do
      unless Module.defines?(__MODULE__, {:change_user, 0}) do
        @doc """
        Returns a changeset for `#{inspect(@user_schema)}.
        """
        @spec change_user :: {:ok, Ecto.Changeset.t()} | {:error, term}
        @spec change_user(@user_schema.t()) :: {:ok, Ecto.Changeset.t()} | {:error, term}
        @spec change_user(@user_schema.t(), map) :: {:ok, Ecto.Changeset.t()} | {:error, term}
        def change_user(user \\ nil, params \\ %{})

        def change_user(nil, params) do
          {:ok, @user_schema.changeset(%@user_schema{}, params)}
        end

        def change_user(%@user_schema{} = user, params) do
          {:ok, @user_schema.changeset(user, params)}
        end
      end

      unless Module.defines?(__MODULE__, {:update_user, 2}) do
        @doc """
        Updates a `#{@user_schema}` with params.
        """
        @impl Authority.Registration
        @spec update_user(@user_schema.t(), map) ::
                {:ok, @user_schema.t()} | {:error, Ecto.Changeset.t()}
        def update_user(user, params) do
          user
          |> @user_schema.changeset(params)
          |> @repo.update()
        end
      end

      unless Module.defines?(__MODULE__, {:delete_user, 1}) do
        @doc """
        Deletes a `#{@user_schema}`.
        """
        @impl Authority.Registration
        @spec delete_user(@user_schema.t()) ::
                {:ok, @user_schema.t()} | {:error, Ecto.Changeset.t()}
        def delete_user(user) do
          @repo.delete(user)
        end
      end

      defoverridable Authority.Registration
    end
  end
end