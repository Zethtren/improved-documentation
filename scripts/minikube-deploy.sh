#!/bin/bash
set -e

echo "=== houston-cv minikube deployment ==="

# Use minikube's Docker daemon
eval $(minikube docker-env)

echo "[1/4] Building images..."
docker build -t houston-cv/surrealdb:latest ./apps/surrealdb
docker build -t houston-cv/leptos-cv:latest ./apps/leptos-cv
docker build -t houston-cv/phoenix-dashboard:latest ./apps/phoenix-dashboard

echo "[2/4] Applying Kubernetes manifests..."
kubectl apply -k k8s/overlays/dev/

echo "[3/4] Waiting for pods..."
kubectl wait --for=condition=ready pod -l app=surrealdb -n houston-cv --timeout=120s
kubectl wait --for=condition=ready pod -l app=leptos-cv -n houston-cv --timeout=120s
kubectl wait --for=condition=ready pod -l app=phoenix-dashboard -n houston-cv --timeout=120s

echo "[4/4] Running SurrealDB init..."
kubectl exec -n houston-cv deploy/surrealdb -- /opt/surrealdb/scripts/init.sh

echo ""
echo "=== Deployment complete ==="
echo ""
echo "To access services, run: minikube tunnel"
echo "Then visit:"
echo "  CV:        http://cv.localhost"
echo "  Dashboard: http://admin.localhost"
echo ""
echo "Or use port-forwarding:"
echo "  kubectl port-forward -n houston-cv svc/leptos-cv-svc 8080:80"
echo "  kubectl port-forward -n houston-cv svc/phoenix-dashboard-svc 4000:80"
echo "  kubectl port-forward -n houston-cv svc/surrealdb-svc 8000:8000"
