# houston-cv docs

This folder describes what currently exists in the monorepo. It does not prescribe
changes — see `vision.md` for the aspirational north star.

## Index

- [architecture.md](architecture.md) — system overview, services, data flow
- [services.md](services.md) — per-service reference (stack, layout, entry points)
- [deployment.md](deployment.md) — local Docker Compose and Minikube/Kustomize
- [ai-recommendations.md](ai-recommendations.md) — blog recommendation pipeline
- [vision.md](vision.md) — long-form product vision (aspirational)

## Repo layout

```
apps/
  leptos-cv/          Rust SSR + hydrate public site (port 8080)
  phoenix-dashboard/  Elixir/Phoenix LiveView admin (port 4000)
  surrealdb/          Schema, seed, init script (port 8000)
  searxng/            Local web-search settings (port 8889)
docs/                 This folder
k8s/
  base/               Kustomize base manifests
  overlays/{dev,prod} Per-environment overlays
scripts/              Wrappers around justfile recipes
docker-compose.yml    Local multi-service runtime
docker-compose.override.yml  Local overrides (SurrealDB start args)
justfile              `just`-based task runner
```

## Quick start

```
just dev           # docker compose up + SurrealDB init
just mk-deploy     # build images and deploy to minikube
just --list        # all recipes
```

Default local URLs:

| Service           | URL                       |
| ----------------- | ------------------------- |
| Leptos CV         | http://localhost:8080     |
| Phoenix Dashboard | http://localhost:4000     |
| SurrealDB         | http://localhost:8000     |
| Ollama            | http://localhost:11434    |
| SearXNG           | http://localhost:8889     |
