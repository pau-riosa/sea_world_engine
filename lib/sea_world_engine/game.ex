defmodule SeaWorldEngine.Game do
  @moduledoc """
  Game server of the game 
  """

  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient
  require Logger
  alias SeaWorldEngine.{Coordinate, Creature, GameSupervisor, Guesses, Rules, World}

  @players [:penguin, :whale]

  @timeout 60 * 60 * 24 * 1000
  @doc """
  initialized the game
  """
  def init(game_id) do
    Logger.info("Game Initialize!")
    check_state()
    send(self(), {:set_state, game_id})
    {:ok, fresh_state(game_id)}
  end

  def via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  @doc """
  starts the game
  """
  def start_link(name) when is_binary(name),
    do: GenServer.start_link(__MODULE__, name, name: via_tuple(name))

  @doc """
  guess a coordinate
  """
  def guess_coordinate(game, player, row, col) when player in @players,
    do: GenServer.call(game, {:guess_coordinate, player, row, col})

  @doc """
  set creatures after positioning them
  """
  def set_creatures(game, player), do: GenServer.call(game, {:set_creatures, player})

  @doc """
  positions a creature [:penguin, :whale] 
  """
  def position_creature(game, player, key, row, col) when player in @players,
    do: GenServer.call(game, {:position_creature, player, key, row, col})

  @doc """
  adds a player
  """
  def add_player_penguin(game, penguin) when is_binary(penguin),
    do: GenServer.call(game, {:add_player_penguin, penguin})

  def add_player_whale(game, whale) when is_binary(whale),
    do: GenServer.call(game, {:add_player_whale, whale})

  @doc """
  handle_call/3 for guess_coordinate/4
  """
  def handle_call({:guess_coordinate, player_key, row, col}, _from, state_data) do
    world = get_world(state_data)

    with {:ok, rules} <-
           Rules.check(state_data.rules, {:guess_coordinate, player_key}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {hit_or_miss, forested_island, win_status, new_world} <-
           World.guess(world, player_key, coordinate),
         {:ok, rules} <- Rules.check(rules, {:win_check, win_status}) do
      Logger.debug("#{player_key} #{hit_or_miss}")
      Logger.debug("#{player_key} #{win_status}")
      Logger.warn("#{rules.state}")

      state_data
      |> update_rules(rules)
      |> update_world(new_world, coordinate)
      |> update_guesses(player_key, hit_or_miss, coordinate)
      |> reply_success({hit_or_miss, forested_island, win_status})
    else
      :error ->
        {:reply, :error, state_data}

      {:error, :invalid_coordinate} = error ->
        Logger.error("coordinate invalid.")
        {:error, error, state_data}
    end
  end

  @doc """
  handle_call/3 for set_creature/2
  """
  def handle_call({:set_creatures, player}, _from, state_data) do
    world = get_world(state_data)

    with {:ok, rules} <- Rules.check(state_data.rules, {:set_creatures, player}),
         true <- World.all_creatures_positioned?(world) do
      {_, _, data, _} =
        state =
        state_data
        |> update_rules(rules)
        |> reply_success({:ok, world})

      Logger.info("creatures all set.")
      Logger.debug("#{data.rules.state}")
      state
    else
      :error ->
        {:reply, :error, state_data}

      false ->
        Logger.error("creatures are not positioned.")
        {:reply, {:error, :not_all_creatures_positioned}, state_data}
    end
  end

  @doc """
  handle_call/3 for position_creature/5 
  """
  def handle_call({:position_creature, player, key, row, col}, _from, state_data) do
    world = get_world(state_data)

    with {:ok, rules} <- Rules.check(state_data.rules, {:position_creatures, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {:ok, creature} <- Creature.new(key, coordinate),
         world = [_ | _] <- World.position_creature(world, creature) do
      Logger.info("creature positioned at [row: #{row}, col: #{col}]")

      state_data
      |> update_rules(rules)
      |> update_world(world, coordinate)
      |> reply_success(:ok)
    else
      :error ->
        {:reply, :error, state_data}

      {:error, :overlapping_creature} = error ->
        Logger.error("creature overlaps")
        {:reply, error, state_data}

      {:error, :invalid_coordinate} = error ->
        Logger.error("invalid coordinate")
        {:reply, error, state_data}

      {:error, :invalid_creature} = error ->
        Logger.error("invalid creature")
        {:reply, error, state_data}
    end
  end

  @doc """
  handle_call/3 for add_player/2 
  """
  def handle_call({:add_player_penguin, penguin}, _from, state_data) do
    case Rules.check(state_data.rules, :add_player) do
      {:ok, rules} ->
        Logger.info("#{penguin} assigned as Penguin")

        state_data
        |> update_penguin_name(penguin)
        |> update_rules(rules)
        |> reply_success(:ok)

      :error ->
        {:reply, :error, state_data}
    end
  end

  def handle_call({:add_player_whale, whale}, _from, state_data) do
    case Rules.check(state_data.rules, :add_player) do
      {:ok, rules} ->
        Logger.info("#{whale} assigned as Whale")

        state_data
        |> update_whale_name(whale)
        |> update_rules(rules)
        |> reply_success(:ok)

      :error ->
        {:reply, :error, state_data}
    end
  end

  # check state every 1 second
  # die whale ends the game
  def handle_info(:check_state, %{rules: %Rules{die_whale?: true}} = state_data) do
    Logger.debug("check_state...")
    check_state()
    {:stop, {:shutdown, :game_over}, state_data}
  end

  def handle_info(:check_state, state_data) do
    {:noreply, state_data, @timeout}
  end

  def handle_info({:set_state, game_id}, _state_data) do
    state_data =
      case :ets.lookup(:game_state, game_id) do
        [] ->
          fresh_state(game_id)

        [{_key, state}] ->
          state
      end

    :ets.insert(:game_state, {game_id, state_data})
    {:noreply, state_data, @timeout}
  end

  def handle_info(:timeout, state_data) do
    {:stop, {:shutdown, :timeout}, state_data}
  end

  def terminate({:shutdown, :game_over}, state_data) do
    Logger.warn("GAME OVER: WHALE DIES")
    GameSupervisor.stop_game(state_data.penguin.name)
  end

  def terminate(_reason, _state), do: :ok

  # updates the guesses list
  defp update_guesses(state_data, player_key, hit_or_miss, coordinate) do
    update_in(state_data[player_key].guesses, fn guesses ->
      Guesses.add(guesses, hit_or_miss, coordinate)
    end)
  end

  # update player's name
  defp update_whale_name(state_data, whale) do
    put_in(state_data.whale.name, whale)
  end

  defp update_penguin_name(state_data, penguin) do
    put_in(state_data.penguin.name, penguin)
  end

  # update rules
  defp update_rules(state_data, rules), do: %{state_data | rules: rules}

  # update world
  defp update_world(state_data, world, coordinate) do
    do_update_world(state_data, state_data.rules, world, coordinate)
  end

  defp do_update_world(state_data, %{whale_reproduce?: true} = _rules, world, coordinate) do
    generate_coordinate(state_data, :whale, world, coordinate)
  end

  defp do_update_world(state_data, %{penguin_reproduce: true} = rules, world, coordinate) do
    generate_coordinate(state_data, :penguin, world, coordinate)
  end

  defp do_update_world(state_data, _rules, world, _coordinate), do: %{state_data | world: world}

  # reproduce penguin if 3 moves lives,
  # reproduce whale if 8 moves lives
  defp generate_coordinate(state_data, key, world, coordinate) do
    with {:ok, coordinate} <- Coordinate.check_coordinate_neighbor(coordinate),
         {:ok, creature} <- Creature.new(key, coordinate),
         new_world = [_ | _] <- World.position_creature(world, creature) do
      Logger.debug("#{key} reproduces")
      %{state_data | world: new_world}
    else
      _ ->
        Logger.error("#{key} cannot reproduce cannot find a free place.")
        %{state_data | world: world}
    end
  end

  # success reply
  defp reply_success(state_data, reply) do
    :ets.insert(:game_state, {state_data.game_id, state_data})
    {:reply, reply, state_data, @timeout}
  end

  # gets the world
  defp get_world(state_data), do: state_data.world

  # gets a fresh state of the game
  defp fresh_state(game_id) do
    penguin = %{name: nil, guesses: Guesses.new()}
    whale = %{name: nil, guesses: Guesses.new()}
    %{game_id: game_id, penguin: penguin, whale: whale, rules: %Rules{}, world: World.new()}
  end

  # check state every microsecs
  defp check_state() do
    Process.send_after(self(), :check_state, 10)
  end
end
