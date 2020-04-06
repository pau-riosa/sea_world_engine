defmodule SeaWorldEngine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Registry.Game},
      SeaWorldEngine.GameSupervisor
      # Starts a worker by calling: SeaWorldEngine.Worker.start_link(arg)
      # {SeaWorldEngine.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    :ets.new(:game_state, [:public, :named_table])
    opts = [strategy: :one_for_one, name: SeaWorldEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
