defmodule SeaWorldEngine.WorldTest do
  use ExUnit.Case
  alias SeaWorldEngine.{Coordinate, Creature, World}

  setup do
    world = World.new()
    {:ok, world: world}
  end

  # test "whale player: new game flow", %{world: world} do
  #   # penguin position to unforested field
  #   assert {:ok, penguin_coordinate_1} = Coordinate.new(1, 1)
  #   assert {:ok, penguin_1} = Creature.new(:penguin, penguin_coordinate_1)
  #   world = World.position_creature(world, penguin_1)

  #   assert {:ok, penguin_coordinate_2} = Coordinate.new(1, 2)
  #   assert {:ok, penguin_2} = Creature.new(:penguin, penguin_coordinate_2)
  #   assert [%Creature{type: :penguin} = penguin] = World.position_creature(world, penguin_2)

  #   assert {:ok, penguin_coordinate_3} = Coordinate.new(1, 3)
  #   assert {:ok, penguin_3} = Creature.new(:penguin, penguin_coordinate_3)
  #   world = World.position_creature(world, penguin_3)

  #   # whale guess a coordinates inside the world return miss
  #   {:ok, guess_coordinate_1} = Coordinate.new(10, 10)
  #   assert {:free, :none, :no_win, world} = World.guess(world, :whale, guess_coordinate_1)

  #   # whale guess a coordinate with creature type penguin
  #   # returns a hit and eats it.
  #   {:ok, hit_coordinate_1} = Coordinate.new(1, 1)
  #   assert {:hit, :eat_penguin, :no_win, world} = World.guess(world, :whale, hit_coordinate_1)
  #   {:ok, hit_coordinate_2} = Coordinate.new(1, 2)
  #   assert {:hit, :eat_penguin, :no_win, world} = World.guess(world, :whale, hit_coordinate_2)
  # end

  test "whale tries to win the game", %{world: world} do
    # create a penguin
    assert {:ok, penguin_coordinate} = Coordinate.new(1, 1)
    assert {:ok, penguin} = Creature.new(:penguin, penguin_coordinate)
    assert [%Creature{type: :penguin} = penguin] = World.position_creature(world, penguin)
    world = [%{penguin | hit_coordinates: penguin.coordinates}]
    assert {:ok, win_coordinate} = Coordinate.new(1, 1)
    # whale win because all penguins are eaten
    assert {:hit, :eat_penguin, :win, world} = World.guess(world, :whale, win_coordinate)
  end
end
