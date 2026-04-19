# ─────────────────────────────────────────────────────────────
# Local Binary Kafka Migration Demo Makefile
# ─────────────────────────────────────────────────────────────

KAFKA_VERSION := 3.9.0
SCALA_VERSION := 2.13
KAFKA_ARCHIVE := kafka_$(SCALA_VERSION)-$(KAFKA_VERSION).tgz
KAFKA_URL     := https://archive.apache.org/dist/kafka/$(KAFKA_VERSION)/$(KAFKA_ARCHIVE)
KAFKA_DIR     := kafka-dist
KAFKA_BIN     := $(KAFKA_DIR)/bin

KAFKA_VERSION_V4 := 4.2.0
KAFKA_ARCHIVE_V4 := kafka_$(SCALA_VERSION)-$(KAFKA_VERSION_V4).tgz
KAFKA_URL_V4     := https://archive.apache.org/dist/kafka/$(KAFKA_VERSION_V4)/$(KAFKA_ARCHIVE_V4)
KAFKA_DIR_V4     := kafka-dist-v4
KAFKA_BIN_V4     := $(KAFKA_DIR_V4)/bin

CONFIG_DIR    := config
DATA_DIR      := data
LOGS_DIR      := logs
PIDS_DIR      := .pids

# Define colors for output
GREEN  :=\033[0;32m
YELLOW :=\033[1;33m
RED    :=\033[0;31m
CYAN   :=\033[0;36m
NC     :=\033[0m

define tui_cmd
	@echo "\n$(CYAN)╭─ ⚡ $(YELLOW)$(1)$(NC)"
	@echo "$(CYAN)├──────────────────────────────────────────────────────────────────────────$(NC)"
	@echo "$(CYAN)│ $(NC)▶  $(2)$(NC)"
	@echo "$(CYAN)╰──────────────────────────────────────────────────────────────────────────$(NC)"
endef

.PHONY: help download download-v4 setup-dirs start cluster-id check-version list-topics produce-messages consume-messages controllers bridge kraft verify-bridge verify-zookeeper verify-controllers verify-kraft upgrade zk-failover controller-failover metadata-shell quorum-status scale-partitions restart-brokers check-pid status watch kill clean all

help:
	@echo "$(CYAN)Kafka Binary Migration Demo Targets$(NC)"
	@echo "-----------------------------------"
	@echo "$(YELLOW)download$(NC)             - Download Kafka $(KAFKA_VERSION) tarball"
	@echo "$(YELLOW)start$(NC)                - Start ZK Ensemble + Kafka Brokers (ZK Mode)"
	@echo "$(YELLOW)cluster-id$(NC)           - Extract cluster ID via zookeeper-shell string parsing"
	@echo "$(YELLOW)check-version$(NC)        - Print the downloaded Kafka binary version"
	@echo "$(YELLOW)list-topics$(NC)          - List all current topics in the cluster"
	@echo "$(YELLOW)produce-messages$(NC)     - Open an interactive console producer"
	@echo "$(YELLOW)consume-messages$(NC)     - Consume all messages from 'devoxx-topic'"
	@echo "$(YELLOW)controllers$(NC)          - Format and start KRaft Controllers cleanly before bridging"
	@echo "$(YELLOW)bridge$(NC)               - Rolling Restart of Brokers into Bridge Mode"
	@echo "$(YELLOW)verify-bridge$(NC)        - Verify topics & produce messages in Bridge Mode"
	@echo "$(YELLOW)verify-zookeeper$(NC)     - Poll Zookeeper znodes to prove topological health"
	@echo "$(YELLOW)verify-controllers$(NC)   - Interrogate KRaft quorum to prove meta-data election"
	@echo "$(YELLOW)kraft$(NC)                - Finalize KRaft (Irreversible!) - Restart brokers in KRaft mode"
	@echo "$(YELLOW)verify-kraft$(NC)         - Final validation + create new topic"
	@echo "$(YELLOW)upgrade$(NC)              - Rolling Upgrade to Kafka V4 (Phase 3)"
	@echo ""
	@echo "$(CYAN)Failover Demo Targets$(NC)"
	@echo "-----------------------------------"
	@echo "$(YELLOW)zk-failover$(NC)          - Kill active ZK controller broker and time failover"
	@echo "$(YELLOW)controller-failover$(NC)  - Kill active KRaft leader and time recovery"
	@echo ""
	@echo "$(CYAN)KRaft Demo Targets$(NC)"
	@echo "-----------------------------------"
	@echo "$(YELLOW)metadata-shell$(NC)       - Browse the __cluster_metadata log interactively"
	@echo "$(YELLOW)quorum-status$(NC)        - Show KRaft replication status with lag details"
	@echo "$(YELLOW)scale-partitions$(NC)     - Create a 10,000-partition topic instantly (KRaft power)"
	@echo ""
	@echo "$(CYAN)Utilities$(NC)"
	@echo "-----------------------------------"
	@echo "$(YELLOW)check-pid$(NC)            - Check details of a specific process (usage: make check-pid PID=123)"
	@echo "$(YELLOW)status$(NC)               - Check running Java PIDs"
	@echo "$(YELLOW)watch$(NC)                - Live-updating status dashboard (refreshes every 2s)"
	@echo "$(YELLOW)clean$(NC)                - Kill all PIDs and wipe data/logs"
	@echo "$(YELLOW)all$(NC)                  - Run full automated migration"

# ── Download ──────────────────────────────────────────────────

download:
	@if [ ! -d "$(KAFKA_DIR)" ]; then \
		echo "$(CYAN)▸ Downloading Kafka $(KAFKA_VERSION)...$(NC)"; \
		curl -O $(KAFKA_URL); \
		tar -xzf $(KAFKA_ARCHIVE); \
		mv kafka_$(SCALA_VERSION)-$(KAFKA_VERSION) $(KAFKA_DIR); \
		rm $(KAFKA_ARCHIVE); \
		echo "$(GREEN)✓ Download complete.$(NC)"; \
	else \
		echo "$(GREEN)✓ Kafka $(KAFKA_VERSION) already downloaded.$(NC)"; \
	fi

download-v4:
	@if [ ! -d "$(KAFKA_DIR_V4)" ]; then \
		echo "$(CYAN)▸ Downloading Kafka V4 $(KAFKA_VERSION_V4)...$(NC)"; \
		curl -O $(KAFKA_URL_V4) >/dev/null 2>&1; \
		tar -xzf $(KAFKA_ARCHIVE_V4); \
		mv kafka_$(SCALA_VERSION)-$(KAFKA_VERSION_V4) $(KAFKA_DIR_V4); \
		rm $(KAFKA_ARCHIVE_V4); \
		echo "$(GREEN)✓ V4 Download complete.$(NC)"; \
	else \
		echo "$(GREEN)✓ Kafka V4 $(KAFKA_VERSION_V4) already downloaded.$(NC)"; \
	fi

setup-dirs:
	@mkdir -p $(DATA_DIR)/zk1 $(DATA_DIR)/zk2 $(DATA_DIR)/zk3
	@mkdir -p $(DATA_DIR)/broker1 $(DATA_DIR)/broker2 $(DATA_DIR)/broker3
	@mkdir -p $(DATA_DIR)/controller1 $(DATA_DIR)/controller2 $(DATA_DIR)/controller3
	@mkdir -p $(LOGS_DIR) $(PIDS_DIR)
	@echo "1" > $(DATA_DIR)/zk1/myid
	@echo "2" > $(DATA_DIR)/zk2/myid
	@echo "3" > $(DATA_DIR)/zk3/myid

# ── Process Management Utility ────────────────────────────────

kill:
	@echo "$(YELLOW)▸ Killing all tracked demo processes...$(NC)"
	@for pidfile in $(PIDS_DIR)/*.pid; do \
		if [ -f "$$pidfile" ]; then \
			pid=$$(cat $$pidfile); \
			kill -9 $$pid 2>/dev/null || true; \
			rm $$pidfile; \
		fi \
	done
	@echo "$(YELLOW)▸ Sweeping for orphaned Kafka/ZK JVMs...$(NC)"
	@pkill -f "config/zk" 2>/dev/null || true
	@pkill -f "config/phase" 2>/dev/null || true
	@sleep 2
	@echo "$(GREEN)✓ All processes killed.$(NC)"

# ── Phase 0 ───────────────────────────────────────────────────

start: download setup-dirs
	@echo "\n$(CYAN)━━━ PHASE 0 — ZooKeeper Mode ━━━$(NC)"
	
	$(call tui_cmd,Starting ZooKeepers (2GB Heap),zookeeper-server-start.sh zkX.properties)
	@KAFKA_HEAP_OPTS="-Xmx2G -Xms2G" $(KAFKA_BIN)/zookeeper-server-start.sh $(CONFIG_DIR)/zk1.properties > $(LOGS_DIR)/zk1.log 2>&1 & echo $$! > $(PIDS_DIR)/zk1.pid
	@KAFKA_HEAP_OPTS="-Xmx2G -Xms2G" $(KAFKA_BIN)/zookeeper-server-start.sh $(CONFIG_DIR)/zk2.properties > $(LOGS_DIR)/zk2.log 2>&1 & echo $$! > $(PIDS_DIR)/zk2.pid
	@KAFKA_HEAP_OPTS="-Xmx2G -Xms2G" $(KAFKA_BIN)/zookeeper-server-start.sh $(CONFIG_DIR)/zk3.properties > $(LOGS_DIR)/zk3.log 2>&1 & echo $$! > $(PIDS_DIR)/zk3.pid
	@sleep 5
	
	$(call tui_cmd,Starting Legacy Kafka Brokers (4GB Heap),kafka-server-start.sh phase0/brokerX.properties)
	@KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/phase0/broker1.properties > $(LOGS_DIR)/broker1.log 2>&1 & echo $$! > $(PIDS_DIR)/broker1.pid
	@KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/phase0/broker2.properties > $(LOGS_DIR)/broker2.log 2>&1 & echo $$! > $(PIDS_DIR)/broker2.pid
	@KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/phase0/broker3.properties > $(LOGS_DIR)/broker3.log 2>&1 & echo $$! > $(PIDS_DIR)/broker3.pid
	
	@echo "$(GREEN)▸ Waiting 15s for brokers to register...$(NC)"
	@sleep 15
	
	$(call tui_cmd,Creating test topic scaffolding,kafka-topics.sh --create --topic devoxx-topic)
	@$(KAFKA_BIN)/kafka-topics.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --create --topic devoxx-topic --partitions 6 --replication-factor 3 2>/dev/null || true
	@echo "$(GREEN)✓ Phase 0 complete.$(NC)"

# ── ZooKeeper Failover Demo ───────────────────────────────────

zk-failover:
	@echo "\n$(CYAN)━━━ ZooKeeper Demo: Controller Failover Recovery ━━━$(NC)"
	$(call tui_cmd,Identifying Active ZK Controller Broker,zookeeper-shell.sh get /controller)
	@CTRL_JSON=$$($(KAFKA_BIN)/zookeeper-shell.sh localhost:2181 get /controller 2>/dev/null | grep 'brokerid'); \
	if [ -z "$$CTRL_JSON" ]; then \
		echo "$(RED)! ZooKeeper is offline or no controller elected.$(NC)"; exit 1; \
	fi; \
	BROKER_ID=$$(echo "$$CTRL_JSON" | grep -o '"brokerid":[0-9]*' | cut -d: -f2); \
	echo "$(GREEN)   Active ZK Controller: Broker $$BROKER_ID$(NC)"; \
	PID_FILE="$(PIDS_DIR)/broker$$BROKER_ID.pid"; \
	if [ ! -f "$$PID_FILE" ]; then \
		echo "$(RED)! PID file not found for broker $$BROKER_ID.$(NC)"; exit 1; \
	fi; \
	echo ""; \
	echo "$(CYAN)╭─ ⚡ $(YELLOW)Killing Active ZK Controller (Broker $$BROKER_ID)$(NC)"; \
	echo "$(CYAN)├──────────────────────────────────────────────────────────────────────────$(NC)"; \
	echo "$(CYAN)│ $(NC)▶  kill -9 $$(cat $$PID_FILE)$(NC)"; \
	echo "$(CYAN)╰──────────────────────────────────────────────────────────────────────────$(NC)"; \
	kill -9 $$(cat $$PID_FILE) 2>/dev/null || true; \
	START_TIME=$$(python3 -c 'import time; print(time.time())'); \
	echo "$(YELLOW)▸ Controller killed. Waiting for ZooKeeper to elect a new controller...$(NC)"; \
	echo "$(YELLOW)  (This typically takes 30-90 seconds with ZooKeeper)$(NC)"; \
	while true; do \
		NEW_JSON=$$($(KAFKA_BIN)/zookeeper-shell.sh localhost:2181 get /controller 2>/dev/null | grep 'brokerid' || true); \
		if [ -n "$$NEW_JSON" ]; then \
			NEW_BROKER=$$(echo "$$NEW_JSON" | grep -o '"brokerid":[0-9]*' | cut -d: -f2); \
			if [ -n "$$NEW_BROKER" ] && [ "$$NEW_BROKER" != "$$BROKER_ID" ]; then \
				END_TIME=$$(python3 -c 'import time; print(time.time())'); \
				ELAPSED=$$(python3 -c "print(f'{$$END_TIME - $$START_TIME:.2f}')"); \
				echo "$(GREEN)✓ New ZK Controller elected: Broker $$NEW_BROKER in $${ELAPSED}s$(NC)"; \
				break; \
			fi; \
		fi; \
		sleep 1; \
	done; \
	echo "$(YELLOW)▸ Restarting killed broker to rejoin cluster...$(NC)"; \
	CONFIG_PHASE="phase0"; \
	if [ -f "$(CONFIG_DIR)/phase2/broker$$BROKER_ID.properties" ] && ! [ -f "$(PIDS_DIR)/zk1.pid" ]; then \
		CONFIG_PHASE="phase2"; \
	elif [ -f "$(CONFIG_DIR)/phase1/broker$$BROKER_ID.properties" ] && [ -f "$(PIDS_DIR)/controller1.pid" ]; then \
		CONFIG_PHASE="phase1"; \
	fi; \
	KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/$$CONFIG_PHASE/broker$$BROKER_ID.properties > $(LOGS_DIR)/broker$$BROKER_ID.log 2>&1 & echo $$! > $(PIDS_DIR)/broker$$BROKER_ID.pid; \
	echo "$(GREEN)✓ Broker $$BROKER_ID restarted and rejoining cluster.$(NC)"; \
	echo ""; \
	echo "$(CYAN)┌─────────────────────────────────────────────────────────────┐$(NC)"; \
	echo "$(CYAN)│$(NC)  $(YELLOW)Compare this with 'make controller-failover' in KRaft mode$(NC)  $(CYAN)│$(NC)"; \
	echo "$(CYAN)│$(NC)  $(YELLOW)to see the dramatic improvement in election speed!$(NC)        $(CYAN)│$(NC)"; \
	echo "$(CYAN)└─────────────────────────────────────────────────────────────┘$(NC)"

# ── Extract Cluster ID ────────────────────────────────────────

cluster-id:
	@echo "\n$(CYAN)━━━ PHASE 0.5 — Extracting Cluster ID ━━━$(NC)"
	$(call tui_cmd,Extracting Active Cluster ID via ZK Shell String Parity,zookeeper-shell.sh localhost:2181 get /cluster/id)
	@CLUSTER_ID=$$($(KAFKA_BIN)/zookeeper-shell.sh localhost:2181 get /cluster/id 2>/dev/null | grep -o '"id":"[^"]*"' | cut -d'"' -f4); \
	if [ -z "$$CLUSTER_ID" ]; then \
		echo "$(RED)! Cannot extract cluster ID. ZK might be down.$(NC)"; exit 1; \
	fi; \
	echo "$$CLUSTER_ID" > .cluster-id; \
	echo "$(GREEN)✓ Captured existing Cluster ID: $$CLUSTER_ID$(NC)"; \

# ── Utilities ─────────────────────────────────────────────────

check-version:
	@echo "\n$(CYAN)━━━ Kafka Version ━━━$(NC)"
	@if [ -f "$(PIDS_DIR)/broker1.pid" ] && ps -p $$(cat $(PIDS_DIR)/broker1.pid) > /dev/null 2>&1; then \
		if ps -f -p $$(cat $(PIDS_DIR)/broker1.pid) | grep -q "kafka-dist-v4"; then \
			echo "$(YELLOW)▸ Active Brokers running V4 Binary (4.2.0):$(NC)"; \
			$(KAFKA_BIN_V4)/kafka-topics.sh --version; \
			echo "\n$(YELLOW)▸ Active Cluster Feature Metadata (Parsed via V4):$(NC)"; \
			$(KAFKA_BIN_V4)/kafka-features.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 describe 2>/dev/null || echo "$(RED)Cluster is currently offline or unreachable.$(NC)"; \
		else \
			echo "$(YELLOW)▸ Active Brokers running V3 Binary (3.9.x):$(NC)"; \
			$(KAFKA_BIN)/kafka-topics.sh --version; \
			echo "\n$(YELLOW)▸ Active Cluster Feature Metadata (Parsed via V3):$(NC)"; \
			$(KAFKA_BIN)/kafka-features.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 describe 2>/dev/null || echo "$(RED)Cluster is currently offline or unreachable.$(NC)"; \
		fi \
	else \
		echo "$(RED)▸ Cluster broker1 is offline. Cannot determine running version.$(NC)"; \
	fi

list-topics:
	@echo "\n$(CYAN)━━━ Listing All Topics ━━━$(NC)"
	@$(KAFKA_BIN)/kafka-topics.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --list

produce-messages:
	@echo "\n$(CYAN)━━━ Auto-Publishing to 'devoxx-topic' ━━━$(NC)"
	@echo "$(YELLOW)Sending an incremented message every 1 second. Press Ctrl+C to stop.$(NC)"
	@python3 -u scripts/producer.py 2>/dev/null | $(KAFKA_BIN)/kafka-console-producer.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --topic devoxx-topic 2>/dev/null; true

consume-messages:
	@echo "\n$(CYAN)━━━ Reading from 'devoxx-topic' ━━━$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop.$(NC)"
	@$(KAFKA_BIN)/kafka-console-consumer.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --topic devoxx-topic --from-beginning 2>/dev/null || true
	@echo "\n$(GREEN)✓ Consumer stopped gracefully.$(NC)"

# ── Phase 0.5 ─────────────────────────────────────────────────

controllers:
	@echo "\n$(CYAN)━━━ PHASE 0.5 — KRaft Controller Quorum Initialization ━━━$(NC)"
	@if [ ! -f .cluster-id ]; then echo "$(RED)No .cluster-id found. Run 'make cluster-id' first.$(NC)"; exit 1; fi
	
	$(call tui_cmd,Formatting KRaft Controllers with isolated cluster ID,kafka-storage.sh format)
	@$(KAFKA_BIN)/kafka-storage.sh format -t $$(cat .cluster-id) -c $(CONFIG_DIR)/phase1/controller1.properties --ignore-formatted >/dev/null 2>&1
	@$(KAFKA_BIN)/kafka-storage.sh format -t $$(cat .cluster-id) -c $(CONFIG_DIR)/phase1/controller2.properties --ignore-formatted >/dev/null 2>&1
	@$(KAFKA_BIN)/kafka-storage.sh format -t $$(cat .cluster-id) -c $(CONFIG_DIR)/phase1/controller3.properties --ignore-formatted >/dev/null 2>&1
	
	$(call tui_cmd,Starting KRaft Controllers (Forming Initial Quorum),kafka-server-start.sh phase1/controllerX.properties)
	@$(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/phase1/controller1.properties > $(LOGS_DIR)/controller1.log 2>&1 & echo $$! > $(PIDS_DIR)/controller1.pid
	@$(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/phase1/controller2.properties > $(LOGS_DIR)/controller2.log 2>&1 & echo $$! > $(PIDS_DIR)/controller2.pid
	@$(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/phase1/controller3.properties > $(LOGS_DIR)/controller3.log 2>&1 & echo $$! > $(PIDS_DIR)/controller3.pid
	@sleep 5
	@echo "$(GREEN)✓ KRaft Controllers successfully booted metadata quorum!$(NC)"

# ── Phase 1 ───────────────────────────────────────────────────

bridge:
	@echo "\n$(CYAN)━━━ PHASE 1 — Bridge Mode (Dual Write) ━━━$(NC)"
	
	$(call tui_cmd,Rolling Restart: Broker 1 (Bridge Mode Dual-Write Array),kafka-server-start.sh phase1/broker1.properties)
	@kill -15 $$(cat $(PIDS_DIR)/broker1.pid) 2>/dev/null || true
	@sleep 6
	@KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/phase1/broker1.properties > $(LOGS_DIR)/broker1.log 2>&1 & echo $$! > $(PIDS_DIR)/broker1.pid
	@sleep 6
	
	$(call tui_cmd,Rolling Restart: Broker 2 (Bridge Mode Dual-Write Array),kafka-server-start.sh phase1/broker2.properties)
	@kill -15 $$(cat $(PIDS_DIR)/broker2.pid) 2>/dev/null || true
	@sleep 6
	@KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/phase1/broker2.properties > $(LOGS_DIR)/broker2.log 2>&1 & echo $$! > $(PIDS_DIR)/broker2.pid
	@sleep 6
	
	$(call tui_cmd,Rolling Restart: Broker 3 (Bridge Mode Dual-Write Array),kafka-server-start.sh phase1/broker3.properties)
	@kill -15 $$(cat $(PIDS_DIR)/broker3.pid) 2>/dev/null || true
	@sleep 6
	@KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/phase1/broker3.properties > $(LOGS_DIR)/broker3.log 2>&1 & echo $$! > $(PIDS_DIR)/broker3.pid
	
	@echo "$(GREEN)▸ Waiting 15s for Bridge registration...$(NC)"
	@sleep 15
	@echo "$(GREEN)✓ Phase 1 complete.$(NC)"

# ── Verifications ─────────────────────────────────────────────

verify-zookeeper:
	@echo "\n$(CYAN)━━━ VERIFY: ZooKeeper Topology ━━━$(NC)"
	@echo "$(YELLOW)▸ Checking active broker connections inside ZK RAM:$(NC)"
	@$(KAFKA_BIN)/zookeeper-shell.sh localhost:2181 ls /brokers/ids 2>/dev/null || echo "$(RED) ZooKeeper offline.$(NC)"
	@echo "\n$(YELLOW)▸ Checking Broker 1 exact metadata map:$(NC)"
	@$(KAFKA_BIN)/zookeeper-shell.sh localhost:2181 get /brokers/ids/1 2>/dev/null || echo "$(RED) Broker 1 offline.$(NC)"

verify-controllers:
	@echo "\n$(CYAN)━━━ VERIFY: KRaft Controller Quorum ━━━$(NC)"
	@echo "$(YELLOW)▸ Fetching consensus metadata via kafka-metadata-quorum.sh:$(NC)"
	@$(KAFKA_BIN)/kafka-metadata-quorum.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 describe --status 2>/dev/null || echo "$(RED) KRaft Quorum offline or unreachable.$(NC)"

verify-bridge:
	@echo "$(CYAN)━━━ VERIFY: Bridge Mode ━━━$(NC)"
	@$(KAFKA_BIN)/kafka-topics.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --describe
	@echo "\n$(YELLOW)▸ Reading actively buffered test messages...$(NC)"
	@MSG_COUNT=$$($(KAFKA_BIN)/kafka-console-consumer.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --topic devoxx-topic --from-beginning --timeout-ms 5000 2>/dev/null | wc -l); \
	echo "$(GREEN)   Stream aggregate currently holds $$MSG_COUNT messages.$(NC)"
	@echo "$(GREEN)✓ Bridge verification complete.$(NC)"

verify-kraft:
	@echo "$(CYAN)━━━ VERIFY: KRaft Mode ━━━$(NC)"
	@echo "$(YELLOW)▸ Reading final dynamic message pipeline aggregate...$(NC)"
	@MSG_COUNT=$$($(KAFKA_BIN)/kafka-console-consumer.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --topic devoxx-topic --from-beginning --timeout-ms 5000 2>/dev/null | wc -l); \
	echo "$(GREEN)   Successfully recovered exactly $$MSG_COUNT messages across the legacy void.$(NC)"
	@echo "$(YELLOW)▸ Validating Topic Creation without ZK...$(NC)"
	@$(KAFKA_BIN)/kafka-topics.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --create --topic post-migration-topic --partitions 3 --replication-factor 3
	@$(KAFKA_BIN)/kafka-topics.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --describe --topic post-migration-topic
	@echo "$(GREEN)✓ Migration 100% Successful!$(NC)"

# ── Phase 2 ───────────────────────────────────────────────────

kraft:
	@echo "\n$(CYAN)━━━ PHASE 2 — KRaft Only Mode (Irreversible) ━━━$(NC)"
	
	$(call tui_cmd,Rolling Restart: Broker 1 (KRaft Mode Only),kafka-server-start.sh phase2/broker1.properties)
	@kill -15 $$(cat $(PIDS_DIR)/broker1.pid) 2>/dev/null || true
	@sleep 6
	@KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/phase2/broker1.properties > $(LOGS_DIR)/broker1.log 2>&1 & echo $$! > $(PIDS_DIR)/broker1.pid
	@sleep 6
	
	$(call tui_cmd,Rolling Restart: Broker 2 (KRaft Mode Only),kafka-server-start.sh phase2/broker2.properties)
	@kill -15 $$(cat $(PIDS_DIR)/broker2.pid) 2>/dev/null || true
	@sleep 6
	@KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/phase2/broker2.properties > $(LOGS_DIR)/broker2.log 2>&1 & echo $$! > $(PIDS_DIR)/broker2.pid
	@sleep 6
	
	$(call tui_cmd,Rolling Restart: Broker 3 (KRaft Mode Only),kafka-server-start.sh phase2/broker3.properties)
	@kill -15 $$(cat $(PIDS_DIR)/broker3.pid) 2>/dev/null || true
	@sleep 6
	@KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/phase2/broker3.properties > $(LOGS_DIR)/broker3.log 2>&1 & echo $$! > $(PIDS_DIR)/broker3.pid
	@sleep 6
	
	$(call tui_cmd,Permanently Decoupling ZooKeeper Quorum,kill -15 zkX.pid)
	@kill -15 $$(cat $(PIDS_DIR)/zk1.pid) $$(cat $(PIDS_DIR)/zk2.pid) $$(cat $(PIDS_DIR)/zk3.pid) 2>/dev/null || true
	@rm $(PIDS_DIR)/zk*.pid || true
	
	@echo "$(GREEN)✓ Phase 2 complete. ZooKeeper is dead!$(NC)"

# ── Phase 3 ───────────────────────────────────────────────────

upgrade: download-v4
	@echo "\n$(CYAN)━━━ PHASE 3 — Kafka 4.2.0 Rolling Upgrade ━━━$(NC)"
	
	@echo "\n$(YELLOW)▸ 1. Rolling Upgrade: Control Plane (Controllers to V4)...$(NC)"
	$(call tui_cmd,Rolling Upgrade: Controller 1 up to Kafka V4,kafka-server-start.sh phase3/controller1.properties)
	@kill -15 $$(cat $(PIDS_DIR)/controller1.pid) 2>/dev/null || true
	@sleep 6
	@KAFKA_HEAP_OPTS="-Xmx1G -Xms1G" $(KAFKA_BIN_V4)/kafka-server-start.sh $(CONFIG_DIR)/phase3/controller1.properties > $(LOGS_DIR)/controller1.log 2>&1 & echo $$! > $(PIDS_DIR)/controller1.pid
	@sleep 6

	$(call tui_cmd,Rolling Upgrade: Controller 2 up to Kafka V4,kafka-server-start.sh phase3/controller2.properties)
	@kill -15 $$(cat $(PIDS_DIR)/controller2.pid) 2>/dev/null || true
	@sleep 6
	@KAFKA_HEAP_OPTS="-Xmx1G -Xms1G" $(KAFKA_BIN_V4)/kafka-server-start.sh $(CONFIG_DIR)/phase3/controller2.properties > $(LOGS_DIR)/controller2.log 2>&1 & echo $$! > $(PIDS_DIR)/controller2.pid
	@sleep 6

	$(call tui_cmd,Rolling Upgrade: Controller 3 up to Kafka V4,kafka-server-start.sh phase3/controller3.properties)
	@kill -15 $$(cat $(PIDS_DIR)/controller3.pid) 2>/dev/null || true
	@sleep 6
	@KAFKA_HEAP_OPTS="-Xmx1G -Xms1G" $(KAFKA_BIN_V4)/kafka-server-start.sh $(CONFIG_DIR)/phase3/controller3.properties > $(LOGS_DIR)/controller3.log 2>&1 & echo $$! > $(PIDS_DIR)/controller3.pid
	@sleep 6

	@echo "\n$(YELLOW)▸ 2. Rolling Upgrade: Data Plane (Brokers to V4)...$(NC)"
	
	$(call tui_cmd,Rolling Upgrade: Broker 1 up to Kafka V4,kafka-server-start.sh phase3/broker1.properties)
	@kill -15 $$(cat $(PIDS_DIR)/broker1.pid) 2>/dev/null || true
	@sleep 6
	@KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN_V4)/kafka-server-start.sh $(CONFIG_DIR)/phase3/broker1.properties > $(LOGS_DIR)/broker1.log 2>&1 & echo $$! > $(PIDS_DIR)/broker1.pid
	@sleep 6

	$(call tui_cmd,Rolling Upgrade: Broker 2 up to Kafka V4,kafka-server-start.sh phase3/broker2.properties)
	@kill -15 $$(cat $(PIDS_DIR)/broker2.pid) 2>/dev/null || true
	@sleep 6
	@KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN_V4)/kafka-server-start.sh $(CONFIG_DIR)/phase3/broker2.properties > $(LOGS_DIR)/broker2.log 2>&1 & echo $$! > $(PIDS_DIR)/broker2.pid
	@sleep 6

	$(call tui_cmd,Rolling Upgrade: Broker 3 up to Kafka V4,kafka-server-start.sh phase3/broker3.properties)
	@kill -15 $$(cat $(PIDS_DIR)/broker3.pid) 2>/dev/null || true
	@sleep 6
	@KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN_V4)/kafka-server-start.sh $(CONFIG_DIR)/phase3/broker3.properties > $(LOGS_DIR)/broker3.log 2>&1 & echo $$! > $(PIDS_DIR)/broker3.pid
	
	@echo "$(GREEN)▸ Waiting 20s for the KRaft Quorum to synchronize Node features...$(NC)"
	@sleep 20
	
	@echo "\n$(YELLOW)▸ 3. Finalizing Metadata Feature Version Bump...$(NC)"
	
	$(call tui_cmd,Dynamically Mapping Cluster Metadata Version to 4.2.0 Schema Abstract,kafka-features.sh upgrade --release-version 4.2)
	@$(KAFKA_BIN_V4)/kafka-features.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 upgrade --release-version 4.2
	@echo "$(GREEN)✓ Upgrade sequence complete. Cluster is natively executing Kafka 4.2.0!$(NC)"

# ── KRaft Demo Targets ────────────────────────────────────────

controller-failover:
	@echo "\n$(CYAN)━━━ KRaft Demo: Controller Failover Recovery ━━━$(NC)"
	$(call tui_cmd,Identifying Active KRaft Leader,kafka-metadata-quorum.sh describe --status)
	@LEADER_ID=$$($(KAFKA_BIN)/kafka-metadata-quorum.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 describe --status 2>/dev/null | grep 'LeaderId' | awk '{print $$NF}'); \
	if [ -z "$$LEADER_ID" ]; then \
		echo "$(RED)! KRaft quorum is offline. Start controllers first.$(NC)"; exit 1; \
	fi; \
	echo "$(GREEN)   Active Leader: Node $$LEADER_ID$(NC)"; \
	PID_FILE="$(PIDS_DIR)/controller$$(($$LEADER_ID - 99)).pid"; \
	if [ ! -f "$$PID_FILE" ]; then \
		echo "$(RED)! PID file not found for controller leader.$(NC)"; exit 1; \
	fi; \
	echo "";\
	echo "$(CYAN)╭─ ⚡ $(YELLOW)Killing Active Leader (Node $$LEADER_ID)$(NC)"; \
	echo "$(CYAN)├──────────────────────────────────────────────────────────────────────────$(NC)"; \
	echo "$(CYAN)│ $(NC)▶  kill -9 $$(cat $$PID_FILE)$(NC)"; \
	echo "$(CYAN)╰──────────────────────────────────────────────────────────────────────────$(NC)"; \
	kill -9 $$(cat $$PID_FILE) 2>/dev/null || true; \
	START_TIME=$$(python3 -c 'import time; print(time.time())'); \
	echo "$(YELLOW)▸ Leader killed. Waiting for new election...$(NC)"; \
	while true; do \
		NEW_LEADER=$$($(KAFKA_BIN)/kafka-metadata-quorum.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 describe --status 2>/dev/null | grep 'LeaderId' | awk '{print $$NF}'); \
		if [ -n "$$NEW_LEADER" ] && [ "$$NEW_LEADER" != "$$LEADER_ID" ]; then \
			END_TIME=$$(python3 -c 'import time; print(time.time())'); \
			ELAPSED=$$(python3 -c "print(f'{$$END_TIME - $$START_TIME:.2f}')"); \
			echo "$(GREEN)✓ New Leader elected: Node $$NEW_LEADER in $${ELAPSED}s$(NC)"; \
			break; \
		fi; \
		sleep 0.5; \
	done; \
	echo "$(YELLOW)▸ Restarting killed controller to rejoin quorum...$(NC)"; \
	CTRL_NUM=$$(($$LEADER_ID - 99)); \
	CONFIG_PHASE="phase1"; \
	if [ -d "$(KAFKA_DIR_V4)" ] && ps -f -p $$(cat $(PIDS_DIR)/broker1.pid 2>/dev/null) 2>/dev/null | grep -q "kafka-dist-v4"; then \
		CONFIG_PHASE="phase3"; \
		KAFKA_HEAP_OPTS="-Xmx1G -Xms1G" $(KAFKA_BIN_V4)/kafka-server-start.sh $(CONFIG_DIR)/$$CONFIG_PHASE/controller$$CTRL_NUM.properties > $(LOGS_DIR)/controller$$CTRL_NUM.log 2>&1 & echo $$! > $(PIDS_DIR)/controller$$CTRL_NUM.pid; \
	else \
		$(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/$$CONFIG_PHASE/controller$$CTRL_NUM.properties > $(LOGS_DIR)/controller$$CTRL_NUM.log 2>&1 & echo $$! > $(PIDS_DIR)/controller$$CTRL_NUM.pid; \
	fi; \
	echo "$(GREEN)✓ Controller $$CTRL_NUM restarted and rejoining quorum.$(NC)"

metadata-shell:
	@echo "\n$(CYAN)━━━ KRaft Demo: Cluster Metadata Log Inspection ━━━$(NC)"
	$(call tui_cmd,Dumping __cluster_metadata records (last 30),kafka-dump-log.sh --cluster-metadata-decoder)
	@LATEST_LOG=$$(ls -t $(DATA_DIR)/controller1/__cluster_metadata-0/*.log 2>/dev/null | head -1); \
	if [ -z "$$LATEST_LOG" ]; then \
		echo "$(RED)! No __cluster_metadata log found. Start controllers first.$(NC)"; exit 1; \
	fi; \
	$(KAFKA_BIN)/kafka-dump-log.sh --cluster-metadata-decoder --files $$LATEST_LOG 2>/dev/null | tail -80

quorum-status:
	@echo "\n$(CYAN)━━━ KRaft Demo: Raft Quorum Replication Status ━━━$(NC)"
	$(call tui_cmd,Quorum Leadership Status,kafka-metadata-quorum.sh describe --status)
	@$(KAFKA_BIN)/kafka-metadata-quorum.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 describe --status 2>/dev/null || echo "$(RED) KRaft Quorum offline.$(NC)"
	@echo ""
	$(call tui_cmd,Quorum Replication Details (Follower Lag),kafka-metadata-quorum.sh describe --replication --human-readable)
	@$(KAFKA_BIN)/kafka-metadata-quorum.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 describe --replication --human-readable 2>/dev/null || echo "$(RED) KRaft Quorum offline.$(NC)"

scale-partitions:
	@echo "\n$(CYAN)━━━ KRaft Demo: Massive Partition Scalability ━━━$(NC)"
	@echo "$(YELLOW)▸ With ZooKeeper, ~200K partitions was the practical ceiling.$(NC)"
	@echo "$(YELLOW)▸ With KRaft, millions of partitions are supported natively.$(NC)"
	@echo ""
	@$(KAFKA_BIN)/kafka-topics.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --delete --topic scale-test >/dev/null 2>&1 || true
	@sleep 2
	$(call tui_cmd,Creating initial topic with 1000 partitions,kafka-topics.sh --create --topic scale-test --partitions 1000)
	@python3 -c 'import time; open(".scale-timer","w").write(str(time.time()))'
	@$(KAFKA_BIN)/kafka-topics.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --command-config $(CONFIG_DIR)/admin-client.properties --create --topic scale-test --partitions 1000 --replication-factor 1 --if-not-exists 2>/dev/null
	@echo "$(GREEN)   ▸ 1,000 partitions created$(NC)"
	@echo ""
	$(call tui_cmd,Scaling up to 10000 partitions dynamically,kafka-topics.sh --alter --topic scale-test --partitions ...)
	@for COUNT in 3000 5000 7000 10000; do \
		$(KAFKA_BIN)/kafka-topics.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --command-config $(CONFIG_DIR)/admin-client.properties --alter --topic scale-test --partitions $$COUNT 2>/dev/null; \
		echo "$(GREEN)   ▸ Scaled to $$COUNT partitions$(NC)"; \
	done
	@ELAPSED=$$(python3 -c "import time; print(f'{time.time() - float(open(\".scale-timer\").read()):.2f}')"); \
	echo "$(GREEN)✓ 10,000 partitions reached in $${ELAPSED}s total$(NC)"; \
	rm -f .scale-timer
	@sleep 3
	@echo ""
	$(call tui_cmd,Verifying topic metadata,kafka-topics.sh --describe --topic scale-test)
	@$(KAFKA_BIN)/kafka-topics.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --command-config $(CONFIG_DIR)/admin-client.properties --describe --topic scale-test 2>/dev/null | head -1
	@PART_COUNT=$$($(KAFKA_BIN)/kafka-topics.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --command-config $(CONFIG_DIR)/admin-client.properties --describe --topic scale-test 2>/dev/null | grep -c 'Partition:'); \
	echo "$(GREEN)   Confirmed: $$PART_COUNT partitions active across the cluster.$(NC)"

restart-brokers:
	@echo "\n$(CYAN)━━━ Restarting Dead Nodes ━━━$(NC)"
	@RESTARTED=0; \
	echo "$(CYAN)── Brokers ──$(NC)"; \
	for BROKER_NUM in 1 2 3; do \
		PID_FILE="$(PIDS_DIR)/broker$$BROKER_NUM.pid"; \
		if [ -f "$$PID_FILE" ] && ps -p $$(cat $$PID_FILE) > /dev/null 2>&1; then \
			echo "$(GREEN)   ▸ Broker $$BROKER_NUM is healthy (PID $$(cat $$PID_FILE))$(NC)"; \
		else \
			echo "$(YELLOW)   ▸ Broker $$BROKER_NUM is dead. Restarting...$(NC)"; \
			if [ -d "$(KAFKA_DIR_V4)" ] && [ -f "$(CONFIG_DIR)/phase3/broker$$BROKER_NUM.properties" ] && [ -f "$(PIDS_DIR)/controller1.pid" ] && ! [ -f "$(PIDS_DIR)/zk1.pid" ]; then \
				KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN_V4)/kafka-server-start.sh $(CONFIG_DIR)/phase3/broker$$BROKER_NUM.properties > $(LOGS_DIR)/broker$$BROKER_NUM.log 2>&1 & echo $$! > $$PID_FILE; \
				echo "$(GREEN)   ✓ Broker $$BROKER_NUM restarted (V4 / KRaft)$(NC)"; \
			elif [ -f "$(PIDS_DIR)/controller1.pid" ] && ! [ -f "$(PIDS_DIR)/zk1.pid" ] && [ -f "$(CONFIG_DIR)/phase2/broker$$BROKER_NUM.properties" ]; then \
				KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/phase2/broker$$BROKER_NUM.properties > $(LOGS_DIR)/broker$$BROKER_NUM.log 2>&1 & echo $$! > $$PID_FILE; \
				echo "$(GREEN)   ✓ Broker $$BROKER_NUM restarted (V3 / KRaft)$(NC)"; \
			elif [ -f "$(PIDS_DIR)/controller1.pid" ] && [ -f "$(CONFIG_DIR)/phase1/broker$$BROKER_NUM.properties" ]; then \
				KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/phase1/broker$$BROKER_NUM.properties > $(LOGS_DIR)/broker$$BROKER_NUM.log 2>&1 & echo $$! > $$PID_FILE; \
				echo "$(GREEN)   ✓ Broker $$BROKER_NUM restarted (V3 / Bridge)$(NC)"; \
			else \
				KAFKA_HEAP_OPTS="-Xmx4G -Xms4G" $(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/phase0/broker$$BROKER_NUM.properties > $(LOGS_DIR)/broker$$BROKER_NUM.log 2>&1 & echo $$! > $$PID_FILE; \
				echo "$(GREEN)   ✓ Broker $$BROKER_NUM restarted (V3 / ZooKeeper)$(NC)"; \
			fi; \
			RESTARTED=$$((RESTARTED + 1)); \
		fi; \
	done; \
	echo "$(CYAN)── Controllers ──$(NC)"; \
	for CTRL_NUM in 1 2 3; do \
		PID_FILE="$(PIDS_DIR)/controller$$CTRL_NUM.pid"; \
		if [ -f "$$PID_FILE" ] && ps -p $$(cat $$PID_FILE) > /dev/null 2>&1; then \
			echo "$(GREEN)   ▸ Controller $$CTRL_NUM is healthy (PID $$(cat $$PID_FILE))$(NC)"; \
		elif [ -f "$$PID_FILE" ] || [ -d "$(DATA_DIR)/controller$$CTRL_NUM" ]; then \
			echo "$(YELLOW)   ▸ Controller $$CTRL_NUM is dead. Restarting...$(NC)"; \
			if [ -d "$(KAFKA_DIR_V4)" ] && [ -f "$(CONFIG_DIR)/phase3/controller$$CTRL_NUM.properties" ]; then \
				KAFKA_HEAP_OPTS="-Xmx1G -Xms1G" $(KAFKA_BIN_V4)/kafka-server-start.sh $(CONFIG_DIR)/phase3/controller$$CTRL_NUM.properties > $(LOGS_DIR)/controller$$CTRL_NUM.log 2>&1 & echo $$! > $$PID_FILE; \
				echo "$(GREEN)   ✓ Controller $$CTRL_NUM restarted (V4)$(NC)"; \
			else \
				KAFKA_HEAP_OPTS="-Xmx1G -Xms1G" $(KAFKA_BIN)/kafka-server-start.sh $(CONFIG_DIR)/kraft-controller/controller$$CTRL_NUM.properties > $(LOGS_DIR)/controller$$CTRL_NUM.log 2>&1 & echo $$! > $$PID_FILE; \
				echo "$(GREEN)   ✓ Controller $$CTRL_NUM restarted (V3)$(NC)"; \
			fi; \
			RESTARTED=$$((RESTARTED + 1)); \
		fi; \
	done; \
	echo ""; \
	if [ $$RESTARTED -eq 0 ]; then \
		echo "$(GREEN)✓ All nodes are healthy. Nothing to restart.$(NC)"; \
	else \
		echo "$(GREEN)✓ Restarted $$RESTARTED node(s). Waiting 5s for stabilization...$(NC)"; \
		sleep 5; \
		echo "$(GREEN)✓ Cluster should be stable now.$(NC)"; \
	fi

# ── Status & Cleanup ──────────────────────────────────────────

check-pid:
	@if [ -z "$(PID)" ]; then \
		echo "$(RED)! You must provide a PID. Usage: make check-pid PID=12345$(NC)"; \
	else \
		echo "$(CYAN)━━━ Process Details for PID $(PID) ━━━$(NC)"; \
		ps -f -p $(PID) || echo "$(RED)✘ No process found actively running with PID $(PID)$(NC)"; \
	fi

status:
	@echo "\n$(CYAN)╭─────────────────────── Runtime Status ──────────────────────╮$(NC)"
	@printf "$(CYAN)│ $(YELLOW)%-14s$(CYAN) │ $(YELLOW)%-8s$(CYAN) │ $(YELLOW)%-14s$(CYAN) │ $(YELLOW)%-14s$(CYAN) │\n$(NC)" "Node Context" "State" "Host Address" "Process ID"
	@echo "$(CYAN)├────────────────┼──────────┼────────────────┼────────────────┤$(NC)"
	@for pidfile in $(PIDS_DIR)/*.pid; do \
		if [ -f "$$pidfile" ]; then \
			pid=$$(cat $$pidfile); \
			name=$$(basename $$pidfile .pid); \
			case $$name in \
				zk1) port="2181" ;; \
				zk2) port="2182" ;; \
				zk3) port="2183" ;; \
				broker1) port="9092" ;; \
				broker2) port="9096" ;; \
				broker3) port="9097" ;; \
				controller1) port="9093" ;; \
				controller2) port="9094" ;; \
				controller3) port="9095" ;; \
				*) port="N/A" ;; \
			esac; \
			if ps -p $$pid > /dev/null; then \
				printf "$(CYAN)│$(NC) %-14s $(CYAN)│$(NC) $(GREEN)%-8s$(CYAN) │$(NC) %-14s $(CYAN)│$(NC) %-14s $(CYAN)│\n$(NC)" "$$name" "RUNNING" "localhost:$$port" "PID $$pid"; \
			else \
				printf "$(CYAN)│$(NC) %-14s $(CYAN)│$(NC) $(RED)%-8s$(CYAN) │$(NC) %-14s $(CYAN)│$(NC) %-14s $(CYAN)│\n$(NC)" "$$name" "STOPPED" "localhost:$$port" "DEAD"; \
			fi \
		fi \
	done
	@echo "$(CYAN)╰────────────────┴──────────┴────────────────┴────────────────╯$(NC)"

watch:
	@watch --color -n 2 $(MAKE) --no-print-directory status

clean: kill
	@echo "$(YELLOW)▸ Wiping data and logs...$(NC)"
	@rm -rf $(DATA_DIR)/* $(LOGS_DIR)/* $(PIDS_DIR)/* .cluster-id
	@echo "$(GREEN)✓ Clean complete.$(NC)"

all: start cluster-id controllers bridge verify-bridge kraft verify-kraft upgrade
