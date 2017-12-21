# Authority
[![Build Status](https://travis-ci.org/infinitered/authority.svg?branch=master)](https://travis-ci.org/infinitered/authority)

Authority is a flexible authentication library for Elixir. It encourages you
to use plain Elixir modules and behaviours instead of coupling your
authentication logic to a framework.

While it provides easy integration with [Ecto](https://github.com/elixir-ecto/ecto),
nothing about Authority requires Ecto.

See [the documentation](https://hexdocs.pm/authority) for details.

## Installation

Add `authority` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:authority, "~> 0.1.0"}
  ]
end
```