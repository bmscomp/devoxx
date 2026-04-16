<span class="tag tag-part">Part 6</span>

## Deploying a <span class="accent-green">KRaft</span> Cluster

From zero to production — three commands <!-- .element: class="subtitle" -->

```bash
# Step 1: Generate a cluster ID
CLUSTER_ID=$(bin/kafka-storage.sh random-uuid)
```
<!-- .element: class="fragment" -->

```bash
# Step 2: Format storage on each node
bin/kafka-storage.sh format \
  -t $CLUSTER_ID \
  -c config/kraft/server.properties
```
<!-- .element: class="fragment" -->

```bash
# Step 3: Start
bin/kafka-server-start.sh config/kraft/server.properties
```
<!-- .element: class="fragment" -->

That's it. <strong><span class="accent-green">No ZooKeeper.</span></strong> <!-- .element: class="fragment" style="font-size: 0.85em; margin-top: 20px; text-align: center;" -->

Note:
Let this simplicity sink in. Three commands. Compare mentally with the ZK setup.

---

## Production Config: <span class="accent-green">Controller</span>

Photograph this slide <!-- .element: class="subtitle" -->

```properties
# ── Node Identity ──
process.roles=controller
node.id=0
cluster.id=your-cluster-id-here

# ── Quorum ──
controller.quorum.voters=0@ctrl0:9093,1@ctrl1:9093,2@ctrl2:9093
controller.listener.names=CONTROLLER
listener.security.protocol.map=CONTROLLER:SSL

# ── Networking ──
listeners=CONTROLLER://ctrl0:9093

# ── Storage ──
log.dirs=/var/kafka/metadata

# ── Metadata Management ──
metadata.log.max.record.bytes.between.snapshots=104857600
metadata.log.max.snapshot.interval.ms=3600000

# ── Security ──
ssl.keystore.location=/etc/kafka/ssl/controller.keystore.jks
ssl.truststore.location=/etc/kafka/ssl/truststore.jks
```

Note:
This is a production-ready starting point. Tell the audience to photograph it.

---

## Production Config: <span class="accent-orange">Broker</span>

Photograph this slide <!-- .element: class="subtitle" -->

```properties
# ── Node Identity ──
process.roles=broker
node.id=100
cluster.id=your-cluster-id-here

# ── Quorum (connect to controllers) ──
controller.quorum.voters=0@ctrl0:9093,1@ctrl1:9093,2@ctrl2:9093
controller.listener.names=CONTROLLER

# ── Networking ──
listeners=PLAINTEXT://broker0:9092,SSL://broker0:9093
advertised.listeners=PLAINTEXT://broker0:9092,SSL://broker0:9093
inter.broker.listener.name=PLAINTEXT

# ── Storage ──
log.dirs=/var/kafka/data
num.partitions=6
default.replication.factor=3
min.insync.replicas=2
```

Note:
Notice: no zookeeper.connect anywhere. The broker just points to the controller quorum.

---

## What <span class="accent-red strikethrough">Disappears</span> with KRaft

- <!-- .element: class="fragment" --> ❌ ZooKeeper deployment (3–5 separate nodes)
- <!-- .element: class="fragment" --> ❌ `zoo.cfg` and `myid` files
- <!-- .element: class="fragment" --> ❌ ZooKeeper JVM tuning (`-Xmx`, GC, `tickTime`, `syncLimit`)
- <!-- .element: class="fragment" --> ❌ ZooKeeper rolling upgrades
- <!-- .element: class="fragment" --> ❌ ZooKeeper ACLs and SASL configuration
- <!-- .element: class="fragment" --> ❌ ZooKeeper monitoring (`mntr`, `ruok`, 4-letter commands)
- <!-- .element: class="fragment" --> ❌ ZooKeeper disk management (txn logs, snapshots, purging)
- <!-- .element: class="fragment" --> ❌ Firewall rules for ZK ports (2181, 2888, 3888)

Result: <strong>fewer runbooks, fewer alerts, fewer on-call pages, one team.</strong> <!-- .element: class="fragment" style="font-size: 0.85em; margin-top: 20px; color: #444;" -->

Note:
Each strikethrough is a weight lifted off the ops team. Let them feel the relief.

---

## Migration: ZK → <span class="accent-green">KRaft</span>

Three-phase rolling migration — no downtime <!-- .element: class="subtitle" -->

<div class="card-grid three-col" style="margin-top: 25px;">
<div class="card fragment" style="border-top: 3px solid var(--accent-black);">
<h4>Phase 1: ZK Mode</h4>
<p>Deploy KRaft controllers alongside existing ZK cluster</p>
</div>
<div class="card fragment" style="border-top: 3px solid var(--accent-blue);">
<h4>Phase 2: Bridge Mode</h4>
<p>Active controller dual-writes: ZK ↔ <code>__cluster_metadata</code></p>
</div>
<div class="card fragment" style="border-top: 3px solid var(--accent-blue);">
<h4>Phase 3: KRaft Mode</h4>
<p>Remove <code>zookeeper.connect</code>, decommission ZK</p>
</div>
</div>

```properties
# Broker config during bridge mode
zookeeper.connect=zk1:2181,zk2:2181,zk3:2181
controller.quorum.voters=0@ctrl0:9093,1@ctrl1:9093,2@ctrl2:9093
```
<!-- .element: class="fragment" -->

⚠️ After finalization: <strong>one-way door</strong> — no rollback to ZooKeeper. <!-- .element: class="fragment" style="font-size: 0.78em; color: var(--accent-red); margin-top: 10px;" -->

Note:
Emphasize the one-way door. This is not a decision you undo.

---

## Day-2 Operations: <span class="accent-green">Simplified</span>

| Operation | <span class="accent-yellow">With ZooKeeper</span> | <span class="accent-green">With KRaft</span> |
|-----------|---------------|------------|
| Rolling upgrade | Upgrade ZK first, then Kafka | Upgrade Kafka only |
| Add a broker | Register in ZK + Kafka | Just start the broker |
| Security config | Kafka SASL + ZK ACLs | Single security model |
| Monitoring | Two dashboards | One dashboard |
| Backup metadata | Export from ZK | Snapshot `__cluster_metadata` |
| Capacity planning | Size ZK + Kafka | Size Kafka only |
| Troubleshooting | ZK logs + Kafka logs | Kafka logs only |

Note:
Another "photograph this" slide. The simplification is massive for day-2 ops.
