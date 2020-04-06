defmodule SeaWorldEngine.GameSupervisorTest do
  use ExUnit.Case

  alias SeaWorldEngine.{Game, GameSupervisor}

  test "start and stop supervisor" do
    assert {:ok, game} = GameSupervisor.start_game("Cassatt")
    assert {:via, Registry, {Registry.Game, "Cassatt"}} = via = Game.via_tuple("Cassatt")

    assert %{active: 1, specs: 1, supervisors: 0, workers: 1} =
             Supervisor.count_children(GameSupervisor)

    assert [{:undefined, game, :worker, [SeaWorldEngine.Game]}] =
             Supervisor.which_children(GameSupervisor)

    assert :ok = GameSupervisor.stop_game("Cassatt")
    refute Process.alive?(game)
    assert nil == GenServer.whereis(via)
  end

  test "state will be stored within ets" do
    {:ok, game} = GameSupervisor.start_game("Cassatt1")
    [{"Cassatt1", value}] = :ets.lookup(:game_state, "Cassatt1")
    assert nil == value.penguin.name
    assert nil == value.whale.name
    assert :ok = Game.add_player_penguin(game, "Rothko")
    assert :ok = Game.add_player_whale(game, "Cassatt1")
    [{"Cassatt1", value}] = :ets.lookup(:game_state, "Cassatt1")
    assert "Rothko" = value.penguin.name
    assert "Cassatt1" == value.whale.name
    assert :ok = GameSupervisor.stop_game("Cassatt1")
  end
end
