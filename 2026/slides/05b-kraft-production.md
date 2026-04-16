<span class="tag tag-part">Part 5b</span>

## <span class="accent-green">KRaft</span> in Production

Key requirements for a stable deployment <!-- .element: class="subtitle" -->

<div class="card-grid" style="margin-top: 20px;">
<div class="card fragment">
<h4 class="accent-green">Dedicated Controllers</h4>
<p>Deploy 3 (or 5) <strong>dedicated</strong> controllers. Do not use combined mode for production.</p>
</div>
<div class="card fragment">
<h4 class="accent-green">Fast Storage (SSD/NVMe)</h4>
<p>Controllers persist the <code>__cluster_metadata</code> log. Fast I/O prevents Raft election timeouts.</p>
</div>
<div class="card fragment">
<h4 class="accent-green">Network Prioritization</h4>
<p>Controller quorum traffic should utilize a low-latency network backbone to maintain stability.</p>
</div>
<div class="card fragment">
<h4 class="accent-green">Key Metrics</h4>
<p>Alert on <code>ActiveControllerCount</code>, <code>MetadataErrorCount</code>, and <code>CurrentState</code> to detect split-brain or election storms.</p>
</div>
</div>

<strong>Production Tip:</strong> Formatting the storage directory (<code>kafka-storage.sh format</code>) is a hard requisite before starting any node! <!-- .element: class="fragment" style="font-size: 0.75em; margin-top: 20px; color: #555;" -->

Note:
When running KRaft, treat the controllers with the same respect you gave ZK nodes. Fast disks are non-negotiable!

---

## <span class="accent-green">Controller</span> Placement Strategy

Surviving Availability Zone (AZ) Failures <!-- .element: class="subtitle" -->

<div class="split-layout">
<div class="split-left" style="font-size: 0.8em;">

### Single Region (3 AZs)
- **AZ-A**: 1 Controller
- **AZ-B**: 1 Controller
- **AZ-C**: 1 Controller
<p style="font-size: 0.9em; font-weight: bold; color: var(--accent-green); margin-top: -10px;">✓ Tolerates loss of any 1 entire AZ</p>

### Dual Datacenter
- <strong>High Risk</strong>
- A 3-node or 5-node quorum evenly split across two datacenters will fail or split-brain if the link drops. You need a 3rd tie-breaker AZ.

</div>
<div class="split-right fragment" style="font-size: 0.8em;">

### Best Practices
- **Hardware Isolation**: Ensure controllers are on distinct racks, power supplies, and hypervisors.
- **Node IDs**: Number your controllers sequentially (`1, 2, 3`) and map them logically to your infrastructure zones.
- **Broker Fetching**: Brokers in remote regions can observe and fetch metadata without impacting the Raft quorum's commit latency.

</div>
</div>

Note:
Raft requires a strict majority. If you lose the majority, the cluster metadata becomes read-only and no partitions can change leaders. Treat controller placement like your most critical database.

---

## Metadata <span class="accent-green">Snapshots</span>

Preventing infinite growth of the `__cluster_metadata` topic <!-- .element: class="subtitle" -->

<div class="card-grid" style="margin-top: 25px;">
<div class="card fragment">
<h4 class="accent-green">Memory Efficiency</h4>
<p>Brokers don't need to cache the entire cluster state aggressively. They just tail the log.</p>
</div>
<div class="card fragment">
<h4 class="accent-green">Continuous Snapshotting</h4>
<p>Controllers periodically serialize their in-memory state to snapshot files, allowing older log segments to be safely deleted.</p>
</div>
<div class="card fragment">
<h4 class="accent-green">Fast Restarts</h4>
<p>On startup, a broker loads the latest snapshot and then merely replays the delta of recent log records.</p>
</div>
<div class="card fragment">
<h4 class="accent-green">Tuning</h4>
<p>Configure <code>metadata.max.retention.bytes</code> and <code>metadata.max.idle.interval.ms</code> to balance disk usage against fast recovery times.</p>
</div>
</div>

If a broker is offline so long that it misses the oldest log segment, it will automatically download a full snapshot from the leader. <!-- .element: class="fragment" style="font-size: 0.75em; margin-top: 20px; color: #555; text-align: center;" -->

Note:
Explain that this solves a huge ZK problem: zookeeper JVM heap sizes. The snapshot+log model is exactly how Kafka manages state stores in Kafka Streams.
