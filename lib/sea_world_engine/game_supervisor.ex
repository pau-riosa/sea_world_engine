defmodule SeaWorldEngine.GameSupervisor do
  @moduledoc """
  Game supervisor
  """
  use DynamicSupervisor
  require Logger
  alias SeaWorldEngine.Game

  def start_game(name) do
    spec = %{id: Game, start: {Game, :start_link, [name]}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_game(name) do
    Logger.warn("END GAME.")
    :ets.delete(:game_state, name)
    Supervisor.terminate_child(__MODULE__, pid_from_name(name))
  end

  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def init(init_args) do
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: init_args)
  end

  defp pid_from_name(name) do
    name
    |> Game.via_tuple()
    |> GenServer.whereis()
  end
end
