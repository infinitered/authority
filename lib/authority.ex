defmodule Authority do
  @moduledoc """
  Authority is a flexible, zero-dependencies authentication library for Elixir.
  It encourages you to use plain Elixir modules and behaviours instead of
  coupling your authentication logic to a framework.

  ### Layers
  Authority is built in layers.

  1. **Behaviours**: a set of minimal conventions for building authentication
     features, like tokenization or account locking.

     - `Authority.Authentication`
     - `Authority.Locking`
     - `Authority.Tokenization`

  2. **Templates**: implementations of the behaviours for common use cases.
     See `Authority.Template`.

  When using a template, you can override everything. If no template meets
  your needs, you can implement the behaviours yourself instead.
  """
end