defmodule SeaWorldEngine.CoodinateTest do
  use ExUnit.Case
  alias SeaWorldEngine.Coordinate

  describe "coordinate: " do
    test "generate new coordinate" do
      assert {:ok, %Coordinate{row: 1, col: 1}} == Coordinate.new(1, 1)
      assert {:ok, %Coordinate{row: 10, col: 15}} == Coordinate.new(10, 15)
    end

    test "generate invalid coordinate" do
      assert {:error, :invalid_coordinate} == Coordinate.new(-1, 1)
      assert {:error, :invalid_coordinate} == Coordinate.new(-2, 1)
      assert {:error, :invalid_coordinate} == Coordinate.new(2, -1)
      assert {:error, :invalid_coordinate} == Coordinate.new(16, 10)
      assert {:error, :invalid_coordinate} == Coordinate.new(10, 16)
    end
  end
end
