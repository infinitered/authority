defmodule Authority do
  @moduledoc """
  Authority is an authentication specification for Elixir projects. It
  encourages conforming projects to use plain Elixir modules for
  authentication rather than frameworks.

  Authority itself is _only a spec_. It ensures that conforming libraries and
  apps use consistent function names and APIs for authentication, but leaves
  all implementation details up to each project. This provides a balance of
  **consistency** and **flexibility**.

  ## Behaviours

  Your application or library can adhere to Authority's spec by defining
  modules which implement any (or all) of Authority's behaviours.

  * `Authority.Authentication`
  * `Authority.Locking`
  * `Authority.Recovery`
  * `Authority.Registration`
  * `Authority.Tokenization`

  ## Conforming Libraries

  * [`authority_ecto`](https://hex.pm/authority_ecto) - Implements
    Authority behaviours for your app using `Ecto` for persistence.
  """
end