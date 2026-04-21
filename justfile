# houston-cv development commands

# Default: show available recipes
default:
    @just --list

# --- Docker Compose (local dev) ---

# Start all services (build + init DB)
dev:
    docker compose up --build -d
    @echo ""
    @echo "Waiting for services to be healthy..."
    docker compose run --rm surrealdb-init
    @echo ""
    @echo "Services running:"
    @echo "  CV:        http://localhost:8080"
    @echo "  Dashboard: http://localhost:4000"
    @echo "  SurrealDB: http://localhost:8000"

# Stop all services
dev-down:
    docker compose down

# Rebuild and restart a single service (auto-inits DB if surrealdb)
dev-restart service:
    docker compose up --build -d {{ service }}
    {{ if service == "surrealdb" { "docker compose run --rm surrealdb-init" } else { "" } }}

# Tail logs (all services or specific)
logs *service:
    docker compose logs -f {{ service }}

# Re-run SurrealDB init (schema + seed)
db-init:
    docker compose run --rm surrealdb-init

# Pull required Ollama models
ollama-pull:
    docker compose exec ollama ollama pull nomic-embed-text
    docker compose exec ollama ollama pull llama3.1:8b

# --- Minikube ---

# Deploy to minikube (build images + apply manifests + init DB + pull models)
mk-deploy:
    #!/usr/bin/env bash
    set -e
    echo "=== houston-cv minikube deployment ==="
    echo "[1/5] Building images..."
    docker build --target server -t houston-cv/surrealdb:latest ./apps/surrealdb
    docker build --target init -t houston-cv/surrealdb-init:latest ./apps/surrealdb
    docker build -t houston-cv/leptos-cv:latest ./apps/leptos-cv
    docker build -t houston-cv/phoenix-dashboard:latest ./apps/phoenix-dashboard
    echo "    Loading images into minikube..."
    minikube image load houston-cv/surrealdb:latest
    minikube image load houston-cv/surrealdb-init:latest
    minikube image load houston-cv/leptos-cv:latest
    minikube image load houston-cv/phoenix-dashboard:latest
    echo "[2/5] Applying Kubernetes manifests..."
    kubectl apply -k k8s/overlays/dev/
    echo "[3/5] Waiting for pods..."
    kubectl wait --for=condition=ready pod -l app=surrealdb -n houston-cv --timeout=120s
    kubectl wait --for=condition=ready pod -l app=ollama -n houston-cv --timeout=120s
    kubectl wait --for=condition=ready pod -l app=searxng -n houston-cv --timeout=120s
    kubectl wait --for=condition=ready pod -l app=leptos-cv -n houston-cv --timeout=180s
    kubectl wait --for=condition=ready pod -l app=phoenix-dashboard -n houston-cv --timeout=120s
    echo "[4/4] Waiting for init jobs..."
    kubectl wait --for=condition=complete job/surrealdb-init -n houston-cv --timeout=120s
    echo "    SurrealDB init complete"
    kubectl wait --for=condition=complete job/ollama-model-pull -n houston-cv --timeout=600s
    echo "    Ollama model pull complete"
    echo ""
    echo "=== Deployment complete ==="
    echo "Run 'just mk-ports' to access services"

# Tear down minikube deployment
mk-teardown:
    kubectl delete -k k8s/overlays/dev/ --ignore-not-found
    @echo "Done. Images remain cached in minikube."

# Port-forward minikube services to localhost
mk-ports:
    #!/usr/bin/env bash
    set -e
    PIDS=()
    cleanup() { kill "${PIDS[@]}" 2>/dev/null; echo "Stopped."; }
    trap cleanup EXIT
    echo "Starting port-forwards for houston-cv..."
    kubectl port-forward -n houston-cv svc/leptos-cv-svc 8080:80 &
    PIDS+=($!)
    kubectl port-forward -n houston-cv svc/phoenix-dashboard-svc 4000:80 &
    PIDS+=($!)
    kubectl port-forward -n houston-cv svc/surrealdb 8000:8000 &
    PIDS+=($!)
    kubectl port-forward -n houston-cv svc/ollama 11434:11434 &
    PIDS+=($!)
    kubectl port-forward -n houston-cv svc/searxng-svc 8889:8080 &
    PIDS+=($!)
    sleep 2
    echo ""
    echo "=== houston-cv dev ports ==="
    echo "  CV:        http://localhost:8080"
    echo "  Dashboard: http://localhost:4000  (admin/admin)"
    echo "  SurrealDB: http://localhost:8000"
    echo "  Ollama:    http://localhost:11434"
    echo "  SearXNG:   http://localhost:8889"
    echo ""
    echo "Press Ctrl+C to stop all port-forwards"
    wait

# Rebuild and redeploy a single service to minikube
mk-redeploy service:
    #!/usr/bin/env bash
    set -e
    docker build -t houston-cv/{{ service }}:latest ./apps/{{ service }}
    minikube image load houston-cv/{{ service }}:latest
    kubectl rollout restart -n houston-cv deploy/{{ service }}
    kubectl wait --for=condition=ready pod -l app={{ service }} -n houston-cv --timeout=120s

# Show pod status
mk-status:
    kubectl get pods -n houston-cv

# Tail logs for a minikube pod
mk-logs service:
    kubectl logs -n houston-cv -l app={{ service }} -f
