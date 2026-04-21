# Deployment

Two runtimes currently exist: Docker Compose for day-to-day development and
Kustomize manifests for Kubernetes (Minikube today, GKE-ready structure).

## Docker Compose

`docker-compose.yml` defines six services; `docker-compose.override.yml`
overlays local-only settings (e.g. SurrealDB start args).

| Service           | Image / Build                       | Host port |
| ----------------- | ----------------------------------- | --------- |
| `surrealdb`       | `./apps/surrealdb` (target `server`)| 8000      |
| `surrealdb-init`  | `./apps/surrealdb` (target `init`) — profile `init` | — |
| `leptos-cv`       | `./apps/leptos-cv`                  | 8080      |
| `phoenix-dashboard` | `./apps/phoenix-dashboard`        | 4000      |
| `ollama`          | `ollama/ollama:latest`              | 11434     |
| `searxng`         | `searxng/searxng:latest`            | 8889      |

Volumes: `surreal-data`, `ollama-data` (persistent).

Healthchecks: `surrealdb` uses `surreal is-ready`; `ollama` uses `ollama list`.

**Common recipes** (`justfile`):

```
just dev              # up --build -d, then run surrealdb-init
just dev-down         # compose down
just dev-restart <s>  # rebuild + restart a single service
just logs [service]   # tail logs
just db-init          # re-run the surrealdb-init profile
just ollama-pull      # pull nomic-embed-text + llama3.1:8b
```

## Kubernetes (Kustomize)

Everything runs in the `houston-cv` namespace. Base manifests live in
`k8s/base/`, environment tweaks in `k8s/overlays/{dev,prod}/`.

```
k8s/base/
  namespace.yaml
  kustomization.yaml
  leptos-cv/           deployment.yaml, service.yaml
  phoenix-dashboard/   deployment.yaml, service.yaml
  surrealdb/           statefulset.yaml, service.yaml, secret.yaml, networkpolicy.yaml
  ingress/             ingress.yaml
```

**Workloads**

- `leptos-cv` Deployment, 1 replica, image `houston-cv/leptos-cv:latest`,
  port 8080. Liveness: `GET /`. Env: `SURREALDB_URL`, `LEPTOS_SITE_ADDR`.
- `phoenix-dashboard` Deployment, 1 replica, image
  `houston-cv/phoenix-dashboard:latest`, port 4000. Liveness: `GET /health`.
  Env: `SURREALDB_URL`, `SECRET_KEY_BASE`, `PHX_HOST`, `PHX_SERVER`.
- `surrealdb` StatefulSet, 1 replica, image `surrealdb/surrealdb:v2`,
  10 Gi PVC at `/data`. Command: `start -u root -p $(SURREAL_PASS) -b 0.0.0.0:8000 file:/data/srdb.db`.

**Services** (all ClusterIP): `leptos-cv-svc:80→8080`,
`phoenix-dashboard-svc:80→4000`, `surrealdb:8000`.

**Ingress** (`base/ingress/ingress.yaml`): nginx class, two host rules —
`cv.localhost → leptos-cv-svc`, `admin.localhost → phoenix-dashboard-svc`.

**Secrets**: `surrealdb-credentials` (`SURREAL_USER`, `SURREAL_PASS`).

**NetworkPolicy**: base policy restricting who can reach SurrealDB (see
`k8s/base/surrealdb/networkpolicy.yaml`).

### Overlays

- `overlays/dev/` — patches for local Minikube (resource tweaks, pod specs).
  Used by `just mk-deploy` / `mk-teardown`.
- `overlays/prod/` — currently includes base unchanged. In-file notes call out
  what should change for prod: sealed or external secrets, resource
  requests/limits, HPA, TLS on Ingress, fixed image tags, PodDisruptionBudgets.

### Minikube recipes

```
just mk-deploy     # eval docker-env; build 3 images; kubectl apply -k overlays/dev; wait; run init.sh
just mk-teardown   # kubectl delete -k overlays/dev (images cached in minikube)
just mk-ports      # port-forward 8080, 4000, 8000
just mk-redeploy <service>  # rebuild + rollout restart
just mk-status     # kubectl get pods
just mk-logs <service>      # follow logs
```

The deploy recipe runs `init.sh` inside the SurrealDB StatefulSet pod after
the rollout completes.
