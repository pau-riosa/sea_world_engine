defmodule SeaWorldEngine.GuessesTest do
  use ExUnit.Case
  alias SeaWorldEngine.{Coordinate, Guesses}

  describe "guesses: " do
    test "coordinate if its a penguin" do
      guesses = Guesses.new()

      {:ok, coordinate1} = Coordinate.new(1, 1)
      {:ok, coordinate2} = Coordinate.new(2, 2)

      %Guesses{} = guesses = update_in(guesses.hits, &MapSet.put(&1, coordinate1))
      %Guesses{} = update_in(guesses.hits, &MapSet.put(&1, coordinate2))
    end

    test "add guesses with penguin and misses" do
      guesses = Guesses.new()
      # hits
      assert {:ok, coordinate1} = Coordinate.new(8, 3)

      assert %Guesses{hits: hits, misses: misses} =
               guesses = Guesses.add(guesses, :hit, coordinate1)

      assert %Guesses{} = guesses
      assert %MapSet{} = hits
      assert %MapSet{} = misses

      # hits
      assert {:ok, coordinate2} = Coordinate.new(9, 7)

      assert %Guesses{hits: hits, misses: misses} =
               guesses = Guesses.add(guesses, :hit, coordinate1)

      assert %Guesses{} = guesses
      assert %MapSet{} = hits
      assert %MapSet{} = misses

      # miss
      assert {:ok, coordinate3} = Coordinate.new(1, 2)

      assert %Guesses{hits: hits, misses: misses} =
               guesses = Guesses.add(guesses, :miss, coordinate3)

      assert %Guesses{} = guesses
      assert %MapSet{} = hits
      assert %MapSet{} = misses
    end
  end
end
