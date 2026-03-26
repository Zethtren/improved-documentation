defmodule PhoenixDashboardWeb.SkillsLive do
  use PhoenixDashboardWeb, :live_view

  alias PhoenixDashboard.SurrealClient

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Skills")
     |> assign(editing: nil, adding: false, status_msg: nil)
     |> assign(form_data: %{})
     |> fetch_skills()}
  end

  defp fetch_skills(socket) do
    case SurrealClient.query("SELECT * FROM skill ORDER BY proficiency DESC") do
      {:ok, skills} when is_list(skills) ->
        assign(socket, skills: skills)

      {:ok, _} ->
        assign(socket, skills: [])

      {:error, reason} ->
        socket
        |> assign(skills: [])
        |> assign(status_msg: {:error, "Failed to fetch skills: #{inspect(reason)}"})
    end
  end

  @impl true
  def handle_event("add", _params, socket) do
    {:noreply,
     assign(socket,
       adding: true,
       editing: nil,
       form_data: %{
         "name" => "",
         "category" => "",
         "proficiency" => "",
         "description" => ""
       }
     )}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    skill = Enum.find(socket.assigns.skills, &(&1["id"] == id))

    {:noreply,
     assign(socket,
       editing: id,
       adding: false,
       form_data: %{
         "name" => skill["name"] || "",
         "category" => skill["category"] || "",
         "proficiency" => to_string(skill["proficiency"] || ""),
         "description" => skill["description"] || ""
       }
     )}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, assign(socket, editing: nil, adding: false, form_data: %{})}
  end

  def handle_event("update-form", %{"field" => field, "value" => value}, socket) do
    {:noreply, assign(socket, form_data: Map.put(socket.assigns.form_data, field, value))}
  end

  def handle_event("save", _params, socket) do
    form = socket.assigns.form_data

    data = %{
      "name" => String.trim(form["name"] || ""),
      "category" => String.trim(form["category"] || ""),
      "proficiency" => parse_int(form["proficiency"]),
      "description" => String.trim(form["description"] || "")
    }

    if socket.assigns.adding do
      case SurrealClient.create("skill", data) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(adding: false, form_data: %{}, status_msg: {:info, "Skill created."})
           |> fetch_skills()}

        {:error, reason} ->
          {:noreply, assign(socket, status_msg: {:error, "Create failed: #{inspect(reason)}"})}
      end
    else
      id = socket.assigns.editing

      case SurrealClient.update(id, data) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(editing: nil, form_data: %{}, status_msg: {:info, "Skill updated."})
           |> fetch_skills()}

        {:error, reason} ->
          {:noreply, assign(socket, status_msg: {:error, "Update failed: #{inspect(reason)}"})}
      end
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    case SurrealClient.delete(id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(status_msg: {:info, "Skill deleted."})
         |> fetch_skills()}

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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="dashboard">
      <div class="terminal-window">
        <div class="terminal-titlebar">
          <span class="terminal-dot red"></span>
          <span class="terminal-dot yellow"></span>
          <span class="terminal-dot green"></span>
          <span class="titlebar-text">houston-cv :: skills</span>
        </div>
        <div class="terminal-body">
          <p class="prompt-line">
            <span class="prompt-user">admin</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
            <span class="prompt-sep">~</span>
            <span class="prompt-cmd">ls skills/</span>
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

          <table class="terminal-table">
            <thead>
              <tr>
                <th>name</th>
                <th>category</th>
                <th>proficiency</th>
                <th>description</th>
                <th>actions</th>
              </tr>
            </thead>
            <tbody>
              <%= if @adding do %>
                <tr class="editing-row">
                  <td>
                    <input type="text" class="terminal-input inline-input" value={@form_data["name"]}
                      phx-keyup="update-form" phx-value-field="name" placeholder="name" />
                  </td>
                  <td>
                    <input type="text" class="terminal-input inline-input" value={@form_data["category"]}
                      phx-keyup="update-form" phx-value-field="category" placeholder="category" />
                  </td>
                  <td>
                    <input type="number" class="terminal-input inline-input" value={@form_data["proficiency"]}
                      phx-keyup="update-form" phx-value-field="proficiency" placeholder="0-100" />
                  </td>
                  <td>
                    <input type="text" class="terminal-input inline-input" value={@form_data["description"]}
                      phx-keyup="update-form" phx-value-field="description" placeholder="description" />
                  </td>
                  <td class="action-cell">
                    <button phx-click="save" class="terminal-btn save-btn"><span class="prompt-symbol">&gt;</span> save</button>
                    <button phx-click="cancel" class="terminal-btn cancel-btn"><span class="prompt-symbol">&gt;</span> cancel</button>
                  </td>
                </tr>
              <% end %>
              <%= for skill <- @skills do %>
                <%= if @editing == skill["id"] do %>
                  <tr class="editing-row">
                    <td>
                      <input type="text" class="terminal-input inline-input" value={@form_data["name"]}
                        phx-keyup="update-form" phx-value-field="name" />
                    </td>
                    <td>
                      <input type="text" class="terminal-input inline-input" value={@form_data["category"]}
                        phx-keyup="update-form" phx-value-field="category" />
                    </td>
                    <td>
                      <input type="number" class="terminal-input inline-input" value={@form_data["proficiency"]}
                        phx-keyup="update-form" phx-value-field="proficiency" />
                    </td>
                    <td>
                      <input type="text" class="terminal-input inline-input" value={@form_data["description"]}
                        phx-keyup="update-form" phx-value-field="description" />
                    </td>
                    <td class="action-cell">
                      <button phx-click="save" class="terminal-btn save-btn"><span class="prompt-symbol">&gt;</span> save</button>
                      <button phx-click="cancel" class="terminal-btn cancel-btn"><span class="prompt-symbol">&gt;</span> cancel</button>
                    </td>
                  </tr>
                <% else %>
                  <tr>
                    <td>{skill["name"]}</td>
                    <td>{skill["category"]}</td>
                    <td>{skill["proficiency"]}</td>
                    <td>{skill["description"]}</td>
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
              <% end %>
            </tbody>
          </table>

          <%= if @skills == [] and not @adding do %>
            <p class="hint-text">-- no skills found --</p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp status_class({:info, _}), do: "status-message status-info"
  defp status_class({:error, _}), do: "status-message status-error"
end
