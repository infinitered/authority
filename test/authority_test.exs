defmodule AuthorityTest do
  use ExUnit.Case
  doctest Authority

  test "greets the world" do
    assert Authority.hello() == :world
  end
end
