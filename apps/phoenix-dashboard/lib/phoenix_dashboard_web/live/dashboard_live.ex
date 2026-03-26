defmodule PhoenixDashboardWeb.DashboardLive do
  use PhoenixDashboardWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    admin_user = Map.get(session, "admin_user", "admin")

    {:ok,
     assign(socket,
       page_title: "Dashboard",
       admin_user: admin_user,
       uptime: format_uptime(),
       elixir_ver: System.version(),
       otp_ver: :erlang.system_info(:otp_release) |> List.to_string()
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="dashboard">
      <div class="terminal-body">
        <div class="welcome-block">
          <pre class="ascii-art welcome-ascii">
            ╦ ╦╔═╗╦ ╦╔═╗╔╦╗╔═╗╔╗╔   ╔═╗╦  ╦
            ║ ║║ ║║ ║╚═╗ ║ ║ ║║║║   ║  ╚╗╔╝
            ╩ ╩╚═╝╚═╝╚═╝ ╩ ╚═╝╝╚╝   ╚═╝ ╚╝
          </pre>
        </div>

        <div class="info-section">
          <p class="prompt-line">
            <span class="prompt-user">{@admin_user}</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
            <span class="prompt-sep">~</span>
            <span class="prompt-cmd">status</span>
          </p>

          <div class="status-grid">
            <div class="status-row">
              <span class="status-key">System</span>
              <span class="status-val">houston-cv admin dashboard v0.1.0</span>
            </div>
            <div class="status-row">
              <span class="status-key">Runtime</span>
              <span class="status-val">Elixir {@elixir_ver} / OTP {@otp_ver}</span>
            </div>
            <div class="status-row">
              <span class="status-key">Uptime</span>
              <span class="status-val">{@uptime}</span>
            </div>
            <div class="status-row">
              <span class="status-key">Database</span>
              <span class="status-val">SurrealDB (houston/cv)</span>
            </div>
          </div>
        </div>

        <div class="dir-listing">
          <p class="prompt-line">
            <span class="prompt-user">{@admin_user}</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
            <span class="prompt-sep">~</span>
            <span class="prompt-cmd">ls</span>
          </p>

          <div class="dir-section">
            <div class="dir-header">
              <span class="dir-perms">drwxr-xr-x</span>
              <span class="dir-name">content/</span>
            </div>
            <div class="dir-children">
              <.link navigate={~p"/content/skills"} class="dir-link">skills/</.link>
              <.link navigate={~p"/content/projects"} class="dir-link">projects/</.link>
              <.link navigate={~p"/content/experience"} class="dir-link">experience/</.link>
              <.link navigate={~p"/content/certifications"} class="dir-link">certifications/</.link>
              <.link navigate={~p"/content/blog"} class="dir-link">blog/</.link>
            </div>
          </div>

          <div class="dir-section">
            <div class="dir-header">
              <span class="dir-perms">drwxr-xr-x</span>
              <span class="dir-name">insights/</span>
            </div>
            <div class="dir-children">
              <.link navigate={~p"/insights/visitors"} class="dir-link">visitors/</.link>
              <.link navigate={~p"/insights/skills"} class="dir-link">skills/</.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp format_uptime do
    {uptime_ms, _} = :erlang.statistics(:wall_clock)
    total_seconds = div(uptime_ms, 1000)
    hours = div(total_seconds, 3600)
    minutes = div(rem(total_seconds, 3600), 60)
    seconds = rem(total_seconds, 60)
    "#{hours}h #{minutes}m #{seconds}s"
  end
end
