defmodule PhoenixDashboard.EmbeddingPipeline do
  alias PhoenixDashboard.{OllamaClient, SurrealClient, WebSearch}
  require Logger

  @doc "Generate and store embedding for a blog post"
  def embed_blog_post(post_id, content) do
    content_hash = :crypto.hash(:md5, content) |> Base.encode16(case: :lower)

    case SurrealClient.query("SELECT * FROM blog_embedding WHERE blog_post_id = '#{post_id}' AND content_hash = '#{content_hash}' LIMIT 1") do
      {:ok, [_existing]} ->
        {:ok, :already_embedded}
      _ ->
        SurrealClient.query("DELETE blog_embedding WHERE blog_post_id = '#{post_id}'")

        case OllamaClient.embed(content) do
          {:ok, embedding} ->
            SurrealClient.create("blog_embedding", %{
              "blog_post_id" => post_id,
              "embedding" => embedding,
              "content_hash" => content_hash
            })
          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Generate recommendations using a 3-step pipeline:
  1. LLM generates search queries from the blog content
  2. Web search finds real articles for each query
  3. LLM ranks and selects the 5 most useful results
  """
  def generate_recommendations(post_id, content) do
    Logger.info("Starting recommendation pipeline for #{post_id}")

    # Step 1: Generate search queries
    with {:ok, queries} <- generate_search_queries(content),
         # Step 2: Search the web for each query
         {:ok, all_results} <- search_for_articles(queries),
         # Step 3: LLM ranks and picks the best 5
         {:ok, ranked} <- rank_results(content, all_results) do

      # Store results
      SurrealClient.query("DELETE recommended_link WHERE blog_post_id = '#{post_id}'")

      Enum.each(ranked, fn rec ->
        SurrealClient.create("recommended_link", Map.put(rec, "blog_post_id", post_id))
      end)

      Logger.info("Generated #{length(ranked)} recommendations for #{post_id}")
      {:ok, length(ranked)}
    else
      {:error, reason} ->
        Logger.error("Recommendation pipeline failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Step 1: Ask LLM for search queries
  defp generate_search_queries(content) do
    prompt = """
    Read this blog post and generate 4 diverse search queries that would find related articles other developers have written.
    Think about: similar technologies, alternative approaches, deeper dives into subtopics, and complementary skills.
    Don't just rephrase the title — think about what a reader would want to explore AFTER reading this.

    Output exactly 4 search queries, one per line. No numbering, no bullets, just the queries.

    Blog post:
    #{String.slice(content, 0..2000)}
    """

    case OllamaClient.generate(prompt) do
      {:ok, response} ->
        queries = response
          |> String.split("\n")
          |> Enum.map(&String.trim/1)
          |> Enum.filter(&(String.length(&1) > 5 and String.length(&1) < 200))
          |> Enum.take(4)

        Logger.info("Generated #{length(queries)} search queries")
        if queries == [], do: {:error, "No queries generated"}, else: {:ok, queries}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Step 2: Search the web for real articles
  defp search_for_articles(queries) do
    results = queries
      |> Enum.flat_map(fn query ->
        Logger.info("Searching: #{query}")
        case WebSearch.search(query <> " blog post article", max_results: 10) do
          {:ok, results} -> results
          {:error, _} -> []
        end
      end)
      |> Enum.uniq_by(& &1["url"])  # deduplicate by URL

    Logger.info("Found #{length(results)} unique search results")
    if results == [], do: {:error, "No search results found"}, else: {:ok, results}
  end

  # Step 3: LLM ranks results by usefulness
  defp rank_results(content, search_results) do
    # Format search results for the LLM
    formatted = search_results
      |> Enum.with_index(1)
      |> Enum.map(fn {r, i} ->
        "[#{i}] #{r["title"]}\n    URL: #{r["url"]}\n    #{r["snippet"]}"
      end)
      |> Enum.join("\n\n")

    prompt = """
    You are selecting the 5 most useful articles for someone who just read a blog post.
    Don't just pick the most similar articles — think about what would genuinely help the reader:
    - Articles that go deeper into a topic mentioned
    - Alternative perspectives or approaches
    - Practical tutorials that complement the knowledge
    - Well-written pieces from real developers sharing experience

    Avoid: marketing pages, generic documentation landing pages, or results that seem off-topic.

    ORIGINAL BLOG POST:
    #{String.slice(content, 0..1500)}

    CANDIDATE ARTICLES:
    #{formatted}

    Select the 5 best articles. For each, output exactly:
    NUMBER | REASON

    Where NUMBER is the article number from above, and REASON is one sentence explaining why it's useful.
    Output exactly 5 lines. No other text.
    """

    case OllamaClient.generate(prompt) do
      {:ok, response} ->
        ranked = response
          |> String.split("\n")
          |> Enum.filter(&(String.contains?(&1, "|")))
          |> Enum.take(5)
          |> Enum.map(fn line ->
            case String.split(line, "|", parts: 2) do
              [num_str, reason] ->
                num = try do
                  num_str |> String.trim() |> String.replace(~r/[^\d]/, "") |> String.to_integer()
                rescue
                  _ -> 0
                end
                article = Enum.at(search_results, num - 1)
                if article do
                  %{
                    "title" => article["title"],
                    "url" => article["url"],
                    "description" => String.trim(reason),
                    "source" => "ai-curated",
                    "relevance_score" => 0.9
                  }
                else
                  nil
                end
              _ -> nil
            end
          end)
          |> Enum.filter(& &1)

        if ranked == [], do: {:error, "No articles ranked"}, else: {:ok, ranked}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
