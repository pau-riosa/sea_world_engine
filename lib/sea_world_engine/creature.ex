defmodule SeaWorldEngine.Creature do
  @moduledoc """
  generates the following creatures:

  penguin -> will be guess by player who has the orca character
  whale   -> will be plotted inside the world
  """

  alias SeaWorldEngine.{Coordinate, Creature}

  @enforce_keys [:type, :coordinates, :hit_coordinates]
  defstruct [:type, :coordinates, :hit_coordinates]

  @doc """
  returns the list of valid island types
  """
  def types, do: [:penguin, :whale]

  @doc """
  generates new creatures
  """
  def new(type, %Coordinate{} = coordinate) do
    with [_ | _] = offsets <- offsets(type),
         %MapSet{} = coordinates <- add_coordinates(offsets, coordinate) do
      {:ok, %Creature{type: type, coordinates: coordinates, hit_coordinates: MapSet.new()}}
    else
      error -> error
    end
  end

  @doc """
  checks if a creatures exists 
  """

  def forested?(creature),
    do: MapSet.equal?(creature.coordinates, creature.hit_coordinates)

  @doc """
  guess the coordinates of a creature 
  """
  def guess(creature, coordinate) do
    case MapSet.member?(creature.coordinates, coordinate) do
      true ->
        hit_coordinates = MapSet.put(creature.hit_coordinates, coordinate)
        {:hit, %{creature | hit_coordinates: hit_coordinates}}

      false ->
        :miss
    end
  end

  @doc """
  check if creatures overlaps 
  """
  def overlaps?(existing_creature, new_creature),
    do: not MapSet.disjoint?(existing_creature.coordinates, new_creature.coordinates)

  defp add_coordinates(offsets, upper_left) do
    Enum.reduce_while(offsets, MapSet.new(), fn offset, acc ->
      add_coordinate(acc, upper_left, offset)
    end)
  end

  defp add_coordinate(coordinates, %Coordinate{row: row, col: col}, {row_offset, col_offset}) do
    case Coordinate.new(row + row_offset, col + col_offset) do
      {:ok, coordinate} ->
        {:cont, MapSet.put(coordinates, coordinate)}

      {:error, :invalid_coordinate} ->
        {:halt, {:error, :invalid_coordinate}}
    end
  end

  defp offsets(offset) when offset in [:penguin, :whale], do: [{0, 0}]
  defp offsets(_), do: {:error, :invalid_creature}
end
