defmodule PhoenixDashboardWeb.BlogPostLive do
  use PhoenixDashboardWeb, :live_view

  alias PhoenixDashboard.SurrealClient

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case SurrealClient.query("SELECT * FROM #{id}") do
      {:ok, [post | _]} ->
        tags = (post["tags"] || []) |> Enum.join(", ")

        {:ok,
         socket
         |> assign(
           page_title: "Edit: #{post["title"]}",
           post_id: id,
           status_msg: nil,
           form_data: %{
             "title" => post["title"] || "",
             "slug" => post["slug"] || "",
             "content" => post["content"] || "",
             "tags" => tags,
             "draft" => to_string(post["draft"] || false),
             "_date" => Date.utc_today() |> Date.to_string()
           }
         )}

      _ ->
        {:ok,
         socket
         |> assign(
           page_title: "Post Not Found",
           post_id: id,
           status_msg: {:error, "Post not found."},
           form_data: %{
             "title" => "",
             "slug" => "",
             "content" => "",
             "tags" => "",
             "draft" => "true",
             "_date" => Date.utc_today() |> Date.to_string()
           }
         )}
    end
  end

  defp slugify(title, date) do
    slug =
      title
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9\s-]/, "")
      |> String.replace(~r/\s+/, "-")
      |> String.replace(~r/-+/, "-")
      |> String.trim("-")

    if slug == "", do: "", else: "#{slug}-#{date}"
  end

  @impl true
  def handle_event("update-form", %{"field" => field, "value" => value}, socket) do
    form = Map.put(socket.assigns.form_data, field, value)

    form =
      if field == "title" do
        date = form["_date"] || Date.utc_today() |> Date.to_string()
        Map.put(form, "slug", slugify(value, date))
      else
        form
      end

    {:noreply, assign(socket, form_data: form)}
  end

  def handle_event("toggle-draft", _params, socket) do
    current = socket.assigns.form_data["draft"]
    new_val = if current == "true", do: "false", else: "true"
    {:noreply, assign(socket, form_data: Map.put(socket.assigns.form_data, "draft", new_val))}
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
      "slug" => String.trim(form["slug"] || ""),
      "content" => String.trim(form["content"] || ""),
      "tags" => tags,
      "draft" => form["draft"] == "true"
    }

    if data["title"] == "" do
      {:noreply, assign(socket, status_msg: {:error, "Title is required."})}
    else
      case SurrealClient.update(socket.assigns.post_id, data) do
        {:ok, _} ->
          {:noreply, assign(socket, status_msg: {:info, "Post saved."})}

        {:error, reason} ->
          {:noreply, assign(socket, status_msg: {:error, "Save failed: #{inspect(reason)}"})}
      end
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
          <span class="prompt-cmd">nvim blog/{@form_data["slug"] || "untitled"}.md</span>
        </p>

          <%= if @status_msg do %>
            <div class={status_class(@status_msg)}>
              <span class="prompt-symbol">&gt;</span> {elem(@status_msg, 1)}
            </div>
          <% end %>

          <div style="display: flex; flex-direction: column; gap: 0.4rem; margin-top: 0.75rem;">
            <div class="form-row">
              <label class="form-label">title ~</label>
              <input type="text" class="terminal-input inline-input" value={@form_data["title"]}
                phx-keyup="update-form" phx-value-field="title" placeholder="Post title" />
            </div>
            <div class="form-row">
              <label class="form-label">slug ~</label>
              <input type="text" class="terminal-input inline-input" value={@form_data["slug"]}
                phx-keyup="update-form" phx-value-field="slug" placeholder="auto-generated-from-title" />
            </div>
            <div class="form-row">
              <label class="form-label">tags ~</label>
              <input type="text" class="terminal-input inline-input" value={@form_data["tags"]}
                phx-keyup="update-form" phx-value-field="tags" placeholder="rust, blog, tutorial" />
            </div>
            <div class="form-row">
              <label class="form-label">draft ~</label>
              <button phx-click="toggle-draft" class="terminal-btn checkbox-btn" type="button">
                {if @form_data["draft"] == "true", do: "[x] draft", else: "[ ] published"}
              </button>
            </div>
            <div class="form-row" style="align-items: flex-start;">
              <label class="form-label" style="margin-top: 0.25rem;">content ~</label>
              <textarea class="terminal-input inline-input"
                phx-keyup="update-form" phx-value-field="content"
                placeholder="Write your markdown here..."
                style="min-height: 500px; font-family: 'JetBrains Mono', monospace; resize: vertical; width: 100%;"
              >{@form_data["content"]}</textarea>
            </div>
            <div class="form-actions">
              <button phx-click="save" class="terminal-btn save-btn"><span class="prompt-symbol">&gt;</span> save</button>
              <.link navigate={~p"/content/blog"} class="terminal-btn cancel-btn"><span class="prompt-symbol">&gt;</span> back to list</.link>
            </div>

            <%= if @form_data["content"] && @form_data["content"] != "" do %>
              <div style="margin-top: 0.5rem; padding: 0.75rem; background: var(--ctp-crust); border: 1px solid var(--ctp-surface0); border-radius: 4px;">
                <div style="color: var(--ctp-overlay1); font-size: 0.7rem; margin-bottom: 0.5rem;">PREVIEW (raw markdown)</div>
                <pre style="white-space: pre-wrap; font-size: 0.8rem; color: var(--ctp-subtext1); font-family: 'JetBrains Mono', monospace;">{@form_data["content"]}</pre>
              </div>
            <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp status_class({:info, _}), do: "status-message status-info"
  defp status_class({:error, _}), do: "status-message status-error"
end
