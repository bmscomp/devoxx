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

.PHONY: help download download-v4 setup-dirs start cluster-id check-version list-topics produce-messages consume-messages controllers bridge kraft verify-bridge verify-zookeeper verify-controllers verify-kraft upgrade check-pid status kill clean all

help:
	@echo "$(CYAN)Kafka Binary Migration Demo Targets$(NC)"
	@echo "-----------------------------------"
	@echo "$(YELLOW)download$(NC)       - Download Kafka $(KAFKA_VERSION) tarball"
	@echo "$(YELLOW)start$(NC)          - Start ZK Ensemble + Kafka Brokers (ZK Mode)"
	@echo "$(YELLOW)cluster-id$(NC)     - Extract cluster ID via zookeeper-shell string parsing"
	@echo "$(YELLOW)check-version$(NC)    - Print the downloaded Kafka binary version"
	@echo "$(YELLOW)list-topics$(NC)    - List all current topics in the cluster"
	@echo "$(YELLOW)produce-messages$(NC)- Open an interactive console producer"
	@echo "$(YELLOW)consume-messages$(NC)- Consume all messages from 'devoxx-topic'"
	@echo "$(YELLOW)controllers$(NC)       - Format and start KRaft Controllers cleanly before bridging"
	@echo "$(YELLOW)bridge$(NC)         - Rolling Restart of Brokers into Bridge Mode"
	@echo "$(YELLOW)verify-bridge$(NC)- Verify topics & produce messages in Bridge Mode"
	@echo "$(YELLOW)verify-zookeeper$(NC)- Poll Zookeeper znodes to prove topological health"
	@echo "$(YELLOW)verify-controllers$(NC)- Interrogate KRaft quorum to prove meta-data election"
	@echo "$(YELLOW)kraft$(NC)          - Finalize KRaft (Irreversible!) - Restart brokers in KRaft mode"
	@echo "$(YELLOW)verify-kraft$(NC) - Final validation + create new topic"
	@echo "$(YELLOW)upgrade$(NC)        - Rolling Upgrade to Kafka V4 (Phase 3)"
	@echo "$(YELLOW)check-pid$(NC)      - Check details of a specific process (usage: make check-pid PID=123)"
	@echo "$(YELLOW)status$(NC)         - Check running Java PIDs"
	@echo "$(YELLOW)clean$(NC)          - Kill all PIDs and wipe data/logs"
	@echo "$(YELLOW)all$(NC)            - Run full automated migration"

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
	@if [ -d "$(KAFKA_DIR_V4)" ]; then \
		echo "$(YELLOW)▸ Using V4 CLI Binary (4.2.0):$(NC)"; \
		$(KAFKA_BIN_V4)/kafka-topics.sh --version; \
		echo "\n$(YELLOW)▸ Active Cluster Feature Metadata (Parsed via V4):$(NC)"; \
		$(KAFKA_BIN_V4)/kafka-features.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 describe 2>/dev/null || echo "$(RED)Cluster is currently offline or unreachable.$(NC)"; \
	else \
		echo "$(YELLOW)▸ Using V3 CLI Binary (3.9.x):$(NC)"; \
		$(KAFKA_BIN)/kafka-topics.sh --version; \
		echo "\n$(YELLOW)▸ Active Cluster Feature Metadata (Parsed via V3):$(NC)"; \
		$(KAFKA_BIN)/kafka-features.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 describe 2>/dev/null || echo "$(RED)Cluster is currently offline or unreachable.$(NC)"; \
	fi

list-topics:
	@echo "\n$(CYAN)━━━ Listing All Topics ━━━$(NC)"
	@$(KAFKA_BIN)/kafka-topics.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --list

produce-messages:
	@echo "\n$(CYAN)━━━ Auto-Publishing to 'devoxx-topic' ━━━$(NC)"
	@echo "$(YELLOW)Sending an incremented message every 0.6 seconds. Press Ctrl+C to stop.$(NC)"
	@python3 -u -c 'exec("import time, datetime\ni=1\nwhile True:\n    ts=datetime.datetime.now().strftime(\"%Y-%m-%d %H:%M:%S.%f\")[:-3]\n    print(f\"devoxx-{i}-{ts}\", flush=True)\n    i+=1\n    time.sleep(0.6)")' | $(KAFKA_BIN)/kafka-console-producer.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --topic devoxx-topic

consume-messages:
	@echo "\n$(CYAN)━━━ Reading from 'devoxx-topic' ━━━$(NC)"
	@$(KAFKA_BIN)/kafka-console-consumer.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 --topic devoxx-topic --from-beginning

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
	@echo "$(CYAN)ℹ EXPLANATION: Upgrading major Kafka versions is executed natively as a rolling restart while the cluster remains fully operational, guaranteeing zero downtime.$(NC)"
	
	@echo "\n$(YELLOW)▸ 1. Rolling Upgrade: Control Plane (Controllers to V4)...$(NC)"
	@echo "$(CYAN)ℹ EXPLANATION: We strictly upgrade the KRaft controllers first. The control plane must always utilize a binary equal to or newer than the broker pool.$(NC)"
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
	@echo "$(CYAN)ℹ EXPLANATION: Now that the KRaft control plane is running V4, we sequentially rolling-restart all data brokers to map them to the V4 binaries.$(NC)"
	
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
	@echo "$(CYAN)ℹ EXPLANATION: All nodes are safely running Kafka V4 infrastructure, however the underlying metadata schema is still functionally bound to 3.9 natively. We run kafka-features.sh to permanently ratify the structure to 4.2.$(NC)"
	
	$(call tui_cmd,Dynamically Mapping Cluster Metadata Version to 4.2.0 Schema Abstract,kafka-features.sh upgrade --metadata 4.2)
	@$(KAFKA_BIN_V4)/kafka-features.sh --bootstrap-server localhost:9092,localhost:9096,localhost:9097 upgrade --metadata 4.2
	@echo "$(GREEN)✓ Upgrade sequence complete. Cluster is natively executing Kafka 4.2.0!$(NC)"

# ── Status & Cleanup ──────────────────────────────────────────

check-pid:
	@if [ -z "$(PID)" ]; then \
		echo "$(RED)! You must provide a PID. Usage: make check-pid PID=12345$(NC)"; \
	else \
		echo "$(CYAN)━━━ Process Details for PID $(PID) ━━━$(NC)"; \
		ps -f -p $(PID) || echo "$(RED)✘ No process found actively running with PID $(PID)$(NC)"; \
	fi

status:
	@echo "$(CYAN)━━━ Runtime Status ━━━$(NC)"
	@for pidfile in $(PIDS_DIR)/*.pid; do \
		if [ -f "$$pidfile" ]; then \
			pid=$$(cat $$pidfile); \
			name=$$(basename $$pidfile .pid); \
			if ps -p $$pid > /dev/null; then \
				echo "$(GREEN)✔ $$name is RUNNING (PID $$pid)$(NC)"; \
			else \
				echo "$(RED)✘ $$name is STOPPED$(NC)"; \
			fi \
		fi \
	done

clean: kill
	@echo "$(YELLOW)▸ Wiping data and logs...$(NC)"
	@rm -rf $(DATA_DIR)/* $(LOGS_DIR)/* $(PIDS_DIR)/* .cluster-id
	@echo "$(GREEN)✓ Clean complete.$(NC)"

all: start cluster-id controllers bridge verify-bridge kraft verify-kraft upgrade
