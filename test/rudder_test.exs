defmodule RudderTest do
  use ExUnit.Case
  doctest Rudder

  test "greets the world" do
    assert Rudder.hello() == :world
  end
end
