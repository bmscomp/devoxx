# ZooKeeper → KRaft Migration Demo

> **Kafka 3.9.2** — the last version supporting both ZooKeeper and KRaft.
> Kafka 4.0+ has ZooKeeper support **completely removed**.

This demo walks through a complete, phased migration from a ZooKeeper-based Kafka cluster to a pure KRaft cluster using Docker Compose.

---

## Architecture Overview

### Phase 0 — Starting Point (ZooKeeper Mode)

```
┌─────────────────────────────────────────────────────────┐
│                   ZooKeeper Ensemble                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │   ZK-1   │  │   ZK-2   │  │   ZK-3   │               │
│  │  :2181   │  │  :2182   │  │  :2183   │               │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘               │
│       │              │              │                   │
│       └──────────────┼──────────────┘                   │
│                      │                                  │
│  ┌──────────┐  ┌─────┴────┐  ┌──────────┐               │
│  │ Broker-1 │  │ Broker-2 │  │ Broker-3 │               │
│  │  :9092   │  │  :9093   │  │  :9094   │               │
│  └──────────┘  └──────────┘  └──────────┘               │
└─────────────────────────────────────────────────────────┘
```

### Phase 1 — Bridge Mode (Dual Write)

```
┌──────────────────────────────────────────────────────────┐
│  ZooKeeper Ensemble          KRaft Controllers           │
│  ┌────┐ ┌────┐ ┌────┐       ┌────────┐ ┌────────┐        │
│  │ZK-1│ │ZK-2│ │ZK-3│       │Ctrl-100│ │Ctrl-101│        │
│  └──┬─┘ └──┬─┘ └──┬─┘       └───┬────┘ └───┬────┘        │
│     │      │      │             │          │             │
│     └──────┼──────┘         ┌────────┐     │             │
│            │                │Ctrl-102│─────┘             │
│            │                └───┬────┘                   │
│            │                    │                        │
│     ┌──────┴────────────────────┘                        │
│     │    (metadata dual-written)                         │
│     │                                                    │
│  ┌──┴───────┐  ┌──────────┐  ┌──────────┐                │
│  │ Broker-1 │  │ Broker-2 │  │ Broker-3 │                │
│  │migration │  │migration │  │migration │                │
│  │ =true    │  │ =true    │  │ =true    │                │
│  └──────────┘  └──────────┘  └──────────┘                │
└──────────────────────────────────────────────────────────┘
```

### Phase 2 — KRaft Only (Final State)

```
┌──────────────────────────────────────────────────────────┐
│                   KRaft Controllers                      │
│  ┌────────┐  ┌────────┐  ┌────────┐                      │
│  │Ctrl-100│  │Ctrl-101│  │Ctrl-102│                      │
│  │ :9093  │  │ :9093  │  │ :9093  │                      │
│  └────┬───┘  └────┬───┘  └────┬───┘                      │
│       │           │           │                          │
│       └───────────┼───────────┘                          │
│                   │  (Raft quorum)                       │
│                   │                                      │
│  ┌──────────┐  ┌──┴───────┐  ┌──────────┐                │
│  │ Broker-1 │  │ Broker-2 │  │ Broker-3 │                │
│  │  :9092   │  │  :9093   │  │  :9094   │                │
│  └──────────┘  └──────────┘  └──────────┘                │
│                                                          │
│            No ZooKeeper. No going back.                  │
└──────────────────────────────────────────────────────────┘
```

---

## Migration Plan

### Prerequisites

| Requirement | Detail |
|---|---|
| **Docker** | Docker 24+ with Compose V2 |
| **Kafka version** | 3.9.2 (last to support both ZK and KRaft) |
| **Disk space** | ~2 GB for images + volumes |
| **OS** | macOS / Linux |

### Step-by-Step Migration

#### Phase 0 — Start the ZooKeeper Cluster

```bash
# Start the ZK-based cluster
docker compose -f docker-compose-zk.yml up -d

# Wait 30 seconds for all nodes to stabilize
sleep 30

# Create a test topic and produce data
docker exec broker-1 /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server broker-1:29092 \
  --create --topic migration-test \
  --partitions 6 --replication-factor 3

# Produce 100 test messages
docker exec broker-1 bash -c '
  for i in $(seq 1 100); do echo "msg-$i"; done \
  | /opt/kafka/bin/kafka-console-producer.sh \
    --bootstrap-server broker-1:29092 --topic migration-test
'
```

✅ **Checkpoint:** Verify 100 messages are consumable.

---

#### Phase 0.5 — Extract Cluster ID

```bash
# The cluster ID must be the SAME for ZK and KRaft.
# Extract it from ZooKeeper:
docker exec zookeeper-1 bash -c '
  echo "get /cluster/id" | /opt/bitnami/zookeeper/bin/zkCli.sh \
    -server localhost:2181 2>/dev/null \
  | grep -o '"'"'"id":"[^"]*"'"'"' | cut -d\" -f4
'

# Save it:
export CLUSTER_ID="<the-id-you-got>"
echo "$CLUSTER_ID" > .cluster-id
```

---

#### Phase 1 — Bridge Mode

This is the **critical phase**. We deploy KRaft controllers alongside the existing ZooKeeper ensemble, and enable migration mode on all brokers.

```bash
# Stop ZK-only cluster
docker compose -f docker-compose-zk.yml down

# Start Bridge Mode (ZK + KRaft controllers + migration-enabled brokers)
docker compose -f docker-compose-bridge.yml up -d

# Wait 45 seconds for metadata synchronization
sleep 45
```

**What happens during Bridge Mode:**
1. KRaft controllers form a Raft quorum
2. The Active Controller reads all metadata from ZooKeeper
3. Metadata is dual-written: ZK ↔ `__cluster_metadata` log
4. Brokers register with both systems

✅ **Checkpoint:** Verify topic still exists and messages are intact.

---

#### Phase 2 — Finalize (ONE-WAY DOOR ⚠️)

> **Warning:** After finalization, there is **no rollback** to ZooKeeper. Test thoroughly in a staging environment first!

```bash
# Stop bridge mode
docker compose -f docker-compose-bridge.yml down

# Start KRaft-only cluster (no ZooKeeper services)
docker compose -f docker-compose-kraft.yml up -d

# Wait 30 seconds
sleep 30
```

---

#### Phase 3 — Post-Migration Validation

```bash
# List topics — should include migration-test
docker exec broker-1 /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server broker-1:29092 --list

# Describe the topic — verify replicas and ISR
docker exec broker-1 /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server broker-1:29092 --describe --topic migration-test

# Consume all messages — should return 100
docker exec broker-1 /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server broker-1:29092 \
  --topic migration-test --from-beginning --timeout-ms 10000

# Produce new messages to verify write path
docker exec broker-1 bash -c '
  for i in $(seq 101 110); do echo "post-kraft-msg-$i"; done \
  | /opt/kafka/bin/kafka-console-producer.sh \
    --bootstrap-server broker-1:29092 --topic migration-test
'
```

✅ **Final Checkpoint:** All 110 messages consumable. Writes work. No ZooKeeper.

---

## Quick Start (Automated)

```bash
# Make scripts executable
chmod +x migrate.sh cleanup.sh

# Run the full interactive migration
./migrate.sh

# When done, clean up everything
./cleanup.sh
```

---

## File Structure

```
demos/migration/
├── README.md                    # This file
├── docker-compose-zk.yml       # Phase 0: ZooKeeper-based cluster
├── docker-compose-bridge.yml   # Phase 1: Bridge mode (ZK + KRaft)
├── docker-compose-kraft.yml    # Phase 2: KRaft-only cluster
├── migrate.sh                  # Interactive migration script
└── cleanup.sh                  # Tear down all containers/volumes
```

---

## Key Configuration Changes

### Broker Config Diff (ZK → Bridge → KRaft)

| Property | ZK Mode | Bridge Mode | KRaft Mode |
|---|---|---|---|
| `process.roles` | *(empty)* | *(empty)* | `broker` |
| `zookeeper.connect` | `zk1:2181,...` | `zk1:2181,...` | ❌ removed |
| `controller.quorum.voters` | ❌ absent | `100@ctrl1:9093,...` | `100@ctrl1:9093,...` |
| `zookeeper.metadata.migration.enable` | ❌ absent | `true` | ❌ removed |
| `controller.listener.names` | ❌ absent | `CONTROLLER` | `CONTROLLER` |

### Node ID Strategy

| Role | ID Range | Rationale |
|---|---|---|
| Brokers | 1–99 | Keep existing broker IDs to preserve partition assignments |
| Controllers | 100–102 | Separate namespace avoids ID collisions |

---

## Upgrade Path to Kafka 4.x

Once you are running KRaft-only on 3.9.2, upgrading to Kafka 4.0+ is a standard rolling upgrade:

1. Update the image tag from `apache/kafka:3.9.2` to `apache/kafka:4.2.0`
2. Rolling restart controllers first, then brokers
3. No ZooKeeper configuration to worry about — it was already removed

> **Note:** Kafka 4.0 removed all ZooKeeper code. You *must* complete the KRaft migration on 3.9.x before upgrading.
