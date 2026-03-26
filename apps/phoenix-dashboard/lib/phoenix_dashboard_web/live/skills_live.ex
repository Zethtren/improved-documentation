defmodule PhoenixDashboardWeb.SkillsLive do
  use PhoenixDashboardWeb, :live_view

  alias PhoenixDashboard.SurrealClient

  @default_categories ["language", "infra", "tool", "ml"]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Skills")
     |> assign(editing: nil, adding: false, status_msg: nil)
     |> assign(form_data: %{}, custom_category: false)
     |> fetch_skills()
     |> load_categories()}
  end

  defp fetch_skills(socket) do
    case SurrealClient.query("SELECT * FROM skill ORDER BY proficiency DESC") do
      {:ok, skills} when is_list(skills) ->
        assign(socket, skills: skills)

      _ ->
        assign(socket, skills: [])
    end
  end

  defp load_categories(socket) do
    # Merge default categories with any found in existing skills
    existing =
      socket.assigns.skills
      |> Enum.map(& &1["category"])
      |> Enum.filter(& &1)
      |> Enum.uniq()

    all = Enum.uniq(@default_categories ++ existing) |> Enum.sort()
    assign(socket, categories: all)
  end

  defp blank_form do
    %{
      "name" => "",
      "category" => "language",
      "proficiency" => "50",
      "hours" => "0",
      "years" => "0",
      "description" => ""
    }
  end

  defp form_from_skill(skill) do
    %{
      "name" => skill["name"] || "",
      "category" => skill["category"] || "language",
      "proficiency" => to_string(skill["proficiency"] || 50),
      "hours" => to_string(skill["hours"] || 0),
      "years" => to_string(skill["years"] || 0),
      "description" => skill["description"] || ""
    }
  end

  @impl true
  def handle_event("add", _params, socket) do
    {:noreply,
     assign(socket,
       adding: true,
       editing: nil,
       custom_category: false,
       form_data: blank_form()
     )}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    skill = Enum.find(socket.assigns.skills, &(&1["id"] == id))

    {:noreply,
     assign(socket,
       editing: id,
       adding: false,
       custom_category: false,
       form_data: form_from_skill(skill)
     )}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, assign(socket, editing: nil, adding: false, form_data: %{}, custom_category: false)}
  end

  def handle_event("update-form", %{"field" => field, "value" => value}, socket) do
    form = Map.put(socket.assigns.form_data, field, value)

    # If category is set to "__new__", toggle custom category input
    custom = if field == "category" and value == "__new__", do: true, else: socket.assigns.custom_category
    custom = if field == "category" and value != "__new__", do: false, else: custom

    {:noreply, assign(socket, form_data: form, custom_category: custom)}
  end

  def handle_event("save", _params, socket) do
    form = socket.assigns.form_data

    category = String.trim(form["category"] || "")

    data = %{
      "name" => String.trim(form["name"] || ""),
      "category" => category,
      "proficiency" => parse_int(form["proficiency"]),
      "hours" => parse_float(form["hours"]),
      "years" => parse_float(form["years"]),
      "description" => String.trim(form["description"] || "")
    }

    if data["name"] == "" do
      {:noreply, assign(socket, status_msg: {:error, "Name is required."})}
    else
      if socket.assigns.adding do
        case SurrealClient.create("skill", data) do
          {:ok, _} ->
            {:noreply,
             socket
             |> assign(adding: false, form_data: %{}, custom_category: false)
             |> assign(status_msg: {:info, "Skill created."})
             |> fetch_skills()
             |> load_categories()}

          {:error, reason} ->
            {:noreply, assign(socket, status_msg: {:error, "Create failed: #{inspect(reason)}"})}
        end
      else
        id = socket.assigns.editing

        case SurrealClient.update(id, data) do
          {:ok, _} ->
            {:noreply,
             socket
             |> assign(editing: nil, form_data: %{}, custom_category: false)
             |> assign(status_msg: {:info, "Skill updated."})
             |> fetch_skills()
             |> load_categories()}

          {:error, reason} ->
            {:noreply, assign(socket, status_msg: {:error, "Update failed: #{inspect(reason)}"})}
        end
      end
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    case SurrealClient.delete(id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(status_msg: {:info, "Skill deleted."})
         |> fetch_skills()
         |> load_categories()}

      {:error, reason} ->
        {:noreply, assign(socket, status_msg: {:error, "Delete failed: #{inspect(reason)}"})}
    end
  end

  defp parse_int(val) when is_binary(val) do
    case Integer.parse(String.trim(val)) do
      {n, _} -> n
      :error -> 0
    end
  end

  defp parse_int(val) when is_integer(val), do: val
  defp parse_int(_), do: 0

  defp parse_float(val) when is_binary(val) do
    trimmed = String.trim(val)

    case Float.parse(trimmed) do
      {n, _} -> n
      :error ->
        case Integer.parse(trimmed) do
          {n, _} -> n * 1.0
          :error -> 0.0
        end
    end
  end

  defp parse_float(val) when is_float(val), do: val
  defp parse_float(val) when is_integer(val), do: val * 1.0
  defp parse_float(_), do: 0.0

  @impl true
  def render(assigns) do
    ~H"""
    <div class="dashboard">
      <div class="terminal-body">
        <p class="prompt-line">
          <span class="prompt-user">admin</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
          <span class="prompt-sep">~</span>
          <span class="prompt-cmd">eza -l --icons ~/.skills/</span>
        </p>

        <%= if @status_msg do %>
          <div class={status_class(@status_msg)}>
            <span class="prompt-symbol">&gt;</span> {elem(@status_msg, 1)}
          </div>
        <% end %>

        <div class="crud-actions">
          <button phx-click="add" class="terminal-btn add-btn" disabled={@adding}>
            <span class="prompt-symbol">&gt;</span> add skill
          </button>
        </div>

          <%= if @adding or @editing do %>
            <div class="skill-form terminal-window" style="margin: 0.5rem 0;">
              <div class="terminal-titlebar">
                <span class="terminal-dot red"></span>
                <span class="terminal-dot yellow"></span>
                <span class="terminal-dot green"></span>
                <span class="titlebar-text"><%= if @adding, do: "new skill", else: "edit skill" %></span>
              </div>
              <div class="terminal-body" style="display: flex; flex-direction: column; gap: 0.4rem;">
                <div class="form-row">
                  <label class="form-label">name ~</label>
                  <input type="text" class="terminal-input inline-input" value={@form_data["name"]}
                    phx-keyup="update-form" phx-value-field="name" placeholder="e.g. Python" />
                </div>
                <div class="form-row">
                  <label class="form-label">category ~</label>
                  <input type="text" class="terminal-input inline-input" value={@form_data["category"]}
                    phx-keyup="update-form" phx-value-field="category" placeholder="type or pick below"
                    list="category-options" />
                  <datalist id="category-options">
                    <%= for cat <- @categories do %>
                      <option value={cat} />
                    <% end %>
                  </datalist>
                </div>
                <div class="form-row">
                  <label class="form-label">proficiency ~</label>
                  <input type="number" class="terminal-input inline-input" value={@form_data["proficiency"]}
                    phx-keyup="update-form" phx-value-field="proficiency" placeholder="0-100" min="1" max="100" />
                </div>
                <div class="form-row">
                  <label class="form-label">hours ~</label>
                  <input type="number" class="terminal-input inline-input" value={@form_data["hours"]}
                    phx-keyup="update-form" phx-value-field="hours" placeholder="0" step="0.1" />
                </div>
                <div class="form-row">
                  <label class="form-label">years ~</label>
                  <input type="number" class="terminal-input inline-input" value={@form_data["years"]}
                    phx-keyup="update-form" phx-value-field="years" placeholder="0" step="0.1" />
                </div>
                <div class="form-row">
                  <label class="form-label">description ~</label>
                  <input type="text" class="terminal-input inline-input" value={@form_data["description"]}
                    phx-keyup="update-form" phx-value-field="description" placeholder="short description" />
                </div>
                <div class="form-actions">
                  <button phx-click="save" class="terminal-btn save-btn"><span class="prompt-symbol">&gt;</span> save</button>
                  <button phx-click="cancel" class="terminal-btn cancel-btn"><span class="prompt-symbol">&gt;</span> cancel</button>
                </div>
              </div>
            </div>
          <% end %>

          <table class="terminal-table">
            <thead>
              <tr>
                <th>name</th>
                <th>category</th>
                <th>prof.</th>
                <th>hours</th>
                <th>years</th>
                <th>description</th>
                <th>actions</th>
              </tr>
            </thead>
            <tbody>
              <%= for skill <- @skills do %>
                <tr>
                  <td style="color: var(--ctp-green); font-weight: 700;">{skill["name"]}</td>
                  <td style="color: var(--ctp-blue);">{skill["category"]}</td>
                  <td style="color: var(--ctp-yellow);">{skill["proficiency"]}</td>
                  <td>{skill["hours"] || 0}</td>
                  <td>{skill["years"] || 0}</td>
                  <td style="color: var(--ctp-subtext0);">{skill["description"]}</td>
                  <td class="action-cell">
                    <button phx-click="edit" phx-value-id={skill["id"]} class="terminal-btn edit-btn">
                      <span class="prompt-symbol">&gt;</span> edit
                    </button>
                    <button phx-click="delete" phx-value-id={skill["id"]} class="terminal-btn delete-btn"
                      data-confirm="Delete this skill?">
                      <span class="prompt-symbol">&gt;</span> delete
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>

        <%= if @skills == [] and not @adding do %>
          <p class="hint-text">-- no skills found --</p>
        <% end %>
      </div>
    </div>
    """
  end

  defp status_class({:info, _}), do: "status-message status-info"
  defp status_class({:error, _}), do: "status-message status-error"
end
