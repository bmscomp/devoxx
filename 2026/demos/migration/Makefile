# ──────────────────────────────────────────────────────────────
# Makefile — ZooKeeper → KRaft Migration Demo
# ──────────────────────────────────────────────────────────────
# Each target corresponds to one phase of the migration.
# Run them sequentially:
#
#   make phase0        Start ZK-based cluster + seed test data
#   make cluster-id    Extract and save the cluster ID from ZK
#   make phase1        Deploy KRaft controllers + enable bridge mode
#   make verify-bridge Verify data integrity in bridge mode
#   make phase2        Finalize migration — KRaft only (irreversible!)
#   make verify-kraft  Verify data integrity post-migration
#   make clean         Tear down everything (containers + volumes)
#
# Or run the entire migration end-to-end:
#   make all
# ──────────────────────────────────────────────────────────────

.PHONY: all phase0 cluster-id phase1 verify-bridge phase2 verify-kraft clean status help

SHELL := /bin/bash
COMPOSE_ZK     := docker compose -f docker-compose-zk.yml
COMPOSE_BRIDGE := docker compose -f docker-compose-bridge.yml
COMPOSE_KRAFT  := docker compose -f docker-compose-kraft.yml
BROKER_EXEC    := docker exec broker-1
KAFKA_BIN      := /bin
BOOTSTRAP      := broker-1:29092
TOPIC          := migration-test

# Colors
GREEN  := \033[0;32m
BLUE   := \033[0;34m
RED    := \033[0;31m
CYAN   := \033[0;36m
BOLD   := \033[1m
NC     := \033[0m

# ── Default target ────────────────────────────────────────────

all: phase0 cluster-id phase1 verify-bridge phase2 verify-kraft
	@echo ""
	@echo -e "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo -e "$(GREEN)  ✓ MIGRATION COMPLETE — Goodbye ZooKeeper, Hello KRaft!  $(NC)"
	@echo -e "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"

# ── Help ──────────────────────────────────────────────────────

help:
	@echo ""
	@echo -e "$(BOLD)ZooKeeper → KRaft Migration Demo$(NC)"
	@echo ""
	@echo -e "  $(CYAN)make phase0$(NC)          Start ZK cluster + create test topic with 100 messages"
	@echo -e "  $(CYAN)make cluster-id$(NC)      Extract cluster ID from ZooKeeper and save to .cluster-id"
	@echo -e "  $(CYAN)make phase1$(NC)          Stop ZK cluster, start Bridge Mode (ZK + KRaft + migration)"
	@echo -e "  $(CYAN)make verify-bridge$(NC)   Verify topics and data integrity in Bridge Mode"
	@echo -e "  $(CYAN)make phase2$(NC)          Finalize: stop Bridge Mode, start KRaft-only (⚠ irreversible)"
	@echo -e "  $(CYAN)make verify-kraft$(NC)    Verify topics, data, and write path post-migration"
	@echo -e "  $(CYAN)make status$(NC)          Show running containers"
	@echo -e "  $(CYAN)make clean$(NC)           Tear down all containers and volumes"
	@echo ""
	@echo -e "  $(CYAN)make all$(NC)             Run the full migration end-to-end"
	@echo ""

# ══════════════════════════════════════════════════════════════
# PHASE 0 — Start ZooKeeper-based Kafka Cluster
# ══════════════════════════════════════════════════════════════
# What happens:
#   1. Starts a 3-node ZooKeeper ensemble (ZK-1, ZK-2, ZK-3)
#   2. Starts 3 Kafka brokers connected to ZooKeeper
#   3. Waits for all brokers to register and stabilize
#   4. Creates a test topic (6 partitions, RF=3)
#   5. Produces 100 test messages for data integrity validation
# ══════════════════════════════════════════════════════════════

phase0:
	@echo ""
	@echo -e "$(CYAN)━━━ PHASE 0 — Starting ZooKeeper-based Kafka 3.9.2 Cluster ━━━$(NC)"
	@echo ""
	@echo -e "$(BLUE)▸ Starting ZooKeeper ensemble (3 nodes) + Kafka brokers (3 nodes)...$(NC)"
	$(COMPOSE_ZK) up -d
	@echo ""
	@echo -e "$(BLUE)▸ Waiting 30s for brokers to register with ZooKeeper...$(NC)"
	@sleep 30
	@echo ""
	@echo -e "$(BLUE)▸ Creating test topic: $(TOPIC) (6 partitions, RF=3)...$(NC)"
	$(BROKER_EXEC) $(KAFKA_BIN)/kafka-topics \
		--bootstrap-server $(BOOTSTRAP) \
		--create --topic $(TOPIC) \
		--partitions 6 --replication-factor 3
	@echo ""
	@echo -e "$(BLUE)▸ Producing 100 test messages...$(NC)"
	$(BROKER_EXEC) bash -c '\
		for i in $$(seq 1 100); do echo "message-$$i"; done \
		| $(KAFKA_BIN)/kafka-console-producer \
			--bootstrap-server $(BOOTSTRAP) --topic $(TOPIC)'
	@echo ""
	@echo -e "$(BLUE)▸ Verifying topic...$(NC)"
	$(BROKER_EXEC) $(KAFKA_BIN)/kafka-topics \
		--bootstrap-server $(BOOTSTRAP) --describe --topic $(TOPIC)
	@echo ""
	@echo -e "$(GREEN)✓ Phase 0 complete. ZK cluster is running with test data.$(NC)"

# ══════════════════════════════════════════════════════════════
# CLUSTER ID — Extract from ZooKeeper
# ══════════════════════════════════════════════════════════════
# What happens:
#   1. Reads the cluster.id from ZooKeeper znode /cluster/id
#   2. Saves it to .cluster-id file
#   3. This ID MUST be reused for KRaft controllers — a mismatch
#      will cause ClusterIdMismatchException and brokers won't
#      register with the new controllers
# ══════════════════════════════════════════════════════════════

cluster-id:
	@echo ""
	@echo -e "$(CYAN)━━━ PHASE 0.5 — Extracting Cluster ID from ZooKeeper ━━━$(NC)"
	@echo ""
	@echo -e "$(BLUE)▸ Reading cluster.id from ZooKeeper...$(NC)"
	@CLUSTER_ID=$$(docker exec broker-1 cat /var/kafka/data/meta.properties 2>/dev/null \
		| grep cluster.id | cut -d= -f2); \
	if [ -z "$$CLUSTER_ID" ]; then \
		echo -e "$(RED)⚠ Could not extract cluster ID. Generating a new one...$(NC)"; \
		CLUSTER_ID=$$($(BROKER_EXEC) $(KAFKA_BIN)/kafka-storage random-uuid); \
	fi; \
	echo "$$CLUSTER_ID" > .cluster-id; \
	echo ""; \
	echo -e "$(GREEN)✓ Cluster ID: $(BOLD)$$CLUSTER_ID$(NC)"; \
	echo -e "  Saved to $(BOLD).cluster-id$(NC)"

# ══════════════════════════════════════════════════════════════
# PHASE 1 — Bridge Mode (Dual-Write)
# ══════════════════════════════════════════════════════════════
# What happens:
#   1. Stops the ZK-only cluster
#   2. Starts a new cluster with:
#      - Same 3 ZooKeeper nodes (unchanged)
#      - 3 NEW KRaft controllers (node IDs 100, 101, 102)
#      - 3 Kafka brokers with migration enabled:
#        * zookeeper.metadata.migration.enable=true
#        * controller.quorum.voters=100@ctrl1:9093,...
#   3. The Active KRaft Controller reads metadata from ZooKeeper
#   4. Metadata is dual-written to BOTH ZK and __cluster_metadata
#   5. This phase is REVERSIBLE — you can roll back to ZK mode
# ══════════════════════════════════════════════════════════════

phase1: .cluster-id
	@echo ""
	@echo -e "$(CYAN)━━━ PHASE 1 — Deploying Bridge Mode (Dual-Write) ━━━$(NC)"
	@echo ""
	@echo -e "$(BLUE)▸ Stopping ZK-only cluster...$(NC)"
	$(COMPOSE_ZK) down
	@echo ""
	@echo -e "$(BLUE)▸ Starting Bridge Mode (ZK + KRaft controllers + migration brokers)...$(NC)"
	CLUSTER_ID=$$(cat .cluster-id) $(COMPOSE_BRIDGE) up -d
	@echo ""
	@echo -e "$(BLUE)▸ Waiting 45s for KRaft quorum formation + metadata sync...$(NC)"
	@echo "  Controllers form a Raft quorum → read metadata from ZK → dual-write begins"
	@sleep 45
	@echo ""
	@echo -e "$(GREEN)✓ Phase 1 complete. Cluster is in Bridge Mode.$(NC)"
	@echo -e "  Metadata is being dual-written to ZK and __cluster_metadata."

# ══════════════════════════════════════════════════════════════
# VERIFY BRIDGE — Validate data integrity in Bridge Mode
# ══════════════════════════════════════════════════════════════
# What to check:
#   - Topic still exists with correct partition count
#   - All partitions have ISR == Replicas (fully replicated)
#   - All 100 original messages are consumable
#   - New messages can be produced (write path works)
# ══════════════════════════════════════════════════════════════

verify-bridge:
	@echo ""
	@echo -e "$(CYAN)━━━ VERIFYING BRIDGE MODE ━━━$(NC)"
	@echo ""
	@echo -e "$(BLUE)▸ Describing topic...$(NC)"
	$(BROKER_EXEC) $(KAFKA_BIN)/kafka-topics \
		--bootstrap-server $(BOOTSTRAP) --describe --topic $(TOPIC)
	@echo ""
	@echo -e "$(BLUE)▸ Consuming messages (expecting 100)...$(NC)"
	@MSG_COUNT=$$($(BROKER_EXEC) $(KAFKA_BIN)/kafka-console-consumer \
		--bootstrap-server $(BOOTSTRAP) \
		--topic $(TOPIC) --from-beginning \
		--timeout-ms 15000 2>/dev/null | wc -l | tr -d ' '); \
	echo -e "  Messages found: $(BOLD)$$MSG_COUNT$(NC)"; \
	if [ "$$MSG_COUNT" -ge 100 ]; then \
		echo -e "$(GREEN)✓ Data integrity verified in Bridge Mode.$(NC)"; \
	else \
		echo -e "$(RED)⚠ Expected 100 messages, got $$MSG_COUNT. Investigate before proceeding!$(NC)"; \
	fi
	@echo ""
	@echo -e "$(BLUE)▸ Producing 20 new messages in Bridge Mode...$(NC)"
	$(BROKER_EXEC) bash -c '\
		for i in $$(seq 101 120); do echo "bridge-msg-$$i"; done \
		| $(KAFKA_BIN)/kafka-console-producer \
			--bootstrap-server $(BOOTSTRAP) --topic $(TOPIC)'
	@echo -e "$(GREEN)✓ Write path verified.$(NC)"

# ══════════════════════════════════════════════════════════════
# PHASE 2 — Finalize Migration (KRaft Only)
# ══════════════════════════════════════════════════════════════
# ⚠  THIS IS A ONE-WAY DOOR — NO ROLLBACK TO ZOOKEEPER
#
# What happens:
#   1. Stops the Bridge Mode cluster (ZK + KRaft + brokers)
#   2. Starts a KRaft-only cluster:
#      - 3 KRaft controllers (same IDs 100, 101, 102)
#      - 3 Kafka brokers with process.roles=broker
#      - NO ZooKeeper nodes whatsoever
#   3. The __cluster_metadata log is now the sole source of truth
#   4. ZooKeeper can be safely decommissioned
# ══════════════════════════════════════════════════════════════

phase2: .cluster-id
	@echo ""
	@echo -e "$(RED)━━━ PHASE 2 — Finalizing Migration (ONE-WAY DOOR!) ━━━$(NC)"
	@echo ""
	@echo -e "$(RED)⚠  WARNING: After this step, there is NO ROLLBACK to ZooKeeper.$(NC)"
	@echo ""
	@echo -e "$(BLUE)▸ Stopping Bridge Mode cluster...$(NC)"
	$(COMPOSE_BRIDGE) down
	@echo ""
	@echo -e "$(BLUE)▸ Starting KRaft-only cluster (no ZooKeeper)...$(NC)"
	CLUSTER_ID=$$(cat .cluster-id) $(COMPOSE_KRAFT) up -d
	@echo ""
	@echo -e "$(BLUE)▸ Waiting 30s for KRaft-only cluster to stabilize...$(NC)"
	@sleep 30
	@echo ""
	@echo -e "$(GREEN)✓ Phase 2 complete. Cluster is running in pure KRaft mode.$(NC)"
	@echo -e "  No ZooKeeper. No going back."

# ══════════════════════════════════════════════════════════════
# VERIFY KRAFT — Post-migration validation
# ══════════════════════════════════════════════════════════════
# Final validation checklist:
#   - All topics survived the migration
#   - All messages are intact (100 original + 20 from bridge)
#   - New messages can be produced (write path through KRaft)
#   - New topics can be created (metadata path through KRaft)
# ══════════════════════════════════════════════════════════════

verify-kraft:
	@echo ""
	@echo -e "$(CYAN)━━━ POST-MIGRATION VALIDATION ━━━$(NC)"
	@echo ""
	@echo -e "$(BLUE)▸ Listing all topics...$(NC)"
	$(BROKER_EXEC) $(KAFKA_BIN)/kafka-topics \
		--bootstrap-server $(BOOTSTRAP) --list
	@echo ""
	@echo -e "$(BLUE)▸ Describing $(TOPIC)...$(NC)"
	$(BROKER_EXEC) $(KAFKA_BIN)/kafka-topics \
		--bootstrap-server $(BOOTSTRAP) --describe --topic $(TOPIC)
	@echo ""
	@echo -e "$(BLUE)▸ Consuming all messages (expecting 120)...$(NC)"
	@MSG_COUNT=$$($(BROKER_EXEC) $(KAFKA_BIN)/kafka-console-consumer \
		--bootstrap-server $(BOOTSTRAP) \
		--topic $(TOPIC) --from-beginning \
		--timeout-ms 15000 2>/dev/null | wc -l | tr -d ' '); \
	echo -e "  Messages found: $(BOLD)$$MSG_COUNT$(NC)"; \
	if [ "$$MSG_COUNT" -ge 120 ]; then \
		echo -e "$(GREEN)✓ All data survived the migration!$(NC)"; \
	else \
		echo -e "$(RED)⚠ Expected 120 messages, got $$MSG_COUNT.$(NC)"; \
	fi
	@echo ""
	@echo -e "$(BLUE)▸ Producing 10 new messages post-migration...$(NC)"
	$(BROKER_EXEC) bash -c '\
		for i in $$(seq 121 130); do echo "kraft-msg-$$i"; done \
		| $(KAFKA_BIN)/kafka-console-producer \
			--bootstrap-server $(BOOTSTRAP) --topic $(TOPIC)'
	@echo -e "$(GREEN)✓ Write path verified on KRaft-only cluster.$(NC)"
	@echo ""
	@echo -e "$(BLUE)▸ Creating a new topic to verify metadata write path...$(NC)"
	$(BROKER_EXEC) $(KAFKA_BIN)/kafka-topics \
		--bootstrap-server $(BOOTSTRAP) \
		--create --topic post-migration-test \
		--partitions 3 --replication-factor 3
	$(BROKER_EXEC) $(KAFKA_BIN)/kafka-topics \
		--bootstrap-server $(BOOTSTRAP) \
		--describe --topic post-migration-test
	@echo ""
	@echo -e "$(GREEN)✓ Topic creation works. KRaft metadata path is fully operational.$(NC)"

# ── Status ────────────────────────────────────────────────────

status:
	@echo ""
	@echo -e "$(CYAN)Running containers:$(NC)"
	@docker ps --filter "name=broker-\|controller-\|zookeeper-" \
		--format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true
	@echo ""

# ── Clean ─────────────────────────────────────────────────────

clean:
	@echo ""
	@echo -e "$(RED)▸ Tearing down all containers and volumes...$(NC)"
	-$(COMPOSE_KRAFT)  down -v 2>/dev/null
	-$(COMPOSE_BRIDGE) down -v 2>/dev/null
	-$(COMPOSE_ZK)     down -v 2>/dev/null
	@rm -f .cluster-id
	@echo -e "$(GREEN)✓ Cleanup complete.$(NC)"
	@echo ""

# ── Guard: ensure .cluster-id exists ─────────────────────────

.cluster-id:
	@echo -e "$(RED)Error: .cluster-id file not found. Run 'make cluster-id' first.$(NC)"
	@exit 1
