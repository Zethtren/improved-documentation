defmodule PhoenixDashboardWeb.BlogLive do
  use PhoenixDashboardWeb, :live_view

  alias PhoenixDashboard.SurrealClient

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Blog")
     |> assign(editing: nil, adding: false, status_msg: nil)
     |> assign(form_data: %{})
     |> fetch_posts()
     |> fetch_recommendations()}
  end

  defp fetch_recommendations(socket) do
    case SurrealClient.query("SELECT * FROM recommended_link ORDER BY fetched_at DESC") do
      {:ok, recs} when is_list(recs) ->
        assign(socket, recommendations: recs)
      _ ->
        assign(socket, recommendations: [])
    end
  end

  defp fetch_posts(socket) do
    case SurrealClient.query("SELECT * FROM blog_post ORDER BY published DESC") do
      {:ok, posts} when is_list(posts) ->
        assign(socket, posts: posts)

      {:ok, _} ->
        assign(socket, posts: [])

      {:error, reason} ->
        socket
        |> assign(posts: [])
        |> assign(status_msg: {:error, "Failed to fetch posts: #{inspect(reason)}"})
    end
  end

  defp blank_form do
    today = Date.utc_today() |> Date.to_string()

    %{
      "title" => "",
      "slug" => "",
      "content" => "",
      "tags" => "",
      "draft" => "true",
      "_date" => today
    }
  end

  defp form_from_post(post) do
    tags = (post["tags"] || []) |> Enum.join(", ")

    %{
      "title" => post["title"] || "",
      "slug" => post["slug"] || "",
      "content" => post["content"] || "",
      "tags" => tags,
      "draft" => to_string(post["draft"] || false),
      "_date" => Date.utc_today() |> Date.to_string()
    }
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
  def handle_event("add", _params, socket) do
    {:noreply,
     assign(socket,
       adding: true,
       editing: nil,
       form_data: blank_form()
     )}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    post = Enum.find(socket.assigns.posts, &(&1["id"] == id))

    {:noreply,
     assign(socket,
       editing: id,
       adding: false,
       form_data: form_from_post(post)
     )}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, assign(socket, editing: nil, adding: false, form_data: %{})}
  end

  def handle_event("update-form", %{"field" => field, "value" => value}, socket) do
    form = Map.put(socket.assigns.form_data, field, value)

    # Auto-generate slug when title changes
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
      if socket.assigns.adding do
        case SurrealClient.create("blog_post", data) do
          {:ok, _} ->
            {:noreply,
             socket
             |> assign(adding: false, form_data: %{})
             |> assign(status_msg: {:info, "Post created."})
             |> fetch_posts()}

          {:error, reason} ->
            {:noreply, assign(socket, status_msg: {:error, "Create failed: #{inspect(reason)}"})}
        end
      else
        id = socket.assigns.editing

        case SurrealClient.update(id, data) do
          {:ok, _} ->
            {:noreply,
             socket
             |> assign(editing: nil, form_data: %{})
             |> assign(status_msg: {:info, "Post updated."})
             |> fetch_posts()}

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
         |> assign(status_msg: {:info, "Post deleted."})
         |> fetch_posts()}

      {:error, reason} ->
        {:noreply, assign(socket, status_msg: {:error, "Delete failed: #{inspect(reason)}"})}
    end
  end

  def handle_event("generate-recommendations", %{"id" => id}, socket) do
    post = Enum.find(socket.assigns.posts, &(&1["id"] == id))

    if post do
      pid = self()
      Task.start(fn ->
        PhoenixDashboard.EmbeddingPipeline.embed_blog_post(id, post["content"] || "")
        result = PhoenixDashboard.EmbeddingPipeline.generate_recommendations(id, post["content"] || "")
        send(pid, {:recommendations_done, result})
      end)

      {:noreply, assign(socket, status_msg: {:info, "AI recommendations generating..."})}
    else
      {:noreply, assign(socket, status_msg: {:error, "Post not found"})}
    end
  end

  def handle_info({:recommendations_done, {:ok, count}}, socket) do
    {:noreply,
     socket
     |> assign(status_msg: {:info, "Generated #{count} recommendations."})
     |> fetch_recommendations()}
  end

  def handle_info({:recommendations_done, {:error, reason}}, socket) do
    {:noreply, assign(socket, status_msg: {:error, "Recommendation failed: #{inspect(reason)}"})}
  end

  def handle_info({:recommendations_done, _}, socket) do
    {:noreply, socket}
  end

  defp format_tags(nil), do: ""
  defp format_tags(tags) when is_list(tags), do: Enum.map_join(tags, " ", &"[#{&1}]")
  defp format_tags(_), do: ""

  defp format_date(nil), do: "--"

  defp format_date(dt) when is_binary(dt) do
    case DateTime.from_iso8601(dt) do
      {:ok, datetime, _} -> Calendar.strftime(datetime, "%Y-%m-%d")
      _ -> dt
    end
  end

  defp format_date(_), do: "--"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="dashboard">
      <div class="terminal-body">
        <p class="prompt-line">
          <span class="prompt-user">admin</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
          <span class="prompt-sep">~</span>
          <span class="prompt-cmd">ls blog/</span>
        </p>

          <%= if @status_msg do %>
            <div class={status_class(@status_msg)}>
              <span class="prompt-symbol">&gt;</span> {elem(@status_msg, 1)}
            </div>
          <% end %>

          <div class="crud-actions">
            <button phx-click="add" class="terminal-btn add-btn" disabled={@adding}>
              <span class="prompt-symbol">&gt;</span> add post
            </button>
          </div>

          <%= if @adding or @editing do %>
            <div class="skill-form terminal-window" style="margin: 0.5rem 0;">
              <div class="terminal-titlebar">
                <span class="terminal-dot red"></span>
                <span class="terminal-dot yellow"></span>
                <span class="terminal-dot green"></span>
                <span class="titlebar-text"><%= if @adding, do: "new post", else: "edit post" %></span>
              </div>
              <div class="terminal-body" style="display: flex; flex-direction: column; gap: 0.4rem;">
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
                <div class="form-row" style="align-items: flex-start;">
                  <label class="form-label" style="margin-top: 0.25rem;">content ~</label>
                  <textarea class="terminal-input inline-input"
                    phx-keyup="update-form" phx-value-field="content"
                    placeholder="Write your markdown here..."
                    style="min-height: 200px; font-family: 'JetBrains Mono', monospace; resize: vertical;"
                  >{@form_data["content"]}</textarea>
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
                <div class="form-actions">
                  <button phx-click="save" class="terminal-btn save-btn"><span class="prompt-symbol">&gt;</span> save</button>
                  <button phx-click="cancel" class="terminal-btn cancel-btn"><span class="prompt-symbol">&gt;</span> cancel</button>
                  <%= if @editing do %>
                    <.link navigate={~p"/content/blog/#{@editing}/edit"} class="terminal-btn edit-btn">
                      <span class="prompt-symbol">&gt;</span> full editor
                    </.link>
                  <% end %>
                </div>

                <%= if @form_data["content"] && @form_data["content"] != "" do %>
                  <div style="margin-top: 0.5rem; padding: 0.75rem; background: var(--ctp-crust); border: 1px solid var(--ctp-surface0); border-radius: 4px;">
                    <div style="color: var(--ctp-overlay1); font-size: 0.7rem; margin-bottom: 0.5rem;">PREVIEW (raw markdown)</div>
                    <pre style="white-space: pre-wrap; font-size: 0.8rem; color: var(--ctp-subtext1); font-family: 'JetBrains Mono', monospace;">{@form_data["content"]}</pre>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>

          <table class="terminal-table">
            <thead>
              <tr>
                <th>title</th>
                <th>slug</th>
                <th>published</th>
                <th>draft</th>
                <th>tags</th>
                <th>actions</th>
              </tr>
            </thead>
            <tbody>
              <%= for post <- @posts do %>
                <tr>
                  <td style="color: var(--ctp-green); font-weight: 700;">{post["title"]}</td>
                  <td style="color: var(--ctp-blue);">{post["slug"]}</td>
                  <td style="color: var(--ctp-subtext0);">{format_date(post["published"])}</td>
                  <td>{if post["draft"], do: "[x] draft", else: "[ ] live"}</td>
                  <td class="tags-cell">{format_tags(post["tags"])}</td>
                  <td class="action-cell">
                    <button phx-click="edit" phx-value-id={post["id"]} class="terminal-btn edit-btn">
                      <span class="prompt-symbol">&gt;</span> edit
                    </button>
                    <.link navigate={~p"/content/blog/#{post["id"]}/edit"} class="terminal-btn edit-btn">
                      <span class="prompt-symbol">&gt;</span> full editor
                    </.link>
                    <button phx-click="generate-recommendations" phx-value-id={post["id"]} class="terminal-btn ai-btn">
                      <span class="prompt-symbol">&gt;</span> ai recommend
                    </button>
                    <button phx-click="delete" phx-value-id={post["id"]} class="terminal-btn delete-btn"
                      data-confirm="Delete this post?">
                      <span class="prompt-symbol">&gt;</span> delete
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>

        <%= if @posts == [] and not @adding do %>
          <p class="hint-text">-- no blog posts found --</p>
        <% end %>

        <%= if @recommendations != [] do %>
          <div style="margin-top: 1.5rem; border-top: 1px dashed var(--ctp-surface1); padding-top: 1rem;">
            <p class="prompt-line">
              <span class="prompt-user">admin</span><span class="prompt-at">@</span><span class="prompt-host">houston</span>
              <span class="prompt-sep">~</span>
              <span class="prompt-cmd">cat recommendations.log</span>
            </p>

            <%= for {post_id, recs} <- Enum.group_by(@recommendations, & &1["blog_post_id"]) do %>
              <div style="margin: 0.5rem 0;">
                <p style="color: var(--ctp-blue); font-size: 0.8rem; font-weight: 700;"><%= post_id %></p>
                <%= for rec <- recs do %>
                  <div style="padding: 0.15rem 0 0.15rem 1rem; font-size: 0.8rem;">
                    <span style="color: var(--ctp-green);">→</span>
                    <span style="color: var(--ctp-text);"><%= rec["title"] %></span>
                    <%= if rec["description"] do %>
                      <span style="color: var(--ctp-subtext0);"> — <%= rec["description"] %></span>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% end %>

            <p style="color: var(--ctp-overlay0); font-size: 0.7rem; font-style: italic; margin-top: 0.5rem;">
              AI-generated topic suggestions — not endorsed links
            </p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp status_class({:info, _}), do: "status-message status-info"
  defp status_class({:error, _}), do: "status-message status-error"
end
