<span class="tag tag-challenge">Part 8</span>

## Challenge 1: <span class="accent-red">Static Quorum</span>

- <!-- .element: class="fragment" --> Controller voter list is <strong>hardcoded</strong> in `controller.quorum.voters`
- <!-- .element: class="fragment" --> Add/remove a controller → config change + <strong>rolling restart of all nodes</strong>
- <!-- .element: class="fragment" --> <strong>KIP-853</strong> (dynamic quorum reconfiguration) — in progress, not yet GA
- <!-- .element: class="fragment" --> Impact: controller replacement after hardware failure requires careful coordination

<!-- .element: class="fragment" -->

<div class="highlight-box" style="margin-top: 20px;">
<p style="font-size: 0.75em; margin: 0;"><strong>Mitigation:</strong> Automate voter config management with orchestration tools (Ansible, Terraform, Strimzi operator).</p>
</div>

Note:
Be honest. This is a real operational pain point. The audience respects honesty over marketing.

---

## Challenge 2: <span class="accent-red">Metadata Log &amp; Snapshots</span>

- <!-- .element: class="fragment" --> `__cluster_metadata` grows with every metadata change
- <!-- .element: class="fragment" --> Snapshot tuning is critical:
  - Too *infrequent* → large log, slow broker bootstrap
  - Too *frequent* → unnecessary I/O on controllers

```properties
# Key tuning knobs
metadata.log.max.record.bytes.between.snapshots=104857600  # 100MB
metadata.log.max.snapshot.interval.ms=3600000              # 1 hour
```
<!-- .element: class="fragment" -->

Large clusters (&gt;100K partitions): snapshot creation can cause <strong>latency spikes</strong> on the active controller. <!-- .element: class="fragment" style="font-size: 0.75em; color: #444;" -->

Note:
Practical advice. These configs are not well-documented. Share your experience with tuning them.

---

## Challenge 3: <span class="accent-red">Failover Edge Cases</span>

<div class="card-grid" style="margin-top: 20px;">
<div class="card fragment">
<h4 class="accent-green">✅ Happy path</h4>
<p>Leader fails → new leader elected in 1–3 seconds</p>
</div>
<div class="card fragment" style="border-color: var(--accent-red);">
<h4 class="accent-red">⚠️ Same-AZ controllers</h4>
<p>AZ outage = total quorum loss</p>
</div>
<div class="card fragment" style="border-color: var(--accent-red);">
<h4 class="accent-red">⚠️ Slow disk</h4>
<p>Active controller slow disk → increased commit latency for ALL metadata ops</p>
</div>
<div class="card fragment" style="border-color: var(--accent-red);">
<h4 class="accent-red">⚠️ Network partition</h4>
<p>Leader isolated → steps down, brokers experience metadata blackout</p>
</div>
</div>

During short outages: <span class="accent-green">data plane continues</span> (produce/consume works). But: <span class="accent-red">no metadata changes</span> — no new topics, no reassignment, no ISR updates. <!-- .element: class="fragment" style="font-size: 0.78em; margin-top: 15px;" -->

Note:
Each of these is a scenario the audience might encounter. Be specific about what works and what doesn't.

---

## Challenge 4: <span class="accent-red">Monitoring Gaps</span>

```text
# Essential KRaft metrics
kafka.controller:type=QuorumController,name=EventQueueTimeMs
kafka.controller:type=QuorumController,name=EventQueueProcessingTimeMs
kafka.server:type=MetadataLoader,name=CurrentMetadataVersion
kafka.controller:type=KafkaController,name=LastAppliedRecordOffset
kafka.server:type=MetadataLoader,name=HandleLoadSnapshotCount
```

<!-- .element: class="fragment" -->

```yaml
# Prometheus alert rules
- alert: KRaftNoActiveController
  expr: sum(kafka_controller_kafkacontroller_activecontrollercount) != 1
  for: 30s

- alert: KRaftMetadataLag
  expr: kafka_server_metadataloader_lastappliedrecordoffset
        - on() kafka_controller_quorumcontroller_lastcommittedrecordoffset > 1000
  for: 2m
```

<strong>Recommendation:</strong> Build custom dashboards from day one. Don't rely on ZK-era templates. <!-- .element: class="fragment" style="font-size: 0.75em; color: #555;" -->

Note:
These alert rules are gold. The audience will photograph this. ZK-era dashboards are useless for KRaft.

---

## Challenge 5: <span class="accent-red">Tooling Maturity</span>

- <!-- .element: class="fragment" --> Some tools <strong>still expect ZooKeeper</strong>:
  - Older Kafka UI, CMAK versions
  - Custom scripts using `kafka-zookeeper-shell.sh`
  - Third-party backup/restore tools
- <!-- .element: class="fragment" --> `kafka-metadata.sh` is the new CLI — less mature than ZK tooling
- <!-- .element: class="fragment accent-green" --> Client libraries: fully compatible — <strong>no client-side changes</strong>
- <!-- .element: class="fragment" --> Operator ecosystem:
  - <span class="accent-green">✅</span> Strimzi (Kubernetes) — full KRaft support
  - <span class="accent-yellow">⚠️</span> Other operators — varying maturity

Note:
Good news: clients don't change. Bad news: your ops scripts probably need updating.

---

## Challenge 6: <span class="accent-red">The One-Way Door</span>

Once migration is finalized → <strong>no rollback to ZooKeeper</strong>. <!-- .element: style="font-size: 0.85em;" -->

<!-- .element: class="fragment" style="margin-top: 20px;" -->

Mitigation strategy: <!-- .element: style="font-size: 0.78em; margin-bottom: 10px;" -->

- Test in staging with <strong>production-like traffic and partition counts</strong>
- Run bridge mode for <strong>weeks</strong>, not hours
- Monitor metadata consistency <strong>before</strong> finalizing
- Keep ZK ensemble running (unused) for a grace period
- Document all KRaft operational procedures <strong>before</strong> finalizing

Note:
This is the slide that prevents disasters. Be emphatic. Weeks in bridge mode, not hours.

---

## Challenge 7: <span class="accent-red">Network Partitions</span>

<div class="card-grid three-col" style="margin-top: 20px;">
<div class="card fragment" style="border-color: var(--accent-blue);">
<h4 class="accent-green">Majority side</h4>
<p>Continues normally — elects new leader if needed</p>
</div>
<div class="card fragment" style="border-color: var(--accent-red);">
<h4 class="accent-red">Minority side</h4>
<p>Controllers can't commit — metadata ops stall</p>
</div>
<div class="card fragment" style="border-color: var(--accent-black);">
<h4 class="accent-yellow">Minority brokers</h4>
<p>Serve existing traffic but no metadata updates</p>
</div>
</div>

<!-- .element: class="fragment" style="margin-top: 20px;" -->

Monitor during partitions: <!-- .element: style="font-size: 0.78em;" -->

- `UncleanLeaderElection` count <!-- .element: style="font-size: 0.72em;" -->
- `MetadataFetchTimeMs` on brokers (spikes when unreachable) <!-- .element: style="font-size: 0.72em;" -->
- Controller logs: `"Timeout while awaiting fetch response"` <!-- .element: style="font-size: 0.72em;" -->

Note:
Key difference from ZK era: Kafka now handles split-brain directly via Raft instead of delegating to ZAB.

---

## Challenge 8: <span class="accent-red">Scaling at Extremes</span>

- <!-- .element: class="fragment" --> Millions of partitions → `__cluster_metadata` snapshot: <strong>100s MB to GB</strong>
- <!-- .element: class="fragment" --> Controller memory: full metadata image in memory
  - Rule of thumb: ~1–2 KB per partition-replica → 1M partitions ≈ 1–2 GB
- <!-- .element: class="fragment" --> New broker bootstrap: must replay snapshot + recent log entries
  - At extreme scale: can take <strong>minutes</strong>

<!-- .element: class="fragment" -->

<div class="highlight-box" style="margin-top: 15px;">
<p style="font-size: 0.75em; margin: 0;">
<strong>Mitigation:</strong> Dedicated high-memory controller nodes with fast NVMe storage. Tune snapshot intervals. Consider separate clusters beyond ~2M partitions.
</p>
</div>

Note:
This is the deep-dive-audience-only content. Most people won't hit this, but those who do need to know.

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
