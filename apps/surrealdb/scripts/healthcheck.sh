#!/bin/bash
# ============================================================================
# healthcheck.sh — Simple SurrealDB health check
# ============================================================================
curl -sf "${SURREAL_HOST:-http://localhost:8000}/health" || exit 1
