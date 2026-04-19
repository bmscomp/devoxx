<span class="tag tag-challenge">Part 6</span>

## Challenges & <span class="accent-red">Anti-Patterns</span>

What can go wrong — and how to avoid it <!-- .element: class="subtitle" -->

<div style="text-align: center; font-size: 2.5em; margin: 30px 0;">
🚫
</div>

These mistakes have **killed production clusters**. <!-- .element: class="fragment" style="font-size: 0.85em; text-align: center; color: var(--accent-red);" -->

Learn from others' pain. <!-- .element: class="fragment" style="font-size: 0.75em; text-align: center; color: #555;" -->

Note:
This section covers both migration anti-patterns and ongoing KRaft operational challenges.

---

## ❌ <span class="accent-red">Rushing the Finalization</span>

> "Bridge mode works, let's finalize immediately!"

<div class="card-grid" style="margin-top: 20px;">
<div class="card card-danger fragment">
<h4 class="accent-red">🚫 What people do</h4>
<p>Run bridge mode for a few hours, see "it works," and immediately run <code>kafka-metadata.sh finalize</code>.</p>
</div>
<div class="card card-success fragment">
<h4 class="accent-green">✅ What you should do</h4>
<p>Run bridge mode for <strong>weeks</strong>. Observe through peak traffic, rolling restarts, broker failures, and consumer rebalances before finalizing.</p>
</div>
</div>

<div class="highlight-box fragment" style="margin-top: 15px;">
<p style="font-size: 0.75em; margin: 0;">⚠️ <strong>Remember:</strong> Finalization is a <span class="accent-red">one-way door</span>. After finalization, there is <strong>no rollback to ZooKeeper</strong>. Ever. Phases 1–2 are reversible, but finalization is not. Backup ZK data (<code>snapshot</code> + <code>txn logs</code>) and tag your Git commit before proceeding.</p>
</div>

Note:
This slide absorbs the "one-way door" and "no rollback plan" messages. No need to repeat them elsewhere.

---

## ❌ <span class="accent-red">Skipping Version Gates</span>

The migration requires a very specific version path <!-- .element: class="subtitle" -->

<div class="card-grid three-col" style="margin-top: 20px;">
<div class="card card-danger fragment">
<h4>🚫 Skip versions</h4>
<p>Jump from Kafka 2.8 directly to 4.x</p>
<p style="color: var(--accent-red); font-weight: 600;">= Data loss risk</p>
</div>
<div class="card card-success fragment">
<h4>✅ Follow the path</h4>
<p>2.x → 3.3+ → 3.7+ (bridge) → 3.9+ (finalize) → 4.x</p>
<p style="color: var(--accent-green); font-weight: 600;">= Safe migration</p>
</div>
<div class="card fragment" style="border-top: 3px solid var(--accent-black);">
<h4>📋 Check IBP</h4>
<p>Set <code>inter.broker.protocol.version</code> correctly at each step</p>
<p style="font-weight: 600;">= Required</p>
</div>
</div>

```properties
# Step 1: Upgrade brokers to 3.7+, keep IBP at current version
inter.broker.protocol.version=3.6

# Step 2: After all brokers upgraded, bump IBP
inter.broker.protocol.version=3.7-IV4

# Step 3: THEN start bridge mode
```
<!-- .element: class="fragment" -->

Note:
KIP-833 defines the exact migration path. Skipping IBP steps can corrupt the metadata log.

---

## ❌ <span class="accent-red">Combined Mode</span> & <span class="accent-red">ZK Cleanup</span>

Two common operational mistakes <!-- .element: class="subtitle" -->

<div class="card-grid" style="margin-top: 20px;">
<div class="card card-danger fragment">
<h4 class="accent-red">🚫 Combined Mode in Production</h4>
<ul>
<li>Controller Raft traffic competes with broker I/O</li>
<li>Broker GC pause → controller election timeout</li>
<li>One crash takes out <strong>both</strong> roles</li>
<li>Use <strong>dedicated controllers</strong> always</li>
</ul>
</div>
<div class="card card-danger fragment">
<h4 class="accent-red">🚫 Leaving ZK Running After Finalization</h4>
<ul>
<li>Stale znodes confuse operators</li>
<li>Security attack surface remains</li>
<li>Keep ZK <strong>1–2 weeks</strong> as grace period</li>
<li>Backup data, then permanently shut down</li>
</ul>
</div>
</div>

Note:
Combined mode exists for dev convenience. Apache removed the recommendation from docs in 3.6. ZK post-finalization is a liability.

---

## ❌ <span class="accent-red">Ignoring Metadata Consistency</span>

The silent killer during bridge mode <!-- .element: class="subtitle" -->

<div class="card-grid" style="margin-top: 20px;">
<div class="card card-danger fragment">
<h4 class="accent-red">🚫 Never verify</h4>
<p>Assume bridge mode "just works" and finalize without checking metadata parity.</p>
</div>
<div class="card card-success fragment">
<h4 class="accent-green">✅ Continuously verify</h4>
<p>Compare ZK metadata with <code>__cluster_metadata</code> log before every milestone.</p>
</div>
</div>

```bash
# Verify topic metadata matches between ZK and KRaft
bin/kafka-metadata.sh --snapshot /var/kafka/metadata/__cluster_metadata-0/ \
    --command-config admin.properties --diff

# Check partition assignments
bin/kafka-topics.sh --bootstrap-server broker:9092 --describe --under-replicated
```
<!-- .element: class="fragment" -->

If even **one topic** has mismatched metadata, do **NOT** finalize. <!-- .element: class="fragment" style="font-size: 0.78em; margin-top: 15px; color: var(--accent-red); text-align: center;" -->

Note:
Metadata drift between ZK and KRaft during bridge mode is rare but possible, especially during network instability.

---

## ❌ <span class="accent-red">Migrating Under Load</span>

Don't migrate during peak traffic <!-- .element: class="subtitle" -->

<div class="card-grid" style="margin-top: 20px;">
<div class="card card-danger fragment">
<h4 class="accent-red">🚫 Bad Timing</h4>
<ul>
<li>Black Friday / peak traffic</li>
<li>During a partition reassignment</li>
<li>While consumer groups are rebalancing</li>
<li>Right after a broker crash</li>
<li>Friday afternoon 😅</li>
</ul>
</div>
<div class="card card-success fragment">
<h4 class="accent-green">✅ Good Timing</h4>
<ul>
<li>Maintenance window, low traffic</li>
<li>All brokers healthy, ISR complete</li>
<li>No pending reassignments</li>
<li>Monitoring dashboards green</li>
<li>The team is awake and available</li>
</ul>
</div>
</div>

<div class="highlight-box fragment" style="margin-top: 15px;">
<p style="font-size: 0.72em; margin: 0;">
<strong>Pre-flight checks before each phase:</strong><br/>
✅ <code>UnderReplicatedPartitions == 0</code> · ✅ <code>OfflinePartitions == 0</code> · ✅ All brokers in ISR · ✅ Consumer lag stable
</p>
</div>

Note:
Every rolling restart during migration causes brief leader elections. Under high load, this can cascade.

---

## Migration <span class="accent-green">Checklist</span>

Photograph this slide <!-- .element: class="subtitle" -->

| Phase | Gate Criteria | Rollback? |
|-------|--------------|-----------|
| **Pre-migration** | All brokers on 3.7+, IBP aligned, ZK healthy | N/A |
| **Deploy controllers** | 3 controllers running, quorum formed | ✅ Remove controllers |
| **Enable bridge** | `zookeeper.metadata.migration.enable=true`, rolling restart | ✅ Revert config |
| **Validate bridge** | Run 1–4 weeks, verify metadata, test failovers | ✅ Disable migration |
| **Finalize** | `kafka-metadata.sh migrate --finalize` | ❌ **One-way door** |
| **Remove ZK refs** | Remove `zookeeper.connect` from all configs | ❌ |
| **Decommission ZK** | Shut down ZK after 1–2 week grace period | ❌ |

<!-- .element: class="fragment" -->

Each row is a **checkpoint**. Don't proceed until every check passes. <!-- .element: class="fragment" style="font-size: 0.78em; margin-top: 15px; text-align: center; color: #555;" -->

Note:
🎤 This is the most practical slide for ops teams. Print this checklist for your migration runbook.

---

## Challenge: <span class="accent-red">Static Quorum</span>

- <!-- .element: class="fragment" --> Controller voter list is <strong>hardcoded</strong> in `controller.quorum.voters`
- <!-- .element: class="fragment" --> Add/remove a controller → config change + <strong>rolling restart of all nodes</strong>
- <!-- .element: class="fragment" --> <strong>KIP-853</strong> (dynamic quorum reconfiguration) — in progress, not yet GA
- <!-- .element: class="fragment" --> Impact: controller replacement after hardware failure requires careful coordination

<div class="highlight-box fragment" style="margin-top: 20px;">
<p style="font-size: 0.75em; margin: 0;"><strong>Mitigation:</strong> Automate voter config management with orchestration tools (Ansible, Terraform, Strimzi operator).</p>
</div>

Note:
Be honest. This is a real operational pain point. The audience respects honesty over marketing.

---

## Challenge: <span class="accent-red">Metadata & Scaling</span>

<div class="card-grid" style="margin-top: 20px;">
<div class="card fragment">
<h4>Metadata Log Growth</h4>
<ul>
<li><code>__cluster_metadata</code> grows with every metadata change</li>
<li>Tune snapshot frequency: too infrequent → large log; too frequent → unnecessary I/O</li>
<li><code>metadata.log.max.record.bytes.between.snapshots=104857600</code></li>
</ul>
</div>
<div class="card fragment">
<h4>Scaling at Extremes</h4>
<ul>
<li>Millions of partitions → snapshots: 100s MB to GB</li>
<li>Rule of thumb: ~1–2 KB per partition-replica → 1M partitions ≈ 1–2 GB memory</li>
<li>New broker bootstrap: must replay snapshot + log → can take <strong>minutes</strong></li>
</ul>
</div>
</div>

<div class="highlight-box fragment" style="margin-top: 15px;">
<p style="font-size: 0.75em; margin: 0;"><strong>Mitigation:</strong> Dedicated high-memory controller nodes with fast NVMe. Tune snapshot intervals. Consider separate clusters beyond ~2M partitions. Place controllers across 3+ AZs for resilience.</p>
</div>

Note:
Practical advice. These configs are not well-documented. Share your experience.

---

## Challenge: <span class="accent-red">Failover & Network Partitions</span>

<div class="card-grid" style="margin-top: 20px;">
<div class="card card-success fragment">
<h4 class="accent-green">✅ Happy path</h4>
<p>Leader fails → new leader elected in 1–3 seconds. Data plane continues.</p>
</div>
<div class="card card-danger fragment">
<h4 class="accent-red">⚠️ Network partition</h4>
<p>Leader isolated → steps down. Majority side elects new leader. Minority side: metadata ops stall, but serve existing traffic.</p>
</div>
</div>

During short outages: <span class="accent-green">data plane continues</span> (produce/consume works). But: <span class="accent-red">no metadata changes</span> — no new topics, no reassignment, no ISR updates. <!-- .element: class="fragment" style="font-size: 0.78em; margin-top: 15px;" -->

Note:
Each of these is a scenario the audience might encounter. Key difference from ZK era: Kafka now handles split-brain directly via Raft.

---

## Challenge: <span class="accent-red">Monitoring & Tooling</span>

<div class="card-grid" style="margin-top: 20px;">
<div class="card fragment">
<h4>KRaft-Specific Metrics</h4>
<pre style="font-size: 0.8em;"><code>kafka.controller:type=QuorumController,
  name=EventQueueTimeMs
kafka.server:type=MetadataLoader,
  name=CurrentMetadataVersion
kafka.controller:type=KafkaController,
  name=LastAppliedRecordOffset</code></pre>
</div>
<div class="card fragment">
<h4>Tooling Gaps</h4>
<ul>
<li>Some tools <strong>still expect ZooKeeper</strong> (older Kafka UI, CMAK)</li>
<li><code>kafka-metadata.sh</code> is the new CLI — less mature</li>
<li><span class="accent-green">✅</span> Client libraries: fully compatible — <strong>no client-side changes</strong></li>
<li><span class="accent-green">✅</span> Strimzi (K8s) — full KRaft support</li>
</ul>
</div>
</div>

<strong>Recommendation:</strong> Build custom KRaft dashboards from day one. Don't rely on ZK-era templates. <!-- .element: class="fragment" style="font-size: 0.75em; color: #555;" -->

Note:
Good news: clients don't change. Bad news: your ops scripts probably need updating.

---

## Failure Scenario <span class="accent-red">Matrix</span>

Photograph this slide <!-- .element: class="subtitle" -->

| Scenario | Data Plane | Metadata | Recovery |
|----------|-----------|----------|----------|
| 1 controller down (of 3) | <span class="accent-green">✅ Normal</span> | <span class="accent-green">✅ Normal</span> | Automatic |
| 2 controllers down (of 3) | <span class="accent-green">✅ Normal</span> | <span class="accent-red">❌ Stalled</span> | Manual — restore 1 ASAP |
| Active controller killed | <span class="accent-green">✅ Normal</span> | <span class="accent-yellow">⏸ 1–3 sec</span> | Auto re-election |
| Active controller slow disk | <span class="accent-green">✅ Normal</span> | <span class="accent-yellow">⚠️ Degraded</span> | Replace disk/node |
| Network partition (leader isolated) | <span class="accent-yellow">⚠️ Minority</span> | <span class="accent-yellow">⚠️ Minority stalled</span> | Auto on heal |
| All controllers down | <span class="accent-green">✅ Brief</span> | <span class="accent-red">❌ Total stall</span> | Restore quorum |
| Full AZ outage (ctrl in 1 AZ) | <span class="accent-red">❌ Partial</span> | <span class="accent-red">❌ Total stall</span> | <strong>Spread across AZs!</strong> |

Note:
🎤 Pause for audience questions (3 min). This matrix is the most actionable slide in the entire deck.
