defmodule SeaWorldEngine.Rules do
  @moduledoc """
  define the rules of the SeaWorld game
  """
  alias __MODULE__

  defstruct state: :initialized,
            penguin: :creatures_not_set,
            whale: :creatures_not_set,
            penguin_counter: 0,
            whale_counter: 0,
            die_counter: 0,
            penguin_reproduce: false,
            whale_reproduce?: false,
            whale_have_eaten?: false,
            die_whale?: false

  @doc """
  define new rules
  """
  def new, do: %Rules{}

  @doc """
  checks state and action 
  """
  def check(%Rules{state: :penguin_turn} = rules, {:win_check, win_or_not}) do
    case win_or_not do
      :no_win -> {:ok, rules}
      :win -> {:ok, %Rules{rules | state: :game_over}}
    end
  end

  def check(%Rules{state: :whale_turn} = rules, {:win_check, win_or_not}) do
    case win_or_not do
      :no_win -> {:ok, rules}
      :win -> {:ok, %Rules{rules | state: :game_over}}
    end
  end

  def check(
        %Rules{state: :penguin_turn, penguin_counter: counter} = rules,
        {:guess_coordinate, :penguin}
      )
      when counter == 2 do
    {:ok, %Rules{rules | state: :whale_turn, penguin_counter: 0, penguin_reproduce: true}}
  end

  def check(
        %Rules{state: :whale_turn, whale_counter: _counter, whale_have_eaten?: true} = rules,
        {:guess_coordinate, :whale}
      ) do
    {:ok, %Rules{rules | state: :penguin_turn, whale_counter: 0, die_whale?: false}}
  end

  def check(
        %Rules{state: :whale_turn, whale_counter: counter, whale_have_eaten?: false} = rules,
        {:guess_coordinate, :whale}
      )
      when counter == 2 do
    {:ok, %Rules{rules | state: :penguin_turn, penguin: :win, whale_counter: 0, die_whale?: true}}
  end

  def check(
        %Rules{state: :whale_turn, whale_counter: counter} = rules,
        {:guess_coordinate, :whale}
      )
      when counter == 7 do
    {:ok, %Rules{rules | state: :penguin_turn, whale_counter: 0, whale_reproduce?: true}}
  end

  def check(
        %Rules{state: :penguin_turn, penguin_counter: counter} = rules,
        {:guess_coordinate, :penguin}
      ),
      do: {:ok, %Rules{rules | state: :whale_turn, penguin_counter: counter + 1}}

  def check(
        %Rules{state: :whale_turn, whale_counter: counter} = rules,
        {:guess_coordinate, :whale}
      ),
      do: {:ok, %Rules{rules | state: :penguin_turn, whale_counter: counter + 1}}

  def check(%Rules{state: :whale_turn} = rules, {:guess_coordinate, :whale}),
    do: {:ok, %Rules{rules | state: :penguin_turn}}

  def check(%Rules{state: :players_set} = rules, {:set_creatures, player}) do
    rules = Map.put(rules, player, :creatures_set)

    case both_players_creatures_set?(rules) do
      true -> {:ok, %Rules{rules | state: :penguin_turn}}
      false -> {:ok, rules}
    end
  end

  def check(%Rules{state: :players_set} = rules, {:position_creatures, player}) do
    case Map.fetch!(rules, player) do
      :creatures_set -> :error
      :creatures_not_set -> {:ok, rules}
    end
  end

  def check(%Rules{state: :waiting_for_player} = rules, :add_player),
    do: {:ok, %Rules{rules | state: :players_set}}

  def check(%Rules{state: :initialized} = rules, :add_player),
    do: {:ok, %Rules{rules | state: :waiting_for_player}}

  def check(_state, _action), do: :error

  defp both_players_creatures_set?(rules),
    do: rules.penguin == :creatures_set && rules.whale == :creatures_set
end
