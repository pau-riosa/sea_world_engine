defmodule SeaWorldEngine.Guesses do
  @moduledoc """
  guesses the field if penguin 
  """
  alias SeaWorldEngine.{Coordinate, Guesses}
  @enforce_keys [:hits, :misses]
  defstruct [:hits, :misses]

  def new, do: %Guesses{hits: MapSet.new(), misses: MapSet.new()}

  # hits
  def add(%Guesses{} = guesses, :hit, %Coordinate{} = coordinate),
    do: update_in(guesses.hits, &MapSet.put(&1, coordinate))

  # misses
  def add(%Guesses{} = guesses, :miss, %Coordinate{} = coordinate),
    do: update_in(guesses.misses, &MapSet.put(&1, coordinate))

  def add(%Guesses{} = guesses, :eat_penguin, %Coordinate{} = coordinate),
    do: update_in(guesses.misses, &MapSet.put(&1, coordinate))

  def add(%Guesses{} = guesses, :occupied_by_penguin, %Coordinate{} = coordinate),
    do: update_in(guesses.misses, &MapSet.put(&1, coordinate))

  def add(%Guesses{} = guesses, :occupied_by_whale, %Coordinate{} = coordinate),
    do: update_in(guesses.misses, &MapSet.put(&1, coordinate))
end
