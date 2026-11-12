# Authority
[![Hex.pm](https://img.shields.io/hexpm/v/authority.svg)](https://hex.pm/packages/authority)

Authority is an authentication specification for Elixir projects. It
encourages conforming projects to use plain Elixir modules for
authentication rather than frameworks.

See [the documentation](https://hexdocs.pm/authority) for details.

## Related Libraries

  * [`authority_ecto`](https://github.com/infinitered/authority_ecto) -
    Implements Authority behaviours for your app using
    [`Ecto`](https://github.com/elixir-ecto/ecto) for persistence.

## Installation

Add `authority` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:authority, "~> 0.3.0"}
  ]
end
```

## About

Originally developed by [Infinite Red](https://infinite.red), a U.S.-based web and mobile development company.
