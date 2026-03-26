defmodule PhoenixDashboardWeb.SkillAnalyticsLive do
  use PhoenixDashboardWeb, :live_view

  alias PhoenixDashboard.SurrealClient

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Skill Analytics")
     |> fetch_connected_skills()
     |> fetch_skill_enables()
     |> fetch_category_distribution()
     |> fetch_experience_skills()
     |> fetch_certification_coverage()
     |> fetch_next_skills()}
  end

  # ---------------------------------------------------------------------------
  # Data fetching
  # ---------------------------------------------------------------------------

  defp fetch_connected_skills(socket) do
    sql = """
    SELECT name, proficiency, count(<-uses_skill<-project) AS project_count FROM skill ORDER BY project_count DESC;
    """

    case SurrealClient.query(sql) do
      {:ok, rows} when is_list(rows) -> assign(socket, connected_skills: rows)
      _ -> assign(socket, connected_skills: [])
    end
  end

  defp fetch_skill_enables(socket) do
    sql = """
    SELECT *, ->enables->skill.name AS enables FROM skill;
    """

    case SurrealClient.query(sql) do
      {:ok, rows} when is_list(rows) -> assign(socket, skill_enables: rows)
      _ -> assign(socket, skill_enables: [])
    end
  end

  defp fetch_category_distribution(socket) do
    sql = """
    SELECT category, count() AS total, math::mean(proficiency) AS avg_proficiency FROM skill GROUP BY category;
    """

    case SurrealClient.query(sql) do
      {:ok, rows} when is_list(rows) -> assign(socket, category_distribution: rows)
      _ -> assign(socket, category_distribution: [])
    end
  end

  defp fetch_experience_skills(socket) do
    sql = """
    SELECT company, title, <-required<-skill.name AS skills_used FROM experience;
    """

    case SurrealClient.query(sql) do
      {:ok, rows} when is_list(rows) -> assign(socket, experience_skills: rows)
      _ -> assign(socket, experience_skills: [])
    end
  end

  defp fetch_certification_coverage(socket) do
    sql = """
    SELECT title AS cert, ->validates->skill.name AS validates_skills FROM certification;
    """

    case SurrealClient.query(sql) do
      {:ok, rows} when is_list(rows) -> assign(socket, cert_coverage: rows)
      _ -> assign(socket, cert_coverage: [])
    end
  end

  defp fetch_next_skills(socket) do
    sql = """
    SELECT ->enables->skill AS next_skills FROM skill;
    """

    case SurrealClient.query(sql) do
      {:ok, rows} when is_list(rows) -> assign(socket, next_skills: rows)
      _ -> assign(socket, next_skills: [])
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp flat_names(list) when is_list(list) do
    list
    |> List.flatten()
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
  end

  defp flat_names(_), do: []

  defp build_learn_next(skill_enables) do
    # Collect all skill names we currently have
    current_names =
      skill_enables
      |> Enum.map(& &1["name"])
      |> Enum.filter(&is_binary/1)
      |> MapSet.new()

    # Build pairs: current_skill -> potential_skill
    skill_enables
    |> Enum.flat_map(fn skill ->
      enables = flat_names(skill["enables"])

      enables
      |> Enum.reject(&MapSet.member?(current_names, &1))
      |> Enum.map(fn target -> {skill["name"], target} end)
    end)
    |> Enum.uniq()
  end

  # ---------------------------------------------------------------------------
  # Render
  # ---------------------------------------------------------------------------

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :learn_next, build_learn_next(assigns.skill_enables))

    ~H"""
    <div class="dashboard">
      <%!-- Section 1: Most Connected Skills --%>
      <div class="terminal-window">
        <div class="terminal-titlebar">
          <span class="terminal-dot red"></span>
          <span class="terminal-dot yellow"></span>
          <span class="terminal-dot green"></span>
          <span class="titlebar-text">houston-cv :: skill analytics :: most connected</span>
        </div>
        <div class="terminal-body">
          <p class="prompt-line">
            <span class="prompt-user">admin</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
            <span class="prompt-sep">~</span>
            <span class="prompt-cmd">SELECT name, proficiency, count(projects) FROM skill</span>
          </p>

          <%= if @connected_skills == [] do %>
            <p class="hint-text">-- no skill data --</p>
          <% else %>
            <table class="terminal-table">
              <thead>
                <tr>
                  <th>name</th>
                  <th>proficiency</th>
                  <th>projects</th>
                </tr>
              </thead>
              <tbody>
                <%= for skill <- @connected_skills do %>
                  <tr>
                    <td style="color: var(--ctp-blue); font-weight: 700;">{skill["name"]}</td>
                    <td>
                      <span class="proficiency-bar">
                        <span style="color: var(--ctp-green);"><%= String.duplicate("█", round((skill["proficiency"] || 0) / 10)) %></span><span style="color: var(--ctp-surface1);"><%= String.duplicate("░", 10 - round((skill["proficiency"] || 0) / 10)) %></span>
                        <span style="color: var(--ctp-green);"> <%= round(skill["proficiency"] || 0) %>%</span>
                      </span>
                    </td>
                    <td style="color: var(--ctp-green); font-weight: 700;">{skill["project_count"] || 0}</td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          <% end %>
        </div>
      </div>

      <%!-- Section 2: Skill Distribution by Category --%>
      <div class="terminal-window">
        <div class="terminal-titlebar">
          <span class="terminal-dot red"></span>
          <span class="terminal-dot yellow"></span>
          <span class="terminal-dot green"></span>
          <span class="titlebar-text">houston-cv :: skill analytics :: distribution</span>
        </div>
        <div class="terminal-body">
          <p class="prompt-line">
            <span class="prompt-user">admin</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
            <span class="prompt-sep">~</span>
            <span class="prompt-cmd">SELECT category, count(), avg(proficiency) FROM skill GROUP BY category</span>
          </p>

          <%= if @category_distribution == [] do %>
            <p class="hint-text">-- no category data --</p>
          <% else %>
            <table class="terminal-table">
              <thead>
                <tr>
                  <th>category</th>
                  <th>count</th>
                  <th>avg proficiency</th>
                </tr>
              </thead>
              <tbody>
                <%= for cat <- @category_distribution do %>
                  <tr>
                    <td style="color: var(--ctp-yellow); font-weight: 700;">{cat["category"]}</td>
                    <td style="color: var(--ctp-green);">{cat["total"] || 0}</td>
                    <td>
                      <span class="proficiency-bar">
                        <span style="color: var(--ctp-green);"><%= String.duplicate("█", round((cat["avg_proficiency"] || 0) / 10)) %></span><span style="color: var(--ctp-surface1);"><%= String.duplicate("░", 10 - round((cat["avg_proficiency"] || 0) / 10)) %></span>
                        <span style="color: var(--ctp-green);"> <%= round(cat["avg_proficiency"] || 0) %>%</span>
                      </span>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          <% end %>
        </div>
      </div>

      <%!-- Section 3: Career Skill Map --%>
      <div class="terminal-window">
        <div class="terminal-titlebar">
          <span class="terminal-dot red"></span>
          <span class="terminal-dot yellow"></span>
          <span class="terminal-dot green"></span>
          <span class="titlebar-text">houston-cv :: skill analytics :: career map</span>
        </div>
        <div class="terminal-body">
          <p class="prompt-line">
            <span class="prompt-user">admin</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
            <span class="prompt-sep">~</span>
            <span class="prompt-cmd">SELECT company, skills_used FROM experience</span>
          </p>

          <%= if @experience_skills == [] do %>
            <p class="hint-text">-- no experience data --</p>
          <% else %>
            <div class="analytics-entries">
              <%= for exp <- @experience_skills do %>
                <div class="analytics-entry">
                  <span class="entry-label" style="color: var(--ctp-blue); font-weight: 700;">
                    {exp["company"]}
                  </span>
                  <span class="entry-sublabel" style="color: var(--ctp-subtext0); font-size: 0.75rem;">
                    {exp["title"]}
                  </span>
                  <div class="skill-tags">
                    <%= for skill_name <- flat_names(exp["skills_used"]) do %>
                      <span class="skill-tag">[{skill_name}]</span>
                    <% end %>
                    <%= if flat_names(exp["skills_used"]) == [] do %>
                      <span class="hint-text">-- no linked skills --</span>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <%!-- Section 4: Certification Coverage --%>
      <div class="terminal-window">
        <div class="terminal-titlebar">
          <span class="terminal-dot red"></span>
          <span class="terminal-dot yellow"></span>
          <span class="terminal-dot green"></span>
          <span class="titlebar-text">houston-cv :: skill analytics :: certifications</span>
        </div>
        <div class="terminal-body">
          <p class="prompt-line">
            <span class="prompt-user">admin</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
            <span class="prompt-sep">~</span>
            <span class="prompt-cmd">SELECT cert, validates_skills FROM certification</span>
          </p>

          <%= if @cert_coverage == [] do %>
            <p class="hint-text">-- no certification data --</p>
          <% else %>
            <div class="analytics-entries">
              <%= for cert <- @cert_coverage do %>
                <div class="analytics-entry">
                  <span class="entry-label" style="color: var(--ctp-yellow); font-weight: 700;">
                    {cert["cert"]}
                  </span>
                  <div class="cert-arrows">
                    <%= for skill_name <- flat_names(cert["validates_skills"]) do %>
                      <span class="cert-arrow">
                        <span style="color: var(--ctp-overlay1);">-></span>
                        <span style="color: var(--ctp-blue);">{skill_name}</span>
                      </span>
                    <% end %>
                    <%= if flat_names(cert["validates_skills"]) == [] do %>
                      <span class="hint-text">-- no linked skills --</span>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <%!-- Section 5: What to Learn Next --%>
      <div class="terminal-window">
        <div class="terminal-titlebar">
          <span class="terminal-dot red"></span>
          <span class="terminal-dot yellow"></span>
          <span class="terminal-dot green"></span>
          <span class="titlebar-text">houston-cv :: skill analytics :: learn next</span>
        </div>
        <div class="terminal-body">
          <p class="prompt-line">
            <span class="prompt-user">admin</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
            <span class="prompt-sep">~</span>
            <span class="prompt-cmd">SELECT enables FROM skill -- gap analysis</span>
          </p>

          <%= if @learn_next == [] do %>
            <p class="hint-text">-- no skill gaps detected (or no enables graph data) --</p>
          <% else %>
            <div class="learn-next-list">
              <%= for {current, target} <- @learn_next do %>
                <div class="learn-next-row">
                  <span style="color: var(--ctp-blue);">{current}</span>
                  <span style="color: var(--ctp-overlay1);"> -> </span>
                  <span style="color: var(--ctp-green); font-weight: 700;">{target}</span>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
