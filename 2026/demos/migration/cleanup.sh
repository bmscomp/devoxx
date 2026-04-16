#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# cleanup.sh — Tear down all demo containers and volumes
# ──────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Stopping all migration demo containers..."

docker compose -f docker-compose-kraft.yml  down -v 2>/dev/null || true
docker compose -f docker-compose-bridge.yml down -v 2>/dev/null || true
docker compose -f docker-compose-zk.yml     down -v 2>/dev/null || true

rm -f .cluster-id

echo "✓ Cleanup complete."
