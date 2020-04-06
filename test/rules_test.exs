defmodule SeaWorldEngine.RulesTest do
  use ExUnit.Case

  alias SeaWorldEngine.Rules

  test "game over flow" do
    rules = Rules.new()

    # initialize game
    assert :initialized == rules.state

    # add players
    assert {:ok, rules} = Rules.check(rules, :add_player)
    assert :waiting_for_player == rules.state
    assert {:ok, rules} = Rules.check(rules, :add_player)
    assert :players_set == rules.state

    # position creatures for penguin
    assert {:ok, rules} = Rules.check(rules, {:position_creatures, :penguin})
    assert :players_set = rules.state

    # set creatures for penguin
    assert {:ok, rules} = Rules.check(rules, {:set_creatures, :penguin})
    assert :players_set = rules.state
    # after set creatures no more action can be done
    assert :error = Rules.check(rules, {:position_creatures, :penguin})

    # position creatures for whale
    assert {:ok, rules} = Rules.check(rules, {:position_creatures, :whale})
    assert :players_set = rules.state

    # set creatures for penguin
    assert {:ok, rules} = Rules.check(rules, {:set_creatures, :whale})
    # after set creatures no more action can be done
    assert :error = Rules.check(rules, {:position_creatures, :whale})

    # state is now penguin_turn
    assert :penguin_turn = rules.state

    # whale tries to guess coordinate and should return an error
    assert :error = Rules.check(rules, {:guess_coordinate, :whale})
    assert :penguin_turn = rules.state

    # penguin turn
    assert {:ok, rules} = Rules.check(rules, {:guess_coordinate, :penguin})
    assert :whale_turn = rules.state

    # whale turn
    assert {:ok, rules} = Rules.check(rules, {:guess_coordinate, :whale})
    assert :penguin_turn = rules.state

    # any guess that doesn't result in a win should not transition the state.
    # But when somebody does win, the state should become :game_over.
    assert {:ok, rules} = Rules.check(rules, {:win_check, :no_win})
    assert :penguin_turn = rules.state
    assert {:ok, rules} = Rules.check(rules, {:win_check, :win})
    assert :game_over = rules.state
  end

  describe "whale turn" do
    test "test if win or no_win" do
      assert %Rules{state: :initialized} = rules = Rules.new()
      assert %{state: :whale_turn} = rules = %{rules | state: :whale_turn}
      assert {:ok, %{state: :whale_turn} = rules} = Rules.check(rules, {:win_check, :no_win})
      assert {:ok, %{state: :game_over} = rules} = Rules.check(rules, {:win_check, :win})
    end

    test "if before 3rd turn moves have already eating penguin, state: :penguin_turn die_whale?: false" do
      assert %Rules{state: :initialized} = rules = Rules.new()

      assert %{state: :whale_turn} =
               rules = %{rules | state: :whale_turn, whale_counter: 2, whale_have_eaten?: true}

      assert {:ok,
              %Rules{
                whale_counter: 0,
                whale_have_eaten?: true,
                die_whale?: false,
                state: :penguin_turn
              } = rules} = Rules.check(rules, {:guess_coordinate, :whale})
    end

    test "if 3 moves without eating penguin, state: :game_over die_whale?: true" do
      assert %Rules{state: :initialized} = rules = Rules.new()
      assert %{state: :whale_turn} = rules = %{rules | state: :whale_turn, whale_counter: 1}

      assert {:ok, %Rules{whale_counter: 2, whale_have_eaten?: false, die_whale?: false} = rules} =
               Rules.check(rules, {:guess_coordinate, :whale})

      # after 3rd step die
      assert %{state: :whale_turn} = rules = %{rules | state: :whale_turn}

      assert {:ok,
              %Rules{
                whale_counter: 0,
                whale_have_eaten?: false,
                die_whale?: true,
                state: :penguin_turn,
                penguin: :win
              } = rules} = Rules.check(rules, {:guess_coordinate, :whale})
    end

    test "if 8 moves live, then on the 8th step tries to produce a child" do
      assert %Rules{state: :initialized} = rules = Rules.new()
      # after 6th step
      assert %{state: :whale_turn} = rules = %{rules | state: :whale_turn, whale_counter: 6}

      # after 7th step
      assert {:ok, %Rules{whale_counter: 7, whale_reproduce?: false} = rules} =
               Rules.check(rules, {:guess_coordinate, :whale})

      # after 8th step
      assert %{state: :whale_turn} = rules = %{rules | state: :whale_turn}

      assert {:ok, %Rules{whale_counter: 0, whale_reproduce?: true}} =
               Rules.check(rules, {:guess_coordinate, :whale})
    end

    test "after penguin_turn with error, it should go to whale_turn" do
      assert %Rules{state: :initialized} = rules = Rules.new()
      assert %{state: :whale_turn} = rules = %{rules | state: :whale_turn}

      # if player penguin tries to guess a coordinate,
      # it should return an error
      assert :error = Rules.check(rules, {:guess_coordinate, :penguin})

      # whale player can guess now a coordinate
      assert {:ok, %Rules{state: :penguin_turn} = rules} =
               Rules.check(rules, {:guess_coordinate, :whale})
    end

    test "if state is whale_turn, no more actions can be done" do
      assert %Rules{state: :initialized} = rules = Rules.new()
      rules = %Rules{rules | state: :players_set}
      assert {:ok, rules} = Rules.check(rules, {:set_creatures, :penguin})
      assert :error = Rules.check(rules, {:position_creatures, :penguin})
      assert {:ok, rules} = Rules.check(rules, {:set_creatures, :whale})
      assert :error = Rules.check(rules, {:position_creatures, :whale})
      assert rules.state == :penguin_turn

      assert {:ok, %Rules{state: :whale_turn} = rules} =
               Rules.check(rules, {:guess_coordinate, :penguin})

      assert rules.state == :whale_turn

      # if state has been transition to whale_turn
      # no more actions can be done
      assert :error = Rules.check(rules, {:guess_coordinate, :penguin})
      assert :error = Rules.check(rules, {:position_creatures, :penguin})
      assert :error = Rules.check(rules, {:position_creatures, :whale})
      assert :error = Rules.check(rules, {:set_creatures, :whale})
      assert :error = Rules.check(rules, :add_player)
    end
  end

  describe "penguin turns" do
    test "test if win or no_win" do
      assert %Rules{state: :initialized} = rules = Rules.new()
      assert %{state: :penguin_turn} = rules = %{rules | state: :penguin_turn}
      assert {:ok, %{state: :penguin_turn} = rules} = Rules.check(rules, {:win_check, :no_win})
      assert {:ok, %{state: :game_over} = rules} = Rules.check(rules, {:win_check, :win})
    end

    test "if 3 moves live, on the third step tries to reproduce" do
      assert %Rules{state: :initialized} = rules = Rules.new()
      assert %{state: :penguin_turn} = rules = %{rules | state: :penguin_turn}

      # 1st step
      assert {:ok, %Rules{penguin_counter: 1, penguin_reproduce: false} = rules} =
               Rules.check(rules, {:guess_coordinate, :penguin})

      # 2nd step
      assert %{state: :penguin_turn} = rules = %{rules | state: :penguin_turn}

      assert {:ok, %Rules{penguin_counter: 2, penguin_reproduce: false} = rules} =
               Rules.check(rules, {:guess_coordinate, :penguin})

      # 3rd step
      assert %{state: :penguin_turn} = rules = %{rules | state: :penguin_turn}

      assert {:ok, %Rules{penguin_counter: 0, penguin_reproduce: true} = rules} =
               Rules.check(rules, {:guess_coordinate, :penguin})
    end

    test "after penguin_turn, it should go to whale_turn" do
      assert %Rules{state: :initialized} = rules = Rules.new()
      assert %{state: :penguin_turn} = rules = %{rules | state: :penguin_turn}

      # an if player whale tries to guess a coordinate,
      # it should return an error
      assert :error = Rules.check(rules, {:guess_coordinate, :whale})

      # penguin player can guess now a coordinate
      assert {:ok, %Rules{state: :whale_turn} = rules} =
               Rules.check(rules, {:guess_coordinate, :penguin})
    end

    test "if state is penguin_turn we shouldn't be able to do anything" do
      assert %Rules{state: :initialized} = rules = Rules.new()
      rules = %Rules{rules | state: :players_set}
      assert {:ok, rules} = Rules.check(rules, {:set_creatures, :penguin})
      assert :error = Rules.check(rules, {:position_creatures, :penguin})
      assert {:ok, rules} = Rules.check(rules, {:set_creatures, :whale})
      assert :error = Rules.check(rules, {:position_creatures, :whale})
      assert rules.state == :penguin_turn

      # if state has been transition to penguin_turn
      # no more actions can be done
      assert :error = Rules.check(rules, :add_player)
      assert :error = Rules.check(rules, {:position_creatures, :penguin})
      assert :error = Rules.check(rules, {:position_creatures, :whale})
      assert :error = Rules.check(rules, {:set_creatures, :whale})
    end
  end

  describe "initialized rules" do
    test "after players have been set position creatures" do
      assert %Rules{state: :initialized} = rules = Rules.new()

      rules = %Rules{rules | state: :players_set}
      assert {:ok, rules} = Rules.check(rules, {:set_creatures, :penguin})
      # since penguin just set her creatures, she shouldn't be able to
      # position them any more, but whale still should be able to:
      assert :error = Rules.check(rules, {:position_creatures, :penguin})
      assert {:ok, rules} = Rules.check(rules, {:set_creatures, :whale})

      # let's have whale set his creatures and do the same check
      # after this both creatures have set their islands, so the state transition to
      # penguin_turn
      assert :error = Rules.check(rules, {:position_creatures, :whale})
      assert rules.state == :penguin_turn
    end

    test "position creatures for penguin and whale players" do
      assert %Rules{state: :initialized} = rules = Rules.new()

      assert {:ok,
              %Rules{
                penguin: :creatures_not_set,
                whale: :creatures_not_set,
                state: :waiting_for_player
              } = rules} = Rules.check(rules, :add_player)

      assert {:ok,
              %Rules{penguin: :creatures_not_set, whale: :creatures_not_set, state: :players_set} =
                rules} = Rules.check(rules, :add_player)

      assert {:ok, %Rules{state: :players_set} = rules} =
               Rules.check(rules, {:position_creatures, :penguin})

      assert {:ok, %Rules{state: :players_set} = rules} =
               Rules.check(rules, {:position_creatures, :whale})
    end

    test "then add player" do
      assert %Rules{state: :initialized} = rules = Rules.new()
      assert {:ok, %Rules{state: :waiting_for_player} = rules} = Rules.check(rules, :add_player)
      assert {:ok, %Rules{state: :players_set} = rules} = Rules.check(rules, :add_player)
    end

    test "then add player with invalid key" do
      assert %Rules{state: :initialized} = rules = Rules.new()
      assert :error = Rules.check(rules, :wrong_action)
      assert :initialized = rules.state
    end
  end
end
