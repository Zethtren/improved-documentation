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

    # Content management
    live "/content/skills", SkillsLive
    live "/content/projects", ProjectsLive
    live "/content/experience", ExperienceLive
    live "/content/certifications", CertificationsLive
    live "/content/blog", BlogLive
    live "/content/blog/:id/edit", BlogPostLive

    # Insights / Analytics
    live "/insights/visitors", AnalyticsLive
    live "/insights/skills", SkillAnalyticsLive
  end
end
