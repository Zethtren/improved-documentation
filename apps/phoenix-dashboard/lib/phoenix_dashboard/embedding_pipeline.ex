defmodule PhoenixDashboard.EmbeddingPipeline do
  alias PhoenixDashboard.{OllamaClient, SurrealClient}

  @doc "Generate and store embedding for a blog post"
  def embed_blog_post(post_id, content) do
    # Hash content to check if re-embedding is needed
    content_hash = :crypto.hash(:md5, content) |> Base.encode16(case: :lower)

    # Check if embedding already exists with same hash
    case SurrealClient.query("SELECT * FROM blog_embedding WHERE blog_post_id = '#{post_id}' AND content_hash = '#{content_hash}' LIMIT 1") do
      {:ok, [_existing]} ->
        {:ok, :already_embedded}
      _ ->
        # Delete old embedding if exists
        SurrealClient.query("DELETE blog_embedding WHERE blog_post_id = '#{post_id}'")

        # Generate new embedding
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

  @doc "Generate related topic suggestions for a blog post using LLM"
  def generate_recommendations(post_id, content) do
    prompt = """
    Based on the following blog post, suggest 5 related technical articles or resources that a reader might find interesting.
    For each suggestion, provide a realistic title and a one-sentence description.
    Format each as: TITLE | DESCRIPTION
    Only output the 5 lines, nothing else.

    Blog post:
    #{String.slice(content, 0..2000)}
    """

    case OllamaClient.generate(prompt) do
      {:ok, response} ->
        # Parse the response into recommendation records
        recommendations = response
          |> String.split("\n")
          |> Enum.filter(&(String.contains?(&1, "|")))
          |> Enum.take(5)
          |> Enum.map(fn line ->
            case String.split(line, "|", parts: 2) do
              [title, desc] ->
                %{
                  "blog_post_id" => post_id,
                  "title" => String.trim(title) |> String.trim_leading("- ") |> String.trim_leading("1. ") |> String.trim_leading("2. ") |> String.trim_leading("3. ") |> String.trim_leading("4. ") |> String.trim_leading("5. "),
                  "description" => String.trim(desc),
                  "source" => "ai-suggested",
                  "url" => "#",
                  "relevance_score" => 0.8
                }
              _ -> nil
            end
          end)
          |> Enum.filter(& &1)

        # Delete old recommendations
        SurrealClient.query("DELETE recommended_link WHERE blog_post_id = '#{post_id}'")

        # Store new ones
        Enum.each(recommendations, fn rec ->
          SurrealClient.create("recommended_link", rec)
        end)

        {:ok, length(recommendations)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
