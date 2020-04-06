defmodule SeaWorldEngine.Coordinate do
  @moduledoc """
  generates the coordinates of the sea world
  """
  alias __MODULE__

  @enforce_keys [:row, :col]
  defstruct [:row, :col]

  @directions [:right, :left, :down, :up, :up_left, :up_right, :down_left, :down_right]
  # board size
  @row 10
  @col 15

  def new(row, col) when row in 1..@row and col in 1..@col,
    do: {:ok, %Coordinate{row: row, col: col}}

  def new(_row, _col), do: {:error, :invalid_coordinate}

  def check_coordinate_neighbor(%Coordinate{row: row, col: col} = coordinate) do
    with direction <- Enum.take_random(@directions, 1) |> List.first(),
         coordinate <- generate_coordinate(direction, coordinate) do
      coordinate
    end
  end

  defp generate_coordinate(:left, %Coordinate{row: row, col: col}), do: new(row - 1, col)
  defp generate_coordinate(:right, %Coordinate{row: row, col: col}), do: new(row + 1, col)
  defp generate_coordinate(:up, %Coordinate{row: row, col: col}), do: new(row, col - 1)
  defp generate_coordinate(:down, %Coordinate{row: row, col: col}), do: new(row, col + 1)
  defp generate_coordinate(:up_left, %Coordinate{row: row, col: col}), do: new(row - 1, col - 1)
  defp generate_coordinate(:down_left, %Coordinate{row: row, col: col}), do: new(row - 1, col + 1)

  defp generate_coordinate(:down_right, %Coordinate{row: row, col: col}),
    do: new(row + 1, col + 1)

  defp generate_coordinate(:up_right, %Coordinate{row: row, col: col}),
    do: new(row + 1, col - 1)
end
