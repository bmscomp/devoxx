#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# migrate.sh — ZooKeeper → KRaft Migration Demo Script
# ──────────────────────────────────────────────────────────────
# This script walks through the full migration from a
# ZooKeeper-based Kafka 3.9.2 cluster to a KRaft-only cluster.
#
# Usage:
#   ./migrate.sh
#
# Each phase pauses for confirmation so you can inspect the
# cluster state during a live demo.
# ──────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Helpers ───────────────────────────────────────────────────

info()  { echo -e "${BLUE}ℹ ${NC}${BOLD}$*${NC}"; }
ok()    { echo -e "${GREEN}✓ ${NC}$*"; }
warn()  { echo -e "${RED}⚠ ${NC}$*"; }
phase() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}  $*${NC}"; echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

pause() {
  echo ""
  read -rp "  Press ENTER to continue to the next step..."
  echo ""
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ══════════════════════════════════════════════════════════════
# PHASE 0 — Start ZooKeeper-based Kafka Cluster
# ══════════════════════════════════════════════════════════════

phase "PHASE 0 — Starting ZooKeeper-based Kafka 3.9.2 Cluster"

info "Bringing up ZooKeeper ensemble (3 nodes) + Kafka brokers (3 nodes)..."
docker compose -f docker-compose-zk.yml up -d

info "Waiting for brokers to become healthy (30s)..."
sleep 30

info "Verifying cluster is operational..."
docker exec broker-1 /opt/kafka/bin/kafka-metadata.sh --snapshot /var/kafka/data/__cluster_metadata-0/00000000000000000000.log --cluster-id 2>/dev/null || true

info "Creating a demo topic to verify data survives migration..."
docker exec broker-1 /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server broker-1:29092 \
  --create \
  --topic migration-test \
  --partitions 6 \
  --replication-factor 3

info "Producing 100 test messages..."
docker exec broker-1 bash -c '
  for i in $(seq 1 100); do
    echo "message-$i"
  done | /opt/kafka/bin/kafka-console-producer.sh \
    --bootstrap-server broker-1:29092 \
    --topic migration-test
'

ok "Phase 0 complete. ZK cluster is running with test data."
info "Topics:"
docker exec broker-1 /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server broker-1:29092 \
  --list

pause

# ══════════════════════════════════════════════════════════════
# PHASE 0.5 — Extract Cluster ID from ZooKeeper
# ══════════════════════════════════════════════════════════════

phase "PHASE 0.5 — Extracting Cluster ID from ZooKeeper"

info "Reading cluster.id from ZooKeeper..."
CLUSTER_ID=$(docker exec zookeeper-1 bash -c '
  echo "get /cluster/id" | /opt/bitnami/zookeeper/bin/zkCli.sh -server localhost:2181 2>/dev/null \
    | grep -o '"'"'"id":"[^"]*"'"'"' \
    | cut -d\" -f4
' 2>/dev/null || echo "")

if [ -z "$CLUSTER_ID" ]; then
  warn "Could not extract cluster ID automatically. Generating a new one..."
  CLUSTER_ID=$(docker exec broker-1 /opt/kafka/bin/kafka-storage.sh random-uuid)
fi

export CLUSTER_ID
echo "$CLUSTER_ID" > .cluster-id

ok "Cluster ID: ${BOLD}${CLUSTER_ID}${NC}"
info "Saved to .cluster-id file for subsequent phases."

pause

# ══════════════════════════════════════════════════════════════
# PHASE 1 — Deploy KRaft Controllers (Bridge Mode)
# ══════════════════════════════════════════════════════════════

phase "PHASE 1 — Deploying KRaft Controllers + Enabling Bridge Mode"

info "Stopping the ZK-only cluster..."
docker compose -f docker-compose-zk.yml down

info "Starting Bridge Mode cluster (ZK + KRaft controllers + migration-enabled brokers)..."
docker compose -f docker-compose-bridge.yml up -d

info "Waiting for controllers to form quorum and brokers to register (45s)..."
sleep 45

info "Checking migration status on the active controller..."
docker exec controller-1 /opt/kafka/bin/kafka-metadata.sh \
  --snapshot /var/kafka/metadata/__cluster_metadata-0/00000000000000000000.log \
  --cluster-id "$CLUSTER_ID" 2>/dev/null || true

info "Verifying demo topic still exists and data is intact..."
docker exec broker-1 /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server broker-1:29092 \
  --describe --topic migration-test

info "Consuming messages to verify data integrity..."
MSG_COUNT=$(docker exec broker-1 /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server broker-1:29092 \
  --topic migration-test \
  --from-beginning \
  --timeout-ms 10000 2>/dev/null | wc -l)

ok "Retrieved ${MSG_COUNT} messages from migration-test topic."
ok "Phase 1 complete. Cluster is in Bridge Mode — dual writing to ZK and KRaft."

pause

# ══════════════════════════════════════════════════════════════
# PHASE 2 — Finalize Migration
# ══════════════════════════════════════════════════════════════

phase "PHASE 2 — Finalizing Migration (One-Way Door!)"

warn "⚠  WARNING: This is a ONE-WAY operation."
warn "   After finalization, you CANNOT roll back to ZooKeeper."
echo ""
read -rp "  Type 'FINALIZE' to proceed: " CONFIRM

if [ "$CONFIRM" != "FINALIZE" ]; then
  warn "Aborted. You can re-run this script to try again."
  exit 1
fi

info "Stopping bridge mode cluster..."
docker compose -f docker-compose-bridge.yml down

info "Starting KRaft-only cluster (no ZooKeeper)..."
docker compose -f docker-compose-kraft.yml up -d

info "Waiting for KRaft-only cluster to stabilize (30s)..."
sleep 30

ok "Phase 2 complete. Cluster is now running in pure KRaft mode!"

# ══════════════════════════════════════════════════════════════
# PHASE 3 — Validation
# ══════════════════════════════════════════════════════════════

phase "PHASE 3 — Post-Migration Validation"

info "Listing all topics..."
docker exec broker-1 /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server broker-1:29092 \
  --list

info "Describing migration-test topic..."
docker exec broker-1 /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server broker-1:29092 \
  --describe --topic migration-test

info "Verifying data integrity — consuming all messages..."
MSG_COUNT=$(docker exec broker-1 /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server broker-1:29092 \
  --topic migration-test \
  --from-beginning \
  --timeout-ms 10000 2>/dev/null | wc -l)

ok "Retrieved ${MSG_COUNT} messages — data survived migration!"

info "Producing new messages to verify write path..."
docker exec broker-1 bash -c '
  for i in $(seq 101 110); do
    echo "post-migration-message-$i"
  done | /opt/kafka/bin/kafka-console-producer.sh \
    --bootstrap-server broker-1:29092 \
    --topic migration-test
'
ok "Successfully produced new messages post-migration."

info "Checking KRaft metadata status..."
docker exec broker-1 /opt/kafka/bin/kafka-broker-api-versions.sh \
  --bootstrap-server broker-1:29092 2>/dev/null | head -5

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ MIGRATION COMPLETE — Goodbye ZooKeeper, Hello KRaft!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Cluster ID:   ${BOLD}${CLUSTER_ID}${NC}"
echo -e "  Kafka:        ${BOLD}3.9.2${NC}"
echo -e "  Mode:         ${BOLD}KRaft (no ZooKeeper)${NC}"
echo -e "  Controllers:  ${BOLD}3 (IDs 100, 101, 102)${NC}"
echo -e "  Brokers:      ${BOLD}3 (IDs 1, 2, 3)${NC}"
echo ""
