defmodule PhoenixDashboardWeb.ExperienceLive do
  use PhoenixDashboardWeb, :live_view

  alias PhoenixDashboard.SurrealClient

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Experience")
     |> assign(editing: nil, adding: false, status_msg: nil)
     |> assign(form_data: %{})
     |> fetch_experience()}
  end

  defp fetch_experience(socket) do
    case SurrealClient.query("SELECT * FROM experience ORDER BY start_date DESC") do
      {:ok, records} when is_list(records) ->
        assign(socket, records: records)

      {:ok, _} ->
        assign(socket, records: [])

      {:error, reason} ->
        socket
        |> assign(records: [])
        |> assign(status_msg: {:error, "Failed to fetch experience: #{inspect(reason)}"})
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
         "company" => "",
         "start_date" => "",
         "end_date" => "",
         "description" => "",
         "current" => "false"
       }
     )}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    record = Enum.find(socket.assigns.records, &(&1["id"] == id))

    {:noreply,
     assign(socket,
       editing: id,
       adding: false,
       form_data: %{
         "title" => record["title"] || "",
         "company" => record["company"] || "",
         "start_date" => record["start_date"] || "",
         "end_date" => record["end_date"] || "",
         "description" => record["description"] || "",
         "current" => to_string(record["current"] || false)
       }
     )}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, assign(socket, editing: nil, adding: false, form_data: %{})}
  end

  def handle_event("update-form", %{"field" => field, "value" => value}, socket) do
    {:noreply, assign(socket, form_data: Map.put(socket.assigns.form_data, field, value))}
  end

  def handle_event("toggle-current", _params, socket) do
    current = socket.assigns.form_data["current"]
    new_val = if current == "true", do: "false", else: "true"
    {:noreply, assign(socket, form_data: Map.put(socket.assigns.form_data, "current", new_val))}
  end

  def handle_event("save", _params, socket) do
    form = socket.assigns.form_data

    data = %{
      "title" => String.trim(form["title"] || ""),
      "company" => String.trim(form["company"] || ""),
      "start_date" => String.trim(form["start_date"] || ""),
      "end_date" => String.trim(form["end_date"] || ""),
      "description" => String.trim(form["description"] || ""),
      "current" => form["current"] == "true"
    }

    if socket.assigns.adding do
      case SurrealClient.create("experience", data) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(adding: false, form_data: %{}, status_msg: {:info, "Experience created."})
           |> fetch_experience()}

        {:error, reason} ->
          {:noreply, assign(socket, status_msg: {:error, "Create failed: #{inspect(reason)}"})}
      end
    else
      id = socket.assigns.editing

      case SurrealClient.update(id, data) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(editing: nil, form_data: %{}, status_msg: {:info, "Experience updated."})
           |> fetch_experience()}

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
         |> assign(status_msg: {:info, "Experience deleted."})
         |> fetch_experience()}

      {:error, reason} ->
        {:noreply, assign(socket, status_msg: {:error, "Delete failed: #{inspect(reason)}"})}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="dashboard">
      <div class="terminal-window">
        <div class="terminal-titlebar">
          <span class="terminal-dot red"></span>
          <span class="terminal-dot yellow"></span>
          <span class="terminal-dot green"></span>
          <span class="titlebar-text">houston-cv :: experience</span>
        </div>
        <div class="terminal-body">
          <p class="prompt-line">
            <span class="prompt-user">admin</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
            <span class="prompt-sep">~</span>
            <span class="prompt-cmd">ls experience/</span>
          </p>

          <%= if @status_msg do %>
            <div class={status_class(@status_msg)}>
              <span class="prompt-symbol">&gt;</span> {elem(@status_msg, 1)}
            </div>
          <% end %>

          <div class="crud-actions">
            <button phx-click="add" class="terminal-btn add-btn" disabled={@adding}>
              <span class="prompt-symbol">&gt;</span> add experience
            </button>
          </div>

          <table class="terminal-table">
            <thead>
              <tr>
                <th>title</th>
                <th>company</th>
                <th>start_date</th>
                <th>end_date</th>
                <th>description</th>
                <th>current</th>
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
                    <input type="text" class="terminal-input inline-input" value={@form_data["company"]}
                      phx-keyup="update-form" phx-value-field="company" placeholder="company" />
                  </td>
                  <td>
                    <input type="text" class="terminal-input inline-input" value={@form_data["start_date"]}
                      phx-keyup="update-form" phx-value-field="start_date" placeholder="YYYY-MM-DD" />
                  </td>
                  <td>
                    <input type="text" class="terminal-input inline-input" value={@form_data["end_date"]}
                      phx-keyup="update-form" phx-value-field="end_date" placeholder="YYYY-MM-DD" />
                  </td>
                  <td>
                    <input type="text" class="terminal-input inline-input" value={@form_data["description"]}
                      phx-keyup="update-form" phx-value-field="description" placeholder="description" />
                  </td>
                  <td>
                    <button phx-click="toggle-current" class="terminal-btn checkbox-btn" type="button">
                      {if @form_data["current"] == "true", do: "[x]", else: "[ ]"}
                    </button>
                  </td>
                  <td class="action-cell">
                    <button phx-click="save" class="terminal-btn save-btn"><span class="prompt-symbol">&gt;</span> save</button>
                    <button phx-click="cancel" class="terminal-btn cancel-btn"><span class="prompt-symbol">&gt;</span> cancel</button>
                  </td>
                </tr>
              <% end %>
              <%= for record <- @records do %>
                <%= if @editing == record["id"] do %>
                  <tr class="editing-row">
                    <td>
                      <input type="text" class="terminal-input inline-input" value={@form_data["title"]}
                        phx-keyup="update-form" phx-value-field="title" />
                    </td>
                    <td>
                      <input type="text" class="terminal-input inline-input" value={@form_data["company"]}
                        phx-keyup="update-form" phx-value-field="company" />
                    </td>
                    <td>
                      <input type="text" class="terminal-input inline-input" value={@form_data["start_date"]}
                        phx-keyup="update-form" phx-value-field="start_date" />
                    </td>
                    <td>
                      <input type="text" class="terminal-input inline-input" value={@form_data["end_date"]}
                        phx-keyup="update-form" phx-value-field="end_date" />
                    </td>
                    <td>
                      <input type="text" class="terminal-input inline-input" value={@form_data["description"]}
                        phx-keyup="update-form" phx-value-field="description" />
                    </td>
                    <td>
                      <button phx-click="toggle-current" class="terminal-btn checkbox-btn" type="button">
                        {if @form_data["current"] == "true", do: "[x]", else: "[ ]"}
                      </button>
                    </td>
                    <td class="action-cell">
                      <button phx-click="save" class="terminal-btn save-btn"><span class="prompt-symbol">&gt;</span> save</button>
                      <button phx-click="cancel" class="terminal-btn cancel-btn"><span class="prompt-symbol">&gt;</span> cancel</button>
                    </td>
                  </tr>
                <% else %>
                  <tr>
                    <td>{record["title"]}</td>
                    <td>{record["company"]}</td>
                    <td>{record["start_date"]}</td>
                    <td>{record["end_date"]}</td>
                    <td class="cell-truncate">{record["description"]}</td>
                    <td>{if record["current"], do: "[x]", else: "[ ]"}</td>
                    <td class="action-cell">
                      <button phx-click="edit" phx-value-id={record["id"]} class="terminal-btn edit-btn">
                        <span class="prompt-symbol">&gt;</span> edit
                      </button>
                      <button phx-click="delete" phx-value-id={record["id"]} class="terminal-btn delete-btn"
                        data-confirm="Delete this experience?">
                        <span class="prompt-symbol">&gt;</span> delete
                      </button>
                    </td>
                  </tr>
                <% end %>
              <% end %>
            </tbody>
          </table>

          <%= if @records == [] and not @adding do %>
            <p class="hint-text">-- no experience records found --</p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp status_class({:info, _}), do: "status-message status-info"
  defp status_class({:error, _}), do: "status-message status-error"
end
