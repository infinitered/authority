defmodule Authority.Factory do
  @moduledoc false

  alias Authority.Test.Repo

  # "password"
  @password_hash "$2b$12$F9Os3dSOZF0cejZZie9CVuoyNVlBy6b12VA2sD0nDDFUoNSO/sjqK"

  @doc """
  Build a factory struct, with zero side effects.

  Define your factories with build functions, like so:

      def build(:user) do
        %Authority.Accounts.User{
          attrs here ...
        }
      end

  Here's how you build records which have associations:

      def build(:user_with_assoc_name) do
        build(:user, assoc_name: build(:assoc_name))
      end

  ## Example

      Factory.build(:user)
      # => %Authority.Accounts.User{...}
  """
  def build(:user) do
    %Authority.Test.User{
      email: "test@email.com",
      encrypted_password: @password_hash
    }
  end

  @doc """
  Build a factory struct with custom attributes.

  ## Example

  Suppose you had a `build/1` factory for users:

      def build(:user) do
        %Authority.Accounts.User{name: "John Smith"}
      end

  You could call `build/2` to customize the name:

      Factory.build(:user, name: "Custom Name")
      # => %Authority.Accounts.User{name: "Custom Name"}
  """
  def build(factory_name, attributes) do
    factory_name
    |> build()
    |> struct(attributes)
  end

  @doc """
  Builds and inserts a factory.

  ## Example

  Suppose you had a `build/1` factory for users:

      def build(:user) do
        %Authority.Accounts.User{name: "John Smith"}
      end

  You can customize and insert the factory in one call to `insert!/2`:

      Factory.insert!(:user, name: "Custom Name")
      # => Authority.Accounts.User{name: "Custom Name"}
  """
  def insert!(factory_name, attributes \\ []) do
    factory_name
    |> build(attributes)
    |> Repo.insert!()
  end
end