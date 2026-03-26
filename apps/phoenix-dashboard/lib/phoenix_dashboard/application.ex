defmodule PhoenixDashboard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PhoenixDashboardWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:phoenix_dashboard, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PhoenixDashboard.PubSub},
      # Start a worker by calling: PhoenixDashboard.Worker.start_link(arg)
      # {PhoenixDashboard.Worker, arg},
      # Start to serve requests, typically the last entry
      PhoenixDashboardWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhoenixDashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PhoenixDashboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
