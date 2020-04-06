defmodule SeaWorldEngine.World do
  @moduledoc """
  Sea world world
  """
  alias SeaWorldEngine.{Coordinate, Creature}
  def new, do: []

  @doc """
  position a creature in the world
  if creature overlaps return an error 
  else update the world
  """
  def position_creature(world, %Creature{} = creature) do
    case overlaps_existing_creature?(world, creature) do
      true -> {:error, :overlapping_creature}
      false -> world ++ [creature]
    end
  end

  @doc """
  guesses the coordinate inside the world 
  if penguin finds an empty cell nearby, penguin has to move there
  if penguin cannot find empty cell, penguin skips turn
  whale checks all directions, if penguin is found, it moves to its place and eats it
  if there are no penguins nearby, then it moves in the same way as a penguin

  """
  def guess(world, key, %Coordinate{} = coordinate) do
    world
    |> check_all_creatures(key, coordinate)
    |> guess_response(world)
  end

  defp check_all_creatures(world, :whale, coordinate) do
    Enum.find_value(world, :miss, fn creature ->
      case Creature.guess(creature, coordinate) do
        {:hit, %{type: :penguin} = creature} -> %{creature | type: :eat_penguin}
        {:hit, %{type: :whale} = _creature} -> :occupied_by_whale
        {:hit, %{type: :eat_penguin} = _creature} -> :eat_penguin
        :miss -> false
      end
    end)
  end

  defp check_all_creatures(world, :penguin, coordinate) do
    Enum.find_value(world, :miss, fn creature ->
      case Creature.guess(creature, coordinate) do
        {:hit, %{type: :eat_penguin} = _creature} -> :eat_penguin
        {:hit, %{type: :penguin} = _creature} -> :occupied_by_penguin
        {:hit, %{type: :whale} = _creature} -> :occupied_by_whale
        :miss -> false
      end
    end)
  end

  defp guess_response(%Creature{} = new_creature, world) do
    new_world = update_world(world, new_creature)
    {:hit, forest_check(new_creature), win_check(new_world), new_world}
  end

  defp guess_response(:occupied_by_penguin, world),
    do: {:occupied_by_penguin, :none, :no_win, world}

  defp guess_response(:occupied_by_whale, world), do: {:occupied_by_whale, :none, :no_win, world}
  defp guess_response(:eat_penguin, world), do: {:eat_penguin, :none, :no_win, world}
  defp guess_response(_miss, world), do: {:miss, :none, :no_win, world}

  defp forest_check(creature) do
    case forested?(creature) do
      true -> creature.type
      false -> :none
    end
  end

  defp forested?(creature) do
    Creature.forested?(creature)
  end

  defp win_check(world) do
    case all_forested?(world) do
      true -> :win
      false -> :no_win
    end
  end

  defp all_forested?(world) do
    Enum.all?(world, fn creature ->
      creature.type in [:eat_penguin, :whale]
    end)
  end

  @doc """
  checks to see if all creatures are positioned
  """
  def all_creatures_positioned?([]), do: false
  def all_creatures_positioned?(_), do: true

  # no overlapping creature
  defp overlaps_existing_creature?(world, new_creature) do
    Enum.any?(world, fn creature ->
      (creature.type != new_creature.type and Creature.overlaps?(creature, new_creature)) or
        (creature.type == new_creature.type and Creature.overlaps?(creature, new_creature))
    end)
  end

  # update world
  defp update_world(world, new_creature) do
    Enum.map(world, fn creature ->
      if creature.coordinates == new_creature.coordinates do
        new_creature
      else
        creature
      end
    end)
  end
end
