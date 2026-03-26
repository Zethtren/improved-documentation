#!/bin/bash
# ============================================================================
# init.sh — Wait for SurrealDB, then apply schemas and seed data
# ============================================================================
set -euo pipefail

SURREAL_HOST="${SURREAL_HOST:-http://localhost:8000}"
SURREAL_USER="${SURREAL_USER:-root}"
SURREAL_PASS="${SURREAL_PASS:-root}"
SURREAL_NS="${SURREAL_NS:-houston}"
SURREAL_DB="${SURREAL_DB:-cv}"

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA_DIR="${SCRIPT_DIR}/schemas"
SEED_DIR="${SCRIPT_DIR}/seed"

MAX_RETRIES=30
RETRY_INTERVAL=2

echo "==> Waiting for SurrealDB at ${SURREAL_HOST} ..."

for i in $(seq 1 $MAX_RETRIES); do
    if curl -sf "${SURREAL_HOST}/health" > /dev/null 2>&1; then
        echo "==> SurrealDB is ready (attempt ${i}/${MAX_RETRIES})"
        break
    fi
    if [ "$i" -eq "$MAX_RETRIES" ]; then
        echo "!!! SurrealDB not reachable after ${MAX_RETRIES} attempts. Aborting."
        exit 1
    fi
    echo "    ... not ready yet (attempt ${i}/${MAX_RETRIES}), retrying in ${RETRY_INTERVAL}s"
    sleep "$RETRY_INTERVAL"
done

echo ""
echo "==> Applying schema files ..."

for schema in "${SCHEMA_DIR}"/[0-9]*.surql; do
    if [ -f "$schema" ]; then
        fname="$(basename "$schema")"
        echo "    -> ${fname}"
        surreal import \
            --endpoint "${SURREAL_HOST}" \
            --username "${SURREAL_USER}" \
            --password "${SURREAL_PASS}" \
            --namespace "${SURREAL_NS}" \
            --database "${SURREAL_DB}" \
            "$schema"
    fi
done

echo ""
echo "==> Applying seed data ..."

for seed in "${SEED_DIR}"/*.surql; do
    if [ -f "$seed" ]; then
        fname="$(basename "$seed")"
        echo "    -> ${fname}"
        surreal import \
            --endpoint "${SURREAL_HOST}" \
            --username "${SURREAL_USER}" \
            --password "${SURREAL_PASS}" \
            --namespace "${SURREAL_NS}" \
            --database "${SURREAL_DB}" \
            "$seed"
    fi
done

echo ""
echo "==> Database initialization complete!"
echo "    Namespace: ${SURREAL_NS}"
echo "    Database:  ${SURREAL_DB}"
echo "    Endpoint:  ${SURREAL_HOST}"
