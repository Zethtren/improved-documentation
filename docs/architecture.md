# Architecture

Snapshot of the system as it stands today.

## Services

| Service           | Role                                  | Stack                          | Port  |
| ----------------- | ------------------------------------- | ------------------------------ | ----- |
| leptos-cv         | Public CV site (SSR + hydrate)        | Rust, Leptos 0.8, Axum 0.8     | 8080  |
| phoenix-dashboard | Admin UI for content + AI pipeline    | Elixir, Phoenix 1.8, LiveView  | 4000  |
| surrealdb         | Primary data store                    | SurrealDB v2                   | 8000  |
| ollama            | Local LLM + embeddings                | `ollama/ollama:latest`         | 11434 |
| searxng           | Local metasearch for AI recs          | `searxng/searxng:latest`       | 8889  |

All services run in a single namespace (`houston-cv`) on Kubernetes. SurrealDB
and SearXNG/Ollama are cluster-internal; only `leptos-cv` and
`phoenix-dashboard` are exposed via Ingress.

## High-level data flow

```
Visitor ──HTTP──▶ leptos-cv ──HTTP──▶ surrealdb
                      │
                      └──records page_view on each route change

Admin ──HTTPS──▶ phoenix-dashboard ──HTTP──▶ surrealdb
                      │                         ▲
                      ├──HTTP──▶ ollama         │
                      ├──HTTP──▶ searxng        │
                      └──writes embeddings + recommended_link ─┘
```

The public site is read-only from SurrealDB. All writes (CV content, blog
posts, recommendations, embeddings) go through the Phoenix dashboard.

## Data model (SurrealDB)

Namespace `houston`, database `cv`. Schemas applied in numeric order from
`apps/surrealdb/schemas/`.

Tables:

- `skill` — name, category, proficiency, hours, years, description
- `project` — title, description, tags, source_url, live_url, status, visible, sort_order
- `experience` — title, company, start_date, end_date, description, current
- `certification` — title, issuer, date
- `education` — degree/institution fields
- `fortune` — easter-egg quotes
- `page_view` — visit log written by leptos-cv
- `admin_user` — username + Argon2 hash (database-level ACCESS)
- `blog_post` — id, title, slug (unique), content, published, tags, draft
- `blog_embedding` — post_id, embedding, content_hash (AI pipeline cache)
- `recommended_link` — blog_post_id, url, title, description, source, relevance_score, fetched_at

Permissions are SCHEMAFULL with public `SELECT FULL` and mutations gated on
`$auth.admin = true`. See `apps/surrealdb/schemas/003_cv_permissions.surql`.

## Auth

- **SurrealDB**: record-access rule `admin` with Argon2 hashing, 24 h session.
- **Phoenix dashboard**: session-based, Bcrypt, credentials from app config
  (default `admin`/`admin` in dev). All content routes behind a `RequireAuth`
  plug.
- **Leptos CV**: no user auth. Server functions call SurrealDB as root
  (credentials from env vars).

## Configuration surface

Environment variables consumed by the services (see `docker-compose.yml` and
`k8s/base/*/deployment.yaml`):

| Var                | Service           | Notes                              |
| ------------------ | ----------------- | ---------------------------------- |
| `SURREALDB_URL`    | leptos-cv, phx    | HTTP base URL of SurrealDB         |
| `SURREAL_USER`     | phx, surrealdb    | Root username                      |
| `SURREAL_PASS`     | phx, surrealdb    | Root password                      |
| `LEPTOS_SITE_ADDR` | leptos-cv         | Bind addr, e.g. `0.0.0.0:8080`     |
| `SECRET_KEY_BASE`  | phx               | Phoenix cookie signing             |
| `PHX_HOST`         | phx               | Public hostname                    |
| `PHX_SERVER`       | phx               | `true` to start endpoint           |
| `OLLAMA_URL`       | phx               | Ollama base URL                    |
| `SEARXNG_URL`      | phx               | SearXNG base URL                   |

## Repo-level conventions

- Catppuccin palette across all three user-facing services.
- Terminal/CRT aesthetic is primarily a CSS concern in `leptos-cv/style.css`.
- SurrealDB schema changes live in numbered `.surql` files; the init script
  applies them in order and then loads `seed/cv_data.surql`.
- All runtime recipes go through `justfile` — scripts in `scripts/` are thin
  wrappers.
