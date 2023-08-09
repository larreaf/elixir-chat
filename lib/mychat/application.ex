defmodule Mychat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MychatWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Mychat.PubSub},
      # Start Finch
      {Finch, name: Mychat.Finch},
      # Start the Endpoint (http/https)
      MychatWeb.Endpoint,
      MychatWeb.Presence,
      Topics.Supervisor
      # Start a worker by calling: Mychat.Worker.start_link(arg)
      # {Mychat.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mychat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MychatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
