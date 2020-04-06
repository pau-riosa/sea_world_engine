defmodule SeaWorldEngine.GameTest do
  use ExUnit.Case

  alias SeaWorldEngine.{Creature, Game, GameSupervisor, Guesses, Rules}

  test "start game" do
    {:ok, game} = GameSupervisor.start_game("Franky")
    state_data = :sys.get_state(game)

    assert %{penguin: penguin, whale: whale, rules: %Rules{}, world: []} = state_data
    assert %{name: nil, guesses: %Guesses{}} = penguin
    assert %{name: nil, guesses: %Guesses{}} = whale
    GameSupervisor.stop_game("Franky")
  end

  describe "simmulate" do
    test "die whale: if 3 turns does not eat penguin" do
      {:ok, game} = GameSupervisor.start_game("Gabby3")
      assert :ok = Game.add_player_penguin(game, "Louis3")
      assert :ok = Game.add_player_whale(game, "Gabby1")
      # position creature
      assert :ok = Game.position_creature(game, :penguin, :penguin, 1, 1)
      assert :ok = Game.position_creature(game, :penguin, :penguin, 1, 2)
      # set creatures' position
      assert {:ok, _} = Game.set_creatures(game, :penguin)
      assert {:ok, _} = Game.set_creatures(game, :whale)
      state_data = :sys.get_state(game)
      # change counter
      new_rules = Map.replace!(state_data.rules, :whale_counter, 2)
      state_data = %{state_data | rules: new_rules}
      :sys.replace_state(game, fn state -> state_data end)
      # change state
      new_rules = Map.replace!(state_data.rules, :state, :whale_turn)
      state_data = %{state_data | rules: new_rules}
      :sys.replace_state(game, fn state -> state_data end)
      # whale turn: hits
      assert :whale_turn = state_data.rules.state
      assert {:hit, :eat_penguin, :no_win} = Game.guess_coordinate(game, :whale, 1, 1)
      # because elixir is too fast, 
      # i need to sleep the process so that when the server checks if whale is
      # ready to die, it will terminate the game
      Process.sleep(1000)
    end
  end

  test "simulate whale reproduce" do
    {:ok, game} = GameSupervisor.start_game("Gabby2")
    assert :ok = Game.add_player_penguin(game, "Louis3")
    assert :ok = Game.add_player_whale(game, "Gabby1")
    # position creature
    assert :ok = Game.position_creature(game, :penguin, :penguin, 1, 1)
    assert :ok = Game.position_creature(game, :penguin, :penguin, 1, 2)
    # set creatures' position
    assert {:ok, _} = Game.set_creatures(game, :penguin)
    assert {:ok, _} = Game.set_creatures(game, :whale)
    state_data = :sys.get_state(game)
    # change counter
    new_rules = Map.replace!(state_data.rules, :whale_counter, 7)
    state_data = %{state_data | rules: new_rules}
    :sys.replace_state(game, fn state -> state_data end)
    # change state
    new_rules = Map.replace!(state_data.rules, :state, :whale_turn)
    state_data = %{state_data | rules: new_rules}
    :sys.replace_state(game, fn state -> state_data end)
    # whale turn: hits
    assert :whale_turn = state_data.rules.state
    assert {:hit, :eat_penguin, :no_win} = Game.guess_coordinate(game, :whale, 1, 1)
    GameSupervisor.stop_game("Gabby2")
  end

  test "simulate penguin reproduce" do
    {:ok, game} = GameSupervisor.start_game("Gabby1")
    assert :ok = Game.add_player_penguin(game, "Louis3")
    assert :ok = Game.add_player_whale(game, "Gabby1")
    # position creature
    assert :ok = Game.position_creature(game, :penguin, :penguin, 1, 1)
    assert :ok = Game.position_creature(game, :penguin, :penguin, 1, 2)
    # set creatures' position
    assert {:ok, _} = Game.set_creatures(game, :penguin)
    assert {:ok, _} = Game.set_creatures(game, :whale)
    state_data = :sys.get_state(game)
    new_rules = Map.replace!(state_data.rules, :penguin_counter, 2)
    state_data = %{state_data | rules: new_rules}
    :sys.replace_state(game, fn state -> state_data end)
    # penguins turn: misses
    assert :penguin_turn = state_data.rules.state
    assert {:occupied_by_penguin, :none, :no_win} = Game.guess_coordinate(game, :penguin, 1, 1)
    state_data = :sys.get_state(game)
    %{world: world} = state_data
    GameSupervisor.stop_game("Gabby1")
  end

  describe "penguin guesses coordindate of type:" do
    test "eat_penguin && whale" do
      {:ok, game} = GameSupervisor.start_game("Miles2")
      assert :error = Game.guess_coordinate(game, :penguin, 1, 1)
      assert :ok = Game.add_player_penguin(game, "Louis3")
      assert :ok = Game.add_player_whale(game, "Gabby1")
      # position creature
      assert :ok = Game.position_creature(game, :penguin, :penguin, 1, 1)
      assert :ok = Game.position_creature(game, :penguin, :penguin, 1, 2)
      assert :ok = Game.position_creature(game, :whale, :whale, 1, 3)
      # set creatures' position
      assert {:ok, _} = Game.set_creatures(game, :penguin)
      assert {:ok, _} = Game.set_creatures(game, :whale)
      # penguins turn: misses
      state = :sys.get_state(game)
      assert :penguin_turn = state.rules.state
      assert {:occupied_by_penguin, :none, :no_win} = Game.guess_coordinate(game, :penguin, 1, 1)
      state = :sys.get_state(game)
      assert :whale_turn = state.rules.state
      assert {:hit, :eat_penguin, :no_win} = Game.guess_coordinate(game, :whale, 1, 1)

      # penguin turn: field is a type eat_penguin
      state = :sys.get_state(game)
      assert :penguin_turn = state.rules.state
      assert {:eat_penguin, :none, :no_win} = Game.guess_coordinate(game, :penguin, 1, 1)

      state = :sys.get_state(game)
      assert :whale_turn = state.rules.state
      assert {:eat_penguin, :none, :no_win} = Game.guess_coordinate(game, :whale, 1, 1)

      # penguin turn: field is a type whale
      state = :sys.get_state(game)
      assert :penguin_turn = state.rules.state
      assert {:occupied_by_whale, :none, :no_win} = Game.guess_coordinate(game, :penguin, 1, 3)
      GameSupervisor.stop_game("Miles2")
    end

    test "penguin" do
      {:ok, game} = GameSupervisor.start_game("Miles1")
      assert :error = Game.guess_coordinate(game, :penguin, 1, 1)
      assert :ok = Game.add_player_penguin(game, "Louis3")
      assert :ok = Game.add_player_whale(game, "Gabby1")
      # position creature
      assert :ok = Game.position_creature(game, :penguin, :penguin, 1, 1)
      assert :ok = Game.position_creature(game, :whale, :whale, 1, 2)
      # set creatures' position
      assert {:ok, _} = Game.set_creatures(game, :penguin)
      assert {:ok, _} = Game.set_creatures(game, :whale)
      # penguins turn: misses
      state = :sys.get_state(game)
      assert :penguin_turn = state.rules.state
      assert {:occupied_by_penguin, :none, :no_win} = Game.guess_coordinate(game, :penguin, 1, 1)
      GameSupervisor.stop_game("Miles1")
    end
  end

  test "guess coordinates" do
    {:ok, game} = GameSupervisor.start_game("Miles")
    assert :error = Game.guess_coordinate(game, :penguin, 1, 1)
    assert :ok = Game.add_player_penguin(game, "Louis3")
    assert :ok = Game.add_player_whale(game, "Gabby1")
    # position creature
    assert :ok = Game.position_creature(game, :penguin, :penguin, 1, 1)
    assert :ok = Game.position_creature(game, :whale, :penguin, 1, 2)
    # set creatures' position
    assert {:ok, _} = Game.set_creatures(game, :penguin)
    assert {:ok, _} = Game.set_creatures(game, :whale)
    # penguins turn: misses
    state = :sys.get_state(game)
    assert :penguin_turn = state.rules.state
    assert {:miss, :none, :no_win} = Game.guess_coordinate(game, :penguin, 5, 5)
    # whales turn: hits a coordinate with creature type penguin: eat_penguin
    state = :sys.get_state(game)
    assert :whale_turn = state.rules.state
    assert {:hit, :eat_penguin, :no_win} = Game.guess_coordinate(game, :whale, 1, 1)
    # penguins turn: hits a whale will miss
    state = :sys.get_state(game)
    assert :penguin_turn = state.rules.state
    assert {:miss, :none, :no_win} = Game.guess_coordinate(game, :penguin, 1, 4)
    # whales turn: hits a coordinate with creature type penguin: eat_penguin
    state = :sys.get_state(game)
    assert :whale_turn = state.rules.state
    assert {:hit, :eat_penguin, :win} = Game.guess_coordinate(game, :whale, 1, 2)
    # game over
    state = :sys.get_state(game)
    assert :game_over = state.rules.state
    GameSupervisor.stop_game("Miles")
  end

  test "initialize player, position and set creatures" do
    # initialize game and penguin player
    {:ok, game} = Game.start_link("Fred1")
    # add whale player
    assert :ok = Game.add_player_penguin(game, "Louis3")
    assert :ok = Game.add_player_whale(game, "Gabby1")
    assert {:error, :not_all_creatures_positioned} = Game.set_creatures(game, :penguin)
    # position creatures
    assert :ok = Game.position_creature(game, :penguin, :penguin, 5, 1)

    assert {:error, :overlapping_creature} =
             Game.position_creature(game, :penguin, :penguin, 5, 1)

    assert {:error, :overlapping_creature} = Game.position_creature(game, :penguin, :whale, 5, 1)

    # whale positioned correctly
    assert :ok = Game.position_creature(game, :penguin, :penguin, 5, 2)
    assert :ok = Game.position_creature(game, :penguin, :penguin, 5, 3)
    assert :ok = Game.position_creature(game, :penguin, :whale, 5, 4)
    assert {:ok, creatures_set} = Game.set_creatures(game, :penguin)
    # all creatures set
    state = :sys.get_state(game)
    assert :creatures_set = state.rules.penguin
    assert :players_set = state.rules.state

    assert {:error, :overlapping_creature} = Game.position_creature(game, :whale, :whale, 5, 2)
    assert :ok = Game.position_creature(game, :whale, :whale, 6, 2)
    assert :ok = Game.position_creature(game, :whale, :whale, 6, 3)
    assert :ok = Game.position_creature(game, :whale, :whale, 6, 4)
    assert {:ok, creatures_set} = Game.set_creatures(game, :whale)
    # all creatures set
    state = :sys.get_state(game)
    assert :creatures_set = state.rules.penguin
    assert :penguin_turn = state.rules.state
    GameSupervisor.stop_game("Fred1")
  end

  test "get an error if penguin hasn't positioned all her creatures" do
    # initialize game and penguin player
    assert {:ok, game} = GameSupervisor.start_game("Freddy")
    # add penguin whale player
    assert :ok = Game.add_player_penguin(game, "Louis3")
    assert :ok = Game.add_player_whale(game, "Gabby1")
    # get an error because penguin player hasn't positioned all her creatures
    assert {:error, :not_all_creatures_positioned} = Game.set_creatures(game, :penguin)
    GameSupervisor.stop_game("Freddy")
  end

  test "position creatures" do
    # initialize game and penguin player
    assert {:ok, game} = GameSupervisor.start_game("Fred")
    # add whale player
    assert :ok = Game.add_player_penguin(game, "Louis3")
    assert :ok = Game.add_player_whale(game, "Gabby1")
    state_data = :sys.get_state(game)
    # players_set
    assert :players_set = state_data.rules.state

    # position_creature
    assert :ok = Game.position_creature(game, :penguin, :penguin, 1, 1)
    state_data = :sys.get_state(game)
    assert [%Creature{type: :penguin} = penguin_creature] = state_data.world
    # invalid coordinate
    assert {:error, :invalid_coordinate} = Game.position_creature(game, :penguin, :penguin, 16, 1)
    # invalid creature_type
    assert {:error, :invalid_creature} = Game.position_creature(game, :penguin, :wrong, 5, 3)

    # if penguin_turn is set
    # other commands will not be permissible
    state_data =
      :sys.replace_state(game, fn state_data ->
        %{state_data | rules: %Rules{state: :penguin_turn}}
      end)

    assert :penguin_turn = state_data.rules.state
    assert :error = Game.position_creature(game, :penguin, :penguin, 5, 5)
    GameSupervisor.stop_game("Fred")
  end

  test "add_player" do
    {:ok, game} = GameSupervisor.start_game("Frank")
    assert :ok = Game.add_player_penguin(game, "Louis3")
    assert :ok = Game.add_player_whale(game, "Gabby1")
    state_data = :sys.get_state(game)

    assert state_data.whale.name == "Gabby1"
    GameSupervisor.stop_game("Frank")
  end
end
