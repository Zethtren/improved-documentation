defmodule PhoenixDashboardWeb.Plugs.RequireAuth do
  @moduledoc """
  Plug that enforces session-based authentication.
  Redirects unauthenticated requests to `/login`.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :authenticated) do
      conn
    else
      conn
      |> redirect(to: "/login")
      |> halt()
    end
  end
end
