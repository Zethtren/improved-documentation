#!/bin/bash
set -e

echo "=== houston-cv minikube deployment ==="

echo "[1/4] Building images..."
docker build --target server -t houston-cv/surrealdb:latest ./apps/surrealdb
docker build --target init -t houston-cv/surrealdb-init:latest ./apps/surrealdb
docker build -t houston-cv/leptos-cv:latest ./apps/leptos-cv
docker build -t houston-cv/phoenix-dashboard:latest ./apps/phoenix-dashboard

echo "    Loading images into minikube..."
minikube image load houston-cv/surrealdb:latest
minikube image load houston-cv/surrealdb-init:latest
minikube image load houston-cv/leptos-cv:latest
minikube image load houston-cv/phoenix-dashboard:latest

echo "[2/4] Applying Kubernetes manifests..."
kubectl apply -k k8s/overlays/live-local/

echo "[3/4] Waiting for pods..."
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
echo "Run 'just mk-ports' or scripts/dev-ports.sh to access services"
