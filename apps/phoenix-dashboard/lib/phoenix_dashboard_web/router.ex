defmodule PhoenixDashboardWeb.Router do
  use PhoenixDashboardWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixDashboardWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :authenticated do
    plug PhoenixDashboardWeb.Plugs.RequireAuth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes — login / logout
  scope "/", PhoenixDashboardWeb do
    pipe_through :browser

    get "/login", SessionController, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
  end

  # Protected routes — require authentication
  scope "/", PhoenixDashboardWeb do
    pipe_through [:browser, :authenticated]

    live "/", DashboardLive
    live "/analytics", AnalyticsLive
    live "/skills", SkillsLive
    live "/projects", ProjectsLive
    live "/experience", ExperienceLive
    live "/certifications", CertificationsLive
  end
end
