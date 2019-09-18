defmodule SnakeExTest do
  use ExUnit.Case
  doctest SnakeEx

  test "greets the world" do
    assert SnakeEx.hello() == :world
  end
end
