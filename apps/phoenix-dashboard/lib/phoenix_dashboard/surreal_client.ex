defmodule PhoenixDashboard.SurrealClient do
  @moduledoc """
  HTTP client for SurrealDB. Wraps Req to issue queries against the
  SurrealDB HTTP API using namespace "houston" and database "cv".
  """

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Execute a raw SurrealQL query."
  def query(sql) when is_binary(sql) do
    post_sql(sql)
  end

  @doc "Select all records from a table."
  def select(table) when is_binary(table) do
    post_sql("SELECT * FROM #{table}")
  end

  @doc "Create a record in `table` with `data` (map)."
  def create(table, data) when is_binary(table) and is_map(data) do
    json = Jason.encode!(data)
    post_sql("CREATE #{table} CONTENT #{json}")
  end

  @doc "Update a record by its full id (e.g. `\"person:abc\"`) with `data`."
  def update(id, data) when is_binary(id) and is_map(data) do
    json = Jason.encode!(data)
    post_sql("UPDATE #{id} MERGE #{json}")
  end

  @doc "Delete a record by its full id."
  def delete(id) when is_binary(id) do
    post_sql("DELETE #{id}")
  end

  # ---------------------------------------------------------------------------
  # Internals
  # ---------------------------------------------------------------------------

  defp post_sql(sql) do
    config = Application.get_env(:phoenix_dashboard, :surrealdb, [])

    base_url = Keyword.get(config, :url, "http://localhost:8000")
    username = Keyword.get(config, :username, "root")
    password = Keyword.get(config, :password, "root")
    namespace = Keyword.get(config, :namespace, "houston")
    database = Keyword.get(config, :database, "cv")

    Req.post("#{base_url}/sql",
      body: sql,
      headers: [
        {"content-type", "application/json"},
        {"accept", "application/json"},
        {"surreal-ns", namespace},
        {"surreal-db", database}
      ],
      auth: {:basic, "#{username}:#{password}"}
    )
    |> handle_response()
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}}) when status in 200..299 do
    {:ok, body}
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}}) do
    {:error, %{status: status, body: body}}
  end

  defp handle_response({:error, reason}) do
    {:error, reason}
  end
end
