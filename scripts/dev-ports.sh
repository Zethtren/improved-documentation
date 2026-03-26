#!/bin/bash
# Forward all houston-cv services to localhost on fixed ports
# CV:        http://localhost:8080
# Dashboard: http://localhost:4000
# SurrealDB: http://localhost:8000

set -e

echo "Starting port-forwards for houston-cv..."
echo ""

kubectl port-forward -n houston-cv svc/leptos-cv-svc 8080:80 &
PID1=$!
kubectl port-forward -n houston-cv svc/phoenix-dashboard-svc 4000:80 &
PID2=$!
kubectl port-forward -n houston-cv svc/surrealdb 8000:8000 &
PID3=$!

sleep 2
echo ""
echo "=== houston-cv dev ports ==="
echo "  CV:        http://localhost:8080"
echo "  Dashboard: http://localhost:4000  (admin/admin)"
echo "  SurrealDB: http://localhost:8000"
echo ""
echo "Press Ctrl+C to stop all port-forwards"

trap "kill $PID1 $PID2 $PID3 2>/dev/null; echo 'Stopped.'" EXIT
wait
