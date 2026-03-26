defmodule PhoenixDashboard.WebSearch do
  @moduledoc """
  Web search using a local SearXNG instance.
  Returns a list of %{title, url, snippet} maps.
  """

  @default_url "http://localhost:8888"

  def search(query, opts \\ []) do
    max_results = Keyword.get(opts, :max_results, 10)
    base_url = Application.get_env(:phoenix_dashboard, :searxng_url, @default_url)

    case Req.get("#{base_url}/search",
      params: [q: query, format: "json", categories: "general"],
      receive_timeout: 15_000
    ) do
      {:ok, %{status: 200, body: %{"results" => results}}} when is_list(results) ->
        parsed = results
          |> Enum.take(max_results)
          |> Enum.map(fn r ->
            %{
              "url" => r["url"] || "",
              "title" => r["title"] || "",
              "snippet" => r["content"] || ""
            }
          end)
          |> Enum.filter(fn r -> r["url"] != "" and r["title"] != "" end)

        {:ok, parsed}

      {:ok, %{status: status}} ->
        {:error, "Search returned status #{status}"}

      {:error, reason} ->
        {:error, "Search failed: #{inspect(reason)}"}
    end
  end
end
