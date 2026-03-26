defmodule PhoenixDashboardWeb.CertificationsLive do
  use PhoenixDashboardWeb, :live_view

  alias PhoenixDashboard.SurrealClient

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Certifications")
     |> assign(editing: nil, adding: false, status_msg: nil)
     |> assign(form_data: %{})
     |> fetch_certifications()}
  end

  defp fetch_certifications(socket) do
    case SurrealClient.query("SELECT * FROM certification ORDER BY date DESC") do
      {:ok, records} when is_list(records) ->
        assign(socket, records: records)

      {:ok, _} ->
        assign(socket, records: [])

      {:error, reason} ->
        socket
        |> assign(records: [])
        |> assign(status_msg: {:error, "Failed to fetch certifications: #{inspect(reason)}"})
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
         "issuer" => "",
         "date" => ""
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
         "issuer" => record["issuer"] || "",
         "date" => record["date"] || ""
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
      "title" => String.trim(form["title"] || ""),
      "issuer" => String.trim(form["issuer"] || ""),
      "date" => String.trim(form["date"] || "")
    }

    if socket.assigns.adding do
      case SurrealClient.create("certification", data) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(adding: false, form_data: %{}, status_msg: {:info, "Certification created."})
           |> fetch_certifications()}

        {:error, reason} ->
          {:noreply, assign(socket, status_msg: {:error, "Create failed: #{inspect(reason)}"})}
      end
    else
      id = socket.assigns.editing

      case SurrealClient.update(id, data) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(editing: nil, form_data: %{}, status_msg: {:info, "Certification updated."})
           |> fetch_certifications()}

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
         |> assign(status_msg: {:info, "Certification deleted."})
         |> fetch_certifications()}

      {:error, reason} ->
        {:noreply, assign(socket, status_msg: {:error, "Delete failed: #{inspect(reason)}"})}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="dashboard">
      <div class="terminal-body">
        <p class="prompt-line">
          <span class="prompt-user">admin</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
          <span class="prompt-sep">~</span>
          <span class="prompt-cmd">ls certifications/</span>
        </p>

          <%= if @status_msg do %>
            <div class={status_class(@status_msg)}>
              <span class="prompt-symbol">&gt;</span> {elem(@status_msg, 1)}
            </div>
          <% end %>

          <div class="crud-actions">
            <button phx-click="add" class="terminal-btn add-btn" disabled={@adding}>
              <span class="prompt-symbol">&gt;</span> add certification
            </button>
          </div>

          <table class="terminal-table">
            <thead>
              <tr>
                <th>title</th>
                <th>issuer</th>
                <th>date</th>
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
                    <input type="text" class="terminal-input inline-input" value={@form_data["issuer"]}
                      phx-keyup="update-form" phx-value-field="issuer" placeholder="issuer" />
                  </td>
                  <td>
                    <input type="text" class="terminal-input inline-input" value={@form_data["date"]}
                      phx-keyup="update-form" phx-value-field="date" placeholder="YYYY-MM-DD" />
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
                      <input type="text" class="terminal-input inline-input" value={@form_data["issuer"]}
                        phx-keyup="update-form" phx-value-field="issuer" />
                    </td>
                    <td>
                      <input type="text" class="terminal-input inline-input" value={@form_data["date"]}
                        phx-keyup="update-form" phx-value-field="date" />
                    </td>
                    <td class="action-cell">
                      <button phx-click="save" class="terminal-btn save-btn"><span class="prompt-symbol">&gt;</span> save</button>
                      <button phx-click="cancel" class="terminal-btn cancel-btn"><span class="prompt-symbol">&gt;</span> cancel</button>
                    </td>
                  </tr>
                <% else %>
                  <tr>
                    <td>{record["title"]}</td>
                    <td>{record["issuer"]}</td>
                    <td>{record["date"]}</td>
                    <td class="action-cell">
                      <button phx-click="edit" phx-value-id={record["id"]} class="terminal-btn edit-btn">
                        <span class="prompt-symbol">&gt;</span> edit
                      </button>
                      <button phx-click="delete" phx-value-id={record["id"]} class="terminal-btn delete-btn"
                        data-confirm="Delete this certification?">
                        <span class="prompt-symbol">&gt;</span> delete
                      </button>
                    </td>
                  </tr>
                <% end %>
              <% end %>
            </tbody>
          </table>

        <%= if @records == [] and not @adding do %>
          <p class="hint-text">-- no certifications found --</p>
        <% end %>
      </div>
    </div>
    """
  end

  defp status_class({:info, _}), do: "status-message status-info"
  defp status_class({:error, _}), do: "status-message status-error"
end
