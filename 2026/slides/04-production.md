<span class="tag tag-part">Part 4</span>

## Kafka with <span class="accent-green">KRaft</span> in Production

What it really takes to run Kafka at scale <!-- .element: class="subtitle" -->

<div class="card-grid" style="margin-top: 25px;">
<div class="card fragment">
<h4 class="accent-green">🖥️ Hardware</h4>
<p>Dedicated machines or VMs with fast ephemeral storage and network throughput.</p>
</div>
<div class="card fragment">
<h4 class="accent-green">📊 Monitoring</h4>
<p>Prometheus + Grafana dashboards on day one. Alerting is not optional.</p>
</div>
<div class="card fragment">
<h4 class="accent-green">🔐 Security</h4>
<p>TLS everywhere. SASL/SCRAM or mTLS for authentication. ACLs for authorization.</p>
</div>
<div class="card fragment">
<h4 class="accent-green">📋 Runbooks</h4>
<p>Documented procedures for failover, scaling, and disaster recovery.</p>
</div>
</div>

<strong>Rule #1:</strong> Kafka is infrastructure — treat it like your database, not your app server. <!-- .element: class="fragment" style="font-size: 0.78em; margin-top: 20px; color: #555; text-align: center;" -->

Note:
Set the tone: Kafka in production is not "just run the binary." It's a commitment.

---

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

## Hardware <span class="accent-green">Sizing</span>

Photograph this slide <!-- .element: class="subtitle" -->

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **Brokers** | 3 nodes | 6+ nodes (dedicated) |
| **Controllers** | 3 nodes | 3 or 5 (dedicated, never combined) |
| **CPU** | 8 cores/broker | 16+ cores (for compression/TLS) |
| **RAM** | 16 GB | 32–64 GB (page cache is king) |
| **Storage** | SSD | NVMe, XFS, `noatime` mount |
| **Network** | 1 Gbps | 10 Gbps (cross-rack/AZ replication) |
| **OS** | Linux x86_64 | Linux x86_64, tuned kernel params |

<!-- .element: class="fragment" -->

<div class="highlight-box fragment" style="margin-top: 15px;">
<p style="font-size: 0.72em; margin: 0;"><strong>💡 Key insight:</strong> Kafka is I/O bound, not CPU bound. Invest in disks and network first. The page cache (OS RAM beyond JVM heap) is what makes Kafka fast — don't steal it for the JVM.</p>
</div>

Note:
Emphasize: Kafka exploits the OS page cache. 32GB RAM with a 6GB JVM heap means 26GB for page cache. That's where the magic happens.

---

## Production Config: <span class="accent-green">Controller</span> + <span class="accent-blue">Broker</span>

Photograph this slide <!-- .element: class="subtitle" -->

<div class="split-layout">
<div class="split-left fragment" style="font-size: 0.78em;">

```properties
# ── Controller ──
process.roles=controller
node.id=0
controller.quorum.voters=
  0@ctrl0:9093,1@ctrl1:9093,
  2@ctrl2:9093
controller.listener.names=CONTROLLER
listeners=CONTROLLER://ctrl0:9093
log.dirs=/var/kafka/metadata
```

</div>
<div class="split-right fragment" style="font-size: 0.78em;">

```properties
# ── Broker ──
process.roles=broker
node.id=100
controller.quorum.voters=
  0@ctrl0:9093,1@ctrl1:9093,
  2@ctrl2:9093
listeners=PLAINTEXT://broker0:9092
log.dirs=/var/kafka/data
num.partitions=6
default.replication.factor=3
min.insync.replicas=2
```

</div>
</div>

Notice: <strong>no `zookeeper.connect` anywhere</strong>. The broker just points to the controller quorum. <!-- .element: class="fragment" style="font-size: 0.78em; margin-top: 15px; color: #555; text-align: center;" -->

Note:
Both configs on one slide so the audience can compare. The key difference: controllers manage metadata, brokers manage data.

---

## Essential <span class="accent-green">Broker</span> Tuning

Production configs that matter <!-- .element: class="subtitle" -->

```properties
# ── Replication & Durability ──
default.replication.factor=3
min.insync.replicas=2
unclean.leader.election.enable=false

# ── Performance ──
num.io.threads=16
num.network.threads=8
num.replica.fetchers=4
socket.send.buffer.bytes=1048576
socket.receive.buffer.bytes=1048576

# ── Log Management ──
log.retention.hours=168          # 7 days
log.segment.bytes=1073741824     # 1 GB segments
log.cleanup.policy=delete

# ── Resource Limits ──
num.partitions=6                 # sensible default per-topic
message.max.bytes=10485760       # 10 MB max message
```
<!-- .element: class="fragment" -->

`min.insync.replicas=2` + `acks=all` = **zero data loss** guarantee. <!-- .element: class="fragment" style="font-size: 0.78em; margin-top: 15px; color: #555; text-align: center;" -->

Note:
Walk through each section. The combo of replication.factor=3, min.insync.replicas=2, and acks=all is the gold standard. NEVER set unclean leader election to true in production.

---

## <span class="accent-green">JVM</span> & OS Tuning

The hidden performance levers <!-- .element: class="subtitle" -->

<div class="split-layout">
<div class="split-left fragment" style="font-size: 0.78em;">

```bash
# JVM settings
export KAFKA_HEAP_OPTS="-Xmx6g -Xms6g"
export KAFKA_JVM_PERFORMANCE_OPTS="
  -server
  -XX:+UseG1GC
  -XX:MaxGCPauseMillis=20
  -XX:InitiatingHeapOccupancyPercent=35
  -XX:G1HeapRegionSize=16M
  -Djava.awt.headless=true"
```

<p style="font-size: 0.85em; color: #555;"><strong>6 GB heap</strong> — don't go higher. Large heaps steal from the page cache.</p>

</div>
<div class="split-right fragment" style="font-size: 0.78em;">

```bash
# Linux kernel params
vm.swappiness=1
vm.dirty_ratio=60
vm.dirty_background_ratio=5
net.core.wmem_max=2097152
net.core.rmem_max=2097152

# File descriptors
* hard nofile 1000000
* soft nofile 1000000
```

<p style="font-size: 0.85em; color: var(--accent-red);">⚠️ 10K partitions = <strong>40K+ FDs</strong>. Default 1024 will crash your cluster!</p>

</div>
</div>

Note:
We merged JVM and OS tuning into one slide. Common mistake: setting -Xmx to 32GB. This kills performance. File descriptors are the silent killer.

---

## <span class="accent-green">Monitoring</span> Essentials

Metrics that save you at 3 AM <!-- .element: class="subtitle" -->

<div class="card-grid three-col" style="margin-top: 20px;">
<div class="card fragment" style="border-top: 3px solid var(--accent-blue);">
<h4>Broker Health</h4>
<ul>
<li><code>UnderReplicatedPartitions</code></li>
<li><code>ActiveControllerCount</code></li>
<li><code>OfflinePartitionsCount</code></li>
<li><code>RequestHandlerAvgIdlePercent</code></li>
</ul>
</div>
<div class="card fragment" style="border-top: 3px solid var(--accent-blue);">
<h4>Performance</h4>
<ul>
<li><code>TotalTimeMs</code> (Produce/Fetch)</li>
<li><code>BytesInPerSec</code></li>
<li><code>BytesOutPerSec</code></li>
<li><code>MessagesInPerSec</code></li>
</ul>
</div>
<div class="card fragment" style="border-top: 3px solid var(--accent-red);">
<h4>🚨 Alert On</h4>
<ul>
<li><code>UnderReplicatedPartitions > 0</code></li>
<li><code>OfflinePartitions > 0</code></li>
<li><code>ISR shrink rate</code></li>
<li><code>Consumer lag > threshold</code></li>
</ul>
</div>
</div>

If `UnderReplicatedPartitions > 0` for more than 5 minutes → **wake someone up**. <!-- .element: class="fragment" style="font-size: 0.78em; margin-top: 15px; color: var(--accent-red); text-align: center;" -->

Note:
UnderReplicatedPartitions is the #1 metric. If it's not zero, something is wrong: slow disk, network issue, dead broker, or overloaded cluster.

---

## Production <span class="accent-green">Security</span>

Defense in depth <!-- .element: class="subtitle" -->

<div class="card-grid" style="margin-top: 20px;">
<div class="card fragment">
<h4 class="accent-green">🔒 Encryption & Authentication</h4>
<ul>
<li><strong>In-transit:</strong> TLS 1.3 for all client↔broker and broker↔broker traffic</li>
<li><strong>At-rest:</strong> Filesystem-level (LUKS/dm-crypt) or cloud KMS</li>
<li><strong>mTLS</strong> — strongest, no passwords</li>
<li><strong>SASL/SCRAM-SHA-512</strong> — password-based, good for services</li>
<li><strong>SASL/OAUTHBEARER</strong> — for OAuth2/OIDC integration</li>
</ul>
</div>
<div class="card fragment">
<h4 class="accent-green">🛡️ Authorization (ACLs)</h4>
<p>With KRaft, use <code>StandardAuthorizer</code> — ACLs stored in <code>__cluster_metadata</code> log.</p>
<pre style="font-size: 0.85em;"><code>kafka-acls.sh --add \
  --allow-principal User:producer-app \
  --operation Write --topic orders

kafka-acls.sh --add \
  --allow-principal User:consumer-app \
  --operation Read \
  --topic orders --group order-group</code></pre>
</div>
</div>

Note:
With KRaft, use StandardAuthorizer instead of AclAuthorizer. It stores ACLs in __cluster_metadata log instead of ZooKeeper.

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

## Operational <span class="accent-green">Runbook</span>

The five scenarios you must prepare for <!-- .element: class="subtitle" -->

| # | Scenario | Action | Recovery Time |
|---|----------|--------|---------------|
| 1 | **Broker loss** | Auto-reassignment kicks in. Monitor ISR. | Minutes |
| 2 | **Disk failure** | Replace disk, restart broker. Kafka re-replicates. | 10–60 min |
| 3 | **Full AZ outage** | Clients fail over to remaining AZs. No operator action needed if `min.insync.replicas` is met. | Automatic |
| 4 | **Consumer lag spike** | Scale consumer group. Check for slow consumers or compaction overhead. | Minutes |
| 5 | **Cluster full** | Add brokers and run `kafka-reassign-partitions.sh` to rebalance. | Hours |

<!-- .element: class="fragment" -->

<div class="highlight-box fragment" style="margin-top: 10px;">
<p style="font-size: 0.72em; margin: 0;"><strong>Golden rule:</strong> Never operate a Kafka cluster above <strong>70% disk</strong> or <strong>70% network</strong> capacity. Leave room for replication storms during recovery.</p>
</div>

Note:
The 70% rule is the most practical advice here. Kafka needs headroom to re-replicate after failures. If you're at 90% disk, one broker failure = cascading failure.
