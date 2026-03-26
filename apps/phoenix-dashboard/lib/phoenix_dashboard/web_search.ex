defmodule PhoenixDashboard.WebSearch do
  @moduledoc """
  Simple web search using DuckDuckGo HTML endpoint.
  Returns a list of %{title, url, snippet} maps.
  """

  def search(query, opts \\ []) do
    max_results = Keyword.get(opts, :max_results, 10)

    case Req.get("https://html.duckduckgo.com/html/",
      params: [q: query],
      headers: [
        {"user-agent", "Mozilla/5.0 (compatible; houston-cv-bot/1.0)"}
      ],
      receive_timeout: 15_000
    ) do
      {:ok, %{status: 200, body: body}} ->
        results = parse_ddg_results(body, max_results)
        {:ok, results}

      {:ok, %{status: status}} ->
        {:error, "Search returned status #{status}"}

      {:error, reason} ->
        {:error, "Search failed: #{inspect(reason)}"}
    end
  end

  defp parse_ddg_results(html, max_results) when is_binary(html) do
    # Parse DuckDuckGo HTML results
    # Results are in <a class="result__a" href="...">title</a>
    # Snippets in <a class="result__snippet">...</a>
    Regex.scan(
      ~r/<a[^>]*class="result__a"[^>]*href="([^"]*)"[^>]*>(.*?)<\/a>.*?<a[^>]*class="result__snippet"[^>]*>(.*?)<\/a>/s,
      html
    )
    |> Enum.take(max_results)
    |> Enum.map(fn [_, url, title, snippet] ->
      %{
        "url" => clean_ddg_url(url),
        "title" => strip_html(title),
        "snippet" => strip_html(snippet)
      }
    end)
    |> Enum.filter(fn r -> r["url"] != "" and r["title"] != "" end)
  end

  defp parse_ddg_results(_, _), do: []

  defp clean_ddg_url(url) do
    # DDG wraps URLs in a redirect: //duckduckgo.com/l/?uddg=ENCODED_URL&...
    case URI.decode_query(URI.parse(url).query || "") do
      %{"uddg" => real_url} -> real_url
      _ -> url
    end
  rescue
    _ -> url
  end

  defp strip_html(text) do
    text
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#x27;", "'")
    |> String.trim()
  end
end
