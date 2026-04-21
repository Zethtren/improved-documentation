# AI recommendation pipeline

Per blog post, generate a curated list of related links. Triggered from the
admin dashboard; displayed on the public site.

## Components involved

- **Phoenix dashboard** orchestrates the pipeline (`EmbeddingPipeline`).
- **Ollama** — local LLM (`llama3.1:8b`) for query generation and ranking;
  embeddings via `nomic-embed-text`.
- **SearXNG** — local metasearch, returns real web results.
- **SurrealDB** — persists embeddings and final recommendations.
- **Leptos CV** — reads `recommended_link` rows to render the per-post list.

## Flow

```
BlogPostLive "Generate Recommendations"
        │
        ▼
 EmbeddingPipeline (Task.start_link, async)
        │
        │ 1. generate_search_queries/1
        │    Ollama LLM → 4 diverse queries (5–200 chars each)
        │
        │ 2. search_for_articles/1
        │    For each query → WebSearch.search → SearXNG /search?format=json
        │    Dedupe by URL; drop empty title/url
        │
        │ 3. rank_results/2
        │    Ollama LLM → "NUMBER | REASON" × 5 lines
        │    Parse → pick 5 results by index
        │
        ▼
 SurrealDB
   blog_embedding   (post_id, embedding, content_hash — cache)
   recommended_link (blog_post_id, url, title, description,
                     source='ai-curated', relevance_score=0.9,
                     fetched_at)
```

Old `recommended_link` rows for a post are deleted before new ones are
inserted. `blog_embedding.content_hash` avoids recomputing embeddings when
the post body hasn't changed.

## Prompts (summary)

- **Query generation**: instructs the model to read the post carefully and
  emit four queries aimed at deeper dives, adjacent perspectives, and
  complementary knowledge — explicitly *not* assumed to be a tech post.
- **Ranking**: instructs the model to pick the five most relevant articles
  for someone who just finished reading the post, and to skip marketing or
  off-topic pages. Output format is strict: `NUMBER | REASON`, exactly five
  lines.

## Where to look

| Concern                 | File                                                                |
| ----------------------- | ------------------------------------------------------------------- |
| Orchestration           | `apps/phoenix-dashboard/lib/phoenix_dashboard/embedding_pipeline.ex` |
| LLM + embeddings client | `.../ollama_client.ex`                                              |
| Search client           | `.../web_search.ex`                                                 |
| SurrealDB HTTP client   | `.../surreal_client.ex`                                             |
| Trigger (UI)            | `BlogPostLive` `handle_event "generate-recommendations"`            |
| Schema                  | `apps/surrealdb/schemas/007_embeddings.surql`                       |
| Public rendering        | `get_recommendations` server fn in `apps/leptos-cv/src/app.rs`      |

## Operational notes

- Models must be pulled first: `just ollama-pull`.
- The pipeline runs as a background `Task`, so the LiveView returns
  immediately after kicking it off.
- SearXNG rate limiter is disabled in the provided dev config; JSON results
  format must remain enabled for `WebSearch` to parse responses.
