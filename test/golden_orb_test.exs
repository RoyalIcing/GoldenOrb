defmodule GoldenOrbTest do
  use ExUnit.Case
  doctest GoldenOrb

  test "greets the world" do
    assert GoldenOrb.hello() == :world
  end
end
