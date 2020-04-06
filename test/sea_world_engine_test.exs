defmodule SeaWorldEngineTest do
  use ExUnit.Case
  doctest SeaWorldEngine

  test "greets the world" do
    assert SeaWorldEngine.hello() == :world
  end
end
