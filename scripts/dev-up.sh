#!/bin/bash
set -e
echo "Starting houston-cv dev environment..."
docker compose up --build -d
echo ""
echo "Waiting for services to be healthy..."
docker compose run --rm surrealdb-init
echo ""
echo "Services running:"
echo "  CV:        http://localhost:8080"
echo "  Dashboard: http://localhost:4000"
echo "  SurrealDB: http://localhost:8000"
echo ""
echo "To view logs: docker compose logs -f"
