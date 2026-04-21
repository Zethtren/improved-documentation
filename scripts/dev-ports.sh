#!/bin/bash
# Forward all houston-cv services to localhost on fixed ports
# CV:        http://localhost:8080
# Dashboard: http://localhost:4000
# SurrealDB: http://localhost:8000
# Ollama:    http://localhost:11434
# SearXNG:   http://localhost:8889

set -e

PIDS=()
cleanup() { kill "${PIDS[@]}" 2>/dev/null; echo "Stopped."; }
trap cleanup EXIT

echo "Starting port-forwards for houston-cv..."
echo ""

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
