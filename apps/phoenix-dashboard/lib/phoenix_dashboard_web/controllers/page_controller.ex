defmodule PhoenixDashboardWeb.PageController do
  use PhoenixDashboardWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
