defmodule PhoenixDashboardWeb.SessionController do
  use PhoenixDashboardWeb, :controller

  alias PhoenixDashboard.Auth

  def new(conn, _params) do
    render(conn, :new, error: nil)
  end

  def create(conn, %{"session" => %{"username" => username, "password" => password}}) do
    case Auth.authenticate(username, password) do
      :ok ->
        conn
        |> put_session(:authenticated, true)
        |> put_session(:admin_user, username)
        |> redirect(to: "/")

      :error ->
        conn
        |> put_flash(:error, "Invalid credentials")
        |> render(:new, error: "Invalid credentials")
    end
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/login")
  end
end
