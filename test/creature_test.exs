defmodule SeaWorldEngine.CreatureTest do
  use ExUnit.Case
  alias SeaWorldEngine.{Coordinate, Creature}

  describe "forested/2:" do
    test "creature hits and miss a penguin/whale" do
      assert {:ok, penguin_coordinates} = Coordinate.new(4, 4)
      assert {:ok, penguin} = Creature.new(:penguin, penguin_coordinates)
      assert {:hit, penguin} = Creature.guess(penguin, %Coordinate{row: 4, col: 4})
      assert :miss = Creature.guess(penguin, %Coordinate{row: 6, col: 6})
      assert Creature.forested?(penguin)

      assert {:ok, whale_coordinates} = Coordinate.new(5, 5)
      assert {:ok, whale} = Creature.new(:whale, whale_coordinates)
      assert {:hit, whale} = Creature.guess(whale, %Coordinate{row: 5, col: 5})
      assert :miss = Creature.guess(whale, %Coordinate{row: 6, col: 6})
      assert Creature.forested?(whale)
    end
  end

  describe "guess/2:" do
    test "coordinates hits or miss penguin" do
      assert {:ok, penguin_coordinates} = Coordinate.new(6, 5)
      assert {:ok, penguin} = Creature.new(:penguin, penguin_coordinates)
      assert {:hit, penguin} = Creature.guess(penguin, %Coordinate{row: 6, col: 5})
      assert :miss = Creature.guess(penguin, %Coordinate{row: 6, col: 6})
    end
  end

  describe "overlaps/2:" do
    test "whale overlaps penguin" do
      assert {:ok, penguin_coordinates} = Coordinate.new(6, 5)
      assert {:ok, penguin} = Creature.new(:penguin, penguin_coordinates)
      assert {:ok, whale_coordinates} = Coordinate.new(6, 5)
      assert {:ok, whale} = Creature.new(:whale, whale_coordinates)
      assert Creature.overlaps?(penguin, whale)
    end
  end

  describe "generate a " do
    test "penguin creature" do
      assert {:ok, %Coordinate{} = coordinate} = Coordinate.new(4, 6)
      assert {:ok, %Creature{} = creature} = Creature.new(:penguin, coordinate)
      assert %MapSet{} = creature.coordinates
      assert %MapSet{} = creature.hit_coordinates
    end

    test "whale creature" do
      assert {:ok, %Coordinate{} = coordinate} = Coordinate.new(4, 6)
      assert {:ok, %Creature{} = creature} = Creature.new(:whale, coordinate)
      assert %MapSet{} = creature.coordinates
      assert %MapSet{} = creature.hit_coordinates
    end

    test "wrong creature with valid coordinate" do
      assert {:ok, %Coordinate{} = coordinate} = Coordinate.new(4, 6)
      assert {:error, :invalid_creature} = Creature.new(:wrong, coordinate)
    end
  end
end
