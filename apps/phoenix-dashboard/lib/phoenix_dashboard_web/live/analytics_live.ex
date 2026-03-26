defmodule PhoenixDashboardWeb.AnalyticsLive do
  use PhoenixDashboardWeb, :live_view

  alias PhoenixDashboard.SurrealClient

  @refresh_interval 30_000

  @impl true
  def mount(_params, session, socket) do
    admin_user = Map.get(session, "admin_user", "admin")

    if connected?(socket) do
      schedule_refresh()
    end

    socket =
      socket
      |> assign(
        page_title: "Analytics",
        admin_user: admin_user,
        total_views: 0,
        today_views: 0,
        views_per_page: [],
        recent_views: []
      )
      |> fetch_analytics()

    {:ok, socket}
  end

  @impl true
  def handle_info(:refresh, socket) do
    schedule_refresh()
    {:noreply, fetch_analytics(socket)}
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_interval)
  end

  defp fetch_analytics(socket) do
    total_views = fetch_total_views()
    today_views = fetch_today_views()
    views_per_page = fetch_views_per_page()
    recent_views = fetch_recent_views()

    assign(socket,
      total_views: total_views,
      today_views: today_views,
      views_per_page: views_per_page,
      recent_views: recent_views
    )
  end

  defp fetch_total_views do
    case SurrealClient.query("SELECT count() AS total FROM page_view GROUP ALL") do
      {:ok, [%{"result" => [%{"total" => total}]} | _]} -> total
      {:ok, [%{"result" => []} | _]} -> 0
      _ -> 0
    end
  end

  defp fetch_today_views do
    case SurrealClient.query(
           "SELECT count() AS total FROM page_view WHERE timestamp > time::now() - 1d GROUP ALL"
         ) do
      {:ok, [%{"result" => [%{"total" => total}]} | _]} -> total
      {:ok, [%{"result" => []} | _]} -> 0
      _ -> 0
    end
  end

  defp fetch_views_per_page do
    case SurrealClient.query(
           "SELECT path, count() AS views FROM page_view GROUP BY path ORDER BY views DESC"
         ) do
      {:ok, [%{"result" => results} | _]} when is_list(results) ->
        Enum.map(results, fn row ->
          %{
            path: Map.get(row, "path", "unknown"),
            views: Map.get(row, "views", 0)
          }
        end)

      _ ->
        []
    end
  end

  defp fetch_recent_views do
    case SurrealClient.query("SELECT * FROM page_view ORDER BY timestamp DESC LIMIT 20") do
      {:ok, [%{"result" => results} | _]} when is_list(results) ->
        Enum.map(results, fn row ->
          %{
            path: Map.get(row, "path", "unknown"),
            referrer: Map.get(row, "referrer"),
            timestamp: Map.get(row, "timestamp", "")
          }
        end)

      _ ->
        []
    end
  end

  defp format_timestamp(ts) when is_binary(ts) do
    case DateTime.from_iso8601(ts) do
      {:ok, dt, _} ->
        Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")

      _ ->
        ts
    end
  end

  defp format_timestamp(_), do: "--"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="dashboard">
      <div class="terminal-body">
        <%!-- Summary stats --%>
        <div class="info-section">
            <p class="prompt-line">
              <span class="prompt-user">{@admin_user}</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
              <span class="prompt-sep">~</span>
              <span class="prompt-cmd">analytics --summary</span>
            </p>

            <div class="status-grid">
              <div class="status-row">
                <span class="status-key">Total Views</span>
                <span class="status-val" style="color: var(--ctp-green); font-weight: 700;">{@total_views}</span>
              </div>
              <div class="status-row">
                <span class="status-key">Today</span>
                <span class="status-val" style="color: var(--ctp-green); font-weight: 700;">{@today_views}</span>
              </div>
              <div class="status-row">
                <span class="status-key">Refresh</span>
                <span class="status-val">every 30s (auto)</span>
              </div>
            </div>
          </div>

          <%!-- Views per page table --%>
          <div class="info-section" style="margin-top: 1.5rem;">
            <p class="prompt-line">
              <span class="prompt-user">{@admin_user}</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
              <span class="prompt-sep">~</span>
              <span class="prompt-cmd">analytics --by-page</span>
            </p>

            <div style="margin-top: 0.5rem; font-family: var(--font-mono, 'JetBrains Mono', monospace);">
              <div style="display: flex; gap: 2rem; padding: 0.25rem 0; border-bottom: 1px solid var(--ctp-surface1, #45475a); margin-bottom: 0.25rem;">
                <span style="width: 5rem; color: var(--ctp-subtext0, #a6adc8); font-weight: 700;">VIEWS</span>
                <span style="color: var(--ctp-subtext0, #a6adc8); font-weight: 700;">PATH</span>
              </div>
              <%= for row <- @views_per_page do %>
                <div style="display: flex; gap: 2rem; padding: 0.15rem 0;">
                  <span style="width: 5rem; color: var(--ctp-green); font-weight: 700;">{row.views}</span>
                  <span style="color: var(--ctp-blue);">{row.path}</span>
                </div>
              <% end %>
              <%= if @views_per_page == [] do %>
                <p style="color: var(--ctp-overlay1, #7f849c); padding: 0.5rem 0;">-- no data --</p>
              <% end %>
            </div>
          </div>

          <%!-- Recent views log (journalctl style) --%>
          <div class="info-section" style="margin-top: 1.5rem;">
            <p class="prompt-line">
              <span class="prompt-user">{@admin_user}</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
              <span class="prompt-sep">~</span>
              <span class="prompt-cmd">journalctl -u page-views -n 20</span>
            </p>

            <div style="margin-top: 0.5rem; font-family: var(--font-mono, 'JetBrains Mono', monospace); font-size: 0.85rem;">
              <%= for entry <- @recent_views do %>
                <div style="padding: 0.1rem 0; white-space: nowrap;">
                  <span style="color: var(--ctp-overlay1, #7f849c);">[{format_timestamp(entry.timestamp)}]</span>
                  <span style="color: var(--ctp-text, #cdd6f4);"> GET </span>
                  <span style="color: var(--ctp-blue);">{entry.path}</span>
                  <%= if entry.referrer && entry.referrer != "" do %>
                    <span style="color: var(--ctp-overlay1, #7f849c);">  (referrer: {entry.referrer})</span>
                  <% end %>
                </div>
              <% end %>
              <%= if @recent_views == [] do %>
                <p style="color: var(--ctp-overlay1, #7f849c); padding: 0.5rem 0;">-- no recent views --</p>
              <% end %>
            </div>
          </div>

      </div>
    </div>
    """
  end
end
