# Services

Per-service reference for what exists today. Paths are relative to the repo
root.

---

## leptos-cv

Public CV site. Rust, Leptos 0.8, built with `cargo-leptos`.

**Cargo features**

- `ssr` → server binary (Axum + Tokio + reqwest)
- `hydrate` → WASM bundle with `console_error_panic_hook`, `wasm-bindgen`, `web-sys`

`cargo-leptos` metadata (`apps/leptos-cv/Cargo.toml`):

- `site-addr = 127.0.0.1:8080`
- `style-file = style.css`
- `assets-dir = assets`
- `lib-profile-release = wasm-release` (opt-level `z`, LTO, 1 codegen unit)

**Source layout** (`apps/leptos-cv/src/`)

| File          | Purpose                                                            |
| ------------- | ------------------------------------------------------------------ |
| `main.rs`     | SSR entry — Axum router, `generate_route_list`, file fallback      |
| `lib.rs`      | Hydration entry (`hydrate` feature)                                |
| `app.rs`      | Top-level `App`, routing, page components, status bar, nav         |
| `db.rs`       | SurrealDB HTTP client helpers used by server functions             |
| `terminal.rs` | Interactive terminal emulator component                            |

Top-level components:

- `shell()` — SSR root wrapper
- `App()` — routes, theme switcher, meta
- `Nav()`, `StatusBar()`, `Section()`
- `BatView()` — static code block; `DynBatView()` — async data + render

Data types mirrored from SurrealDB (`SkillData`, `ProjectData`,
`ExperienceData`, `CertificationData`, `BlogPostData`, `RecommendedLink`).

Server functions include `record_page_view`, `get_skills`, `get_projects`,
`get_experience`, `get_certifications`, `get_blog_posts`, `get_blog_post`,
`get_recommendations`.

**Run locally**

```
cargo leptos watch          # dev with reload
cargo leptos build --release
```

**Env vars**: `SURREALDB_URL`, `LEPTOS_SITE_ADDR`.

---

## phoenix-dashboard

Elixir Phoenix 1.8 LiveView app for managing CV content and triggering the AI
recommendation pipeline.

**Key deps** (`apps/phoenix-dashboard/mix.exs`-level)

- `phoenix 1.8.5`, `phoenix_live_view 1.1.0`
- `bandit 1.5` (HTTP)
- `req 0.5` (HTTP client for SurrealDB, Ollama, SearXNG)
- `bcrypt_elixir 3.0` (session auth)
- `telemetry_metrics`, `telemetry_poller`

**Core modules** (`apps/phoenix-dashboard/lib/phoenix_dashboard/`)

| Module                | Purpose                                          |
| --------------------- | ------------------------------------------------ |
| `application.ex`      | OTP supervision tree                             |
| `auth.ex`             | Bcrypt auth, session plug                        |
| `surreal_client.ex`   | HTTP wrapper for SurrealDB CRUD                  |
| `ollama_client.ex`    | Ollama embeddings + generation                   |
| `web_search.ex`       | SearXNG HTTP client                              |
| `embedding_pipeline.ex` | Orchestrates query → search → rank (see AI doc)|

**Routes** (`router.ex`)

Public:

- `GET /login`, `POST /login`, `DELETE /logout`

Authenticated (behind `RequireAuth`):

- `GET /` → `DashboardLive`
- `GET /content/skills|projects|experience|certifications|blog`
- `GET /content/blog/:id/edit` → `BlogPostLive`
- `GET /insights/visitors` → `AnalyticsLive`
- `GET /insights/skills` → `SkillAnalyticsLive`

**Env vars**: `SURREALDB_URL`, `SURREAL_USER`, `SURREAL_PASS`,
`SECRET_KEY_BASE`, `PHX_HOST`, `PHX_SERVER`, `OLLAMA_URL`, `SEARXNG_URL`.

---

## surrealdb

Container image, schema files, seed data, and init script.

**Layout** (`apps/surrealdb/`)

```
Dockerfile            Multi-target: `server` and `init` stages
schemas/              Applied in numeric order by init.sh
  001_cv_tables.surql     Core CV tables + page_view, admin_user
  002_cv_relations.surql  Edge / relation definitions
  003_cv_permissions.surql Record-access `admin` rule, Argon2
  004_cv_indexes.surql    Indexes (e.g. blog_post.slug UNIQUE)
  005_cv_events.surql     DB-level events / triggers
  006_blog.surql          blog_post table
  007_embeddings.surql    blog_embedding + recommended_link
seed/cv_data.surql    Skills, projects, experience, certs, fortunes
scripts/init.sh       Waits for /health, imports schemas + seed
```

**Namespace / database**: `houston` / `cv`.

**Init flow** (`scripts/init.sh`):

1. Poll `http://$SURREAL_HOST/health` up to 30 × 2 s.
2. `surreal import` each schema file in order.
3. `surreal import` the seed file.

Invoked automatically by `just dev` (Docker Compose `surrealdb-init` profile)
and `just mk-deploy` (`kubectl exec` into the StatefulSet).

---

## searxng

Local metasearch engine used exclusively by the recommendation pipeline.

**Files**: `apps/searxng/settings.yml` only.

- `use_default_settings: true`
- Formats: HTML + JSON
- Rate limiter disabled for local dev
- Secret key is dev-only

In Compose it's the upstream image mounted with this config. Phoenix reaches it
via `SEARXNG_URL` (Compose: `http://searxng:8080`, local: `http://localhost:8889`).

---

## ollama

Not a first-party app — upstream `ollama/ollama:latest` image with a persistent
`ollama-data` volume. Models pulled on demand:

```
just ollama-pull
# → ollama pull nomic-embed-text
# → ollama pull llama3.1:8b
```

Phoenix reaches it via `OLLAMA_URL` (Compose: `http://ollama:11434`).
