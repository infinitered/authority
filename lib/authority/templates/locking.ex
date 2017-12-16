defmodule Authority.Template.Locking do
  @moduledoc false

  defmacro __using__(config) do
    quote location: :keep do
      @config unquote(config)
      @repo @config[:repo]

      # Locks
      @lock_schema @config[:lock_schema] || raise(":lock_schema is required")
      @lock_expiration_field @config[:lock_expiration_field] || :expires_at
      @lock_user_assoc @config[:lock_user_assoc] || :user
      @lock_reason_field @config[:lock_reason_field] || :reason

      # Attempts
      @lock_attempt_schema @config[:lock_attempt_schema] ||
                             raise(":lock_attempt_schema is required")
      @lock_max_attempts @config[:lock_max_attempts] || 5
      @lock_interval_seconds @config[:lock_interval_seconds] || 6_000
      @lock_duration_seconds @config[:lock_duration_seconds] || 6_000

      # LOCKING
      # —————————————————————————————————————————————————————————————————————————

      use Authority.Locking

      import Ecto.Query, except: [lock: 1, lock: 2]

      @impl Authority.Locking
      def get_lock(%{id: id}) do
        lock =
          @lock_schema
          |> where(^[{:"#{@lock_user_assoc}_id", id}])
          |> where([l], field(l, ^@lock_expiration_field) > ^DateTime.utc_now())
          |> first()
          |> @repo.one()

        if lock do
          {:ok, lock}
        else
          {:error, :unlocked}
        end
      end

      @impl Authority.Locking
      def lock(user, reason) do
        expires_at =
          DateTime.utc_now()
          |> DateTime.to_unix()
          |> Kernel.+(@lock_duration_seconds)
          |> DateTime.from_unix!()

        %@lock_schema{@lock_user_assoc => user}
        |> @lock_schema.changeset(%{
             @lock_reason_field => reason,
             @lock_expiration_field => expires_at
           })
        |> @repo.insert()
      end

      @impl Authority.Locking
      def unlock(%{id: id}) do
        @lock_schema
        |> where(^[{:"#{@lock_user_assoc}_id", id}])
        |> @repo.delete_all()

        :ok
      end

      defoverridable Authority.Locking

      # AUTHENTICATION
      # —————————————————————————————————————————————————————————————————————————

      @impl Authority.Authentication
      def before_validate(user, _purpose) do
        case get_lock(user) do
          {:ok, lock} -> {:error, lock}
          _other -> :ok
        end
      end

      @impl Authority.Authentication
      def after_validate(user, _purpose) do
        unlock(user)
      end

      @impl Authority.Authentication
      def failed(user, _error) do
        create_attempt(user)

        if failed_attempt_count(user) >= @lock_max_attempts do
          lock(user, :too_many_attempts)
        else
          :ok
        end
      end

      defp create_attempt(user) do
        %@lock_attempt_schema{@lock_user_assoc => user}
        |> @lock_attempt_schema.changeset()
        |> @repo.insert()
      end

      defp failed_attempt_count(%{id: id}) do
        now = DateTime.utc_now()

        @lock_attempt_schema
        |> where(^[{:"#{@lock_user_assoc}_id", id}])
        |> where([l], l.inserted_at > datetime_add(^now, ^(-@lock_interval_seconds), "second"))
        |> @repo.aggregate(:count, :id)
      end
    end
  end
end