defmodule PhoenixDashboardWeb.ProjectsLive do
  use PhoenixDashboardWeb, :live_view

  alias PhoenixDashboard.SurrealClient

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Projects")
     |> assign(editing: nil, adding: false, status_msg: nil)
     |> assign(form_data: %{})
     |> fetch_projects()}
  end

  defp fetch_projects(socket) do
    case SurrealClient.query("SELECT * FROM project ORDER BY sort_order ASC") do
      {:ok, projects} when is_list(projects) ->
        assign(socket, projects: projects)

      {:ok, _} ->
        assign(socket, projects: [])

      {:error, reason} ->
        socket
        |> assign(projects: [])
        |> assign(status_msg: {:error, "Failed to fetch projects: #{inspect(reason)}"})
    end
  end

  @impl true
  def handle_event("add", _params, socket) do
    {:noreply,
     assign(socket,
       adding: true,
       editing: nil,
       form_data: %{
         "title" => "",
         "description" => "",
         "tags" => "",
         "source_url" => "",
         "status" => "",
         "visible" => "true",
         "sort_order" => "0"
       }
     )}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    project = Enum.find(socket.assigns.projects, &(&1["id"] == id))
    tags = (project["tags"] || []) |> Enum.join(", ")

    {:noreply,
     assign(socket,
       editing: id,
       adding: false,
       form_data: %{
         "title" => project["title"] || "",
         "description" => project["description"] || "",
         "tags" => tags,
         "source_url" => project["source_url"] || "",
         "status" => project["status"] || "",
         "visible" => to_string(project["visible"] || true),
         "sort_order" => to_string(project["sort_order"] || 0)
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

    tags =
      (form["tags"] || "")
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    data = %{
      "title" => String.trim(form["title"] || ""),
      "description" => String.trim(form["description"] || ""),
      "tags" => tags,
      "source_url" => String.trim(form["source_url"] || ""),
      "status" => String.trim(form["status"] || ""),
      "visible" => form["visible"] == "true",
      "sort_order" => parse_int(form["sort_order"])
    }

    if socket.assigns.adding do
      case SurrealClient.create("project", data) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(adding: false, form_data: %{}, status_msg: {:info, "Project created."})
           |> fetch_projects()}

        {:error, reason} ->
          {:noreply, assign(socket, status_msg: {:error, "Create failed: #{inspect(reason)}"})}
      end
    else
      id = socket.assigns.editing

      case SurrealClient.update(id, data) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(editing: nil, form_data: %{}, status_msg: {:info, "Project updated."})
           |> fetch_projects()}

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
         |> assign(status_msg: {:info, "Project deleted."})
         |> fetch_projects()}

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

  defp format_tags(nil), do: ""
  defp format_tags(tags) when is_list(tags), do: Enum.map_join(tags, " ", &"[#{&1}]")
  defp format_tags(_), do: ""

  @impl true
  def render(assigns) do
    ~H"""
    <div class="dashboard">
      <div class="terminal-window">
        <div class="terminal-titlebar">
          <span class="terminal-dot red"></span>
          <span class="terminal-dot yellow"></span>
          <span class="terminal-dot green"></span>
          <span class="titlebar-text">houston-cv :: projects</span>
        </div>
        <div class="terminal-body">
          <p class="prompt-line">
            <span class="prompt-user">admin</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
            <span class="prompt-sep">~</span>
            <span class="prompt-cmd">ls projects/</span>
          </p>

          <%= if @status_msg do %>
            <div class={status_class(@status_msg)}>
              <span class="prompt-symbol">&gt;</span> {elem(@status_msg, 1)}
            </div>
          <% end %>

          <div class="crud-actions">
            <button phx-click="add" class="terminal-btn add-btn" disabled={@adding}>
              <span class="prompt-symbol">&gt;</span> add project
            </button>
          </div>

          <table class="terminal-table">
            <thead>
              <tr>
                <th>title</th>
                <th>description</th>
                <th>tags</th>
                <th>source_url</th>
                <th>status</th>
                <th>visible</th>
                <th>sort</th>
                <th>actions</th>
              </tr>
            </thead>
            <tbody>
              <%= if @adding do %>
                <tr class="editing-row">
                  <td>
                    <input type="text" class="terminal-input inline-input" value={@form_data["title"]}
                      phx-keyup="update-form" phx-value-field="title" placeholder="title" />
                  </td>
                  <td>
                    <input type="text" class="terminal-input inline-input" value={@form_data["description"]}
                      phx-keyup="update-form" phx-value-field="description" placeholder="description" />
                  </td>
                  <td>
                    <input type="text" class="terminal-input inline-input" value={@form_data["tags"]}
                      phx-keyup="update-form" phx-value-field="tags" placeholder="tag1, tag2" />
                  </td>
                  <td>
                    <input type="text" class="terminal-input inline-input" value={@form_data["source_url"]}
                      phx-keyup="update-form" phx-value-field="source_url" placeholder="https://..." />
                  </td>
                  <td>
                    <input type="text" class="terminal-input inline-input" value={@form_data["status"]}
                      phx-keyup="update-form" phx-value-field="status" placeholder="active" />
                  </td>
                  <td>
                    <select class="terminal-input inline-input" phx-change="update-form" phx-value-field="visible" name="visible">
                      <option value="true" selected={@form_data["visible"] == "true"}>true</option>
                      <option value="false" selected={@form_data["visible"] == "false"}>false</option>
                    </select>
                  </td>
                  <td>
                    <input type="number" class="terminal-input inline-input" value={@form_data["sort_order"]}
                      phx-keyup="update-form" phx-value-field="sort_order" placeholder="0" />
                  </td>
                  <td class="action-cell">
                    <button phx-click="save" class="terminal-btn save-btn"><span class="prompt-symbol">&gt;</span> save</button>
                    <button phx-click="cancel" class="terminal-btn cancel-btn"><span class="prompt-symbol">&gt;</span> cancel</button>
                  </td>
                </tr>
              <% end %>
              <%= for project <- @projects do %>
                <%= if @editing == project["id"] do %>
                  <tr class="editing-row">
                    <td>
                      <input type="text" class="terminal-input inline-input" value={@form_data["title"]}
                        phx-keyup="update-form" phx-value-field="title" />
                    </td>
                    <td>
                      <input type="text" class="terminal-input inline-input" value={@form_data["description"]}
                        phx-keyup="update-form" phx-value-field="description" />
                    </td>
                    <td>
                      <input type="text" class="terminal-input inline-input" value={@form_data["tags"]}
                        phx-keyup="update-form" phx-value-field="tags" />
                    </td>
                    <td>
                      <input type="text" class="terminal-input inline-input" value={@form_data["source_url"]}
                        phx-keyup="update-form" phx-value-field="source_url" />
                    </td>
                    <td>
                      <input type="text" class="terminal-input inline-input" value={@form_data["status"]}
                        phx-keyup="update-form" phx-value-field="status" />
                    </td>
                    <td>
                      <select class="terminal-input inline-input" phx-change="update-form" phx-value-field="visible" name="visible">
                        <option value="true" selected={@form_data["visible"] == "true"}>true</option>
                        <option value="false" selected={@form_data["visible"] == "false"}>false</option>
                      </select>
                    </td>
                    <td>
                      <input type="number" class="terminal-input inline-input" value={@form_data["sort_order"]}
                        phx-keyup="update-form" phx-value-field="sort_order" />
                    </td>
                    <td class="action-cell">
                      <button phx-click="save" class="terminal-btn save-btn"><span class="prompt-symbol">&gt;</span> save</button>
                      <button phx-click="cancel" class="terminal-btn cancel-btn"><span class="prompt-symbol">&gt;</span> cancel</button>
                    </td>
                  </tr>
                <% else %>
                  <tr>
                    <td>{project["title"]}</td>
                    <td class="cell-truncate">{project["description"]}</td>
                    <td class="tags-cell">{format_tags(project["tags"])}</td>
                    <td class="cell-truncate">{project["source_url"]}</td>
                    <td>{project["status"]}</td>
                    <td>{to_string(project["visible"])}</td>
                    <td>{project["sort_order"]}</td>
                    <td class="action-cell">
                      <button phx-click="edit" phx-value-id={project["id"]} class="terminal-btn edit-btn">
                        <span class="prompt-symbol">&gt;</span> edit
                      </button>
                      <button phx-click="delete" phx-value-id={project["id"]} class="terminal-btn delete-btn"
                        data-confirm="Delete this project?">
                        <span class="prompt-symbol">&gt;</span> delete
                      </button>
                    </td>
                  </tr>
                <% end %>
              <% end %>
            </tbody>
          </table>

          <%= if @projects == [] and not @adding do %>
            <p class="hint-text">-- no projects found --</p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp status_class({:info, _}), do: "status-message status-info"
  defp status_class({:error, _}), do: "status-message status-error"
end
