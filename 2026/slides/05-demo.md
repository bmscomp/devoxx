<!-- .slide: class="center-slide" data-background-gradient="radial-gradient(circle at 50% 50%, rgba(78,205,196,0.12) 0%, transparent 50%)" -->

<span class="tag tag-demo">Part 5</span>

# Live Demo <!-- .element: class="section-title accent-green" -->

25 minutes — 4 scenarios <!-- .element: class="section-subtitle" -->

<div class="card-grid" style="margin-top: 30px; text-align: left;">
<div class="card">
<h4>Demo 1 (10 min)</h4>
<p>Full ZK → KRaft migration — live binary upgrade</p>
</div>
<div class="card">
<h4>Demo 2 (5 min)</h4>
<p>Explore <code>__cluster_metadata</code></p>
</div>
<div class="card">
<h4>Demo 3 (5 min)</h4>
<p>Controller failover — adversarial</p>
</div>
<div class="card">
<h4>Demo 4 (5 min)</h4>
<p>Partition scaling & broker recovery</p>
</div>
</div>

Note:
Switch to live terminal. Have backup pre-recorded videos ready.

---

## Demo 1: ZK → KRaft <span class="accent-green">Migration</span>

Live binary upgrade — 3 brokers + 3 ZK → 3 controllers + 3 brokers <!-- .element: class="subtitle" -->

1. <!-- .element: class="fragment" --> Start with ZK-based cluster (`make start`)
2. <!-- .element: class="fragment" --> Deploy KRaft controllers alongside (`make controllers`)
3. <!-- .element: class="fragment" --> Enable bridge mode — dual-write visible in logs (`make bridge`)
4. <!-- .element: class="fragment" --> Verify bridge mode metadata consistency (`make verify-bridge`)
5. <!-- .element: class="fragment" --> Finalize migration — remove ZK dependency (`make kraft`)
6. <!-- .element: class="fragment" --> Upgrade to Kafka 4.x binaries (`make upgrade`)

```bash
# The entire migration is orchestrated via Makefile
make all  # runs: start → controllers → bridge → kraft → upgrade
```
<!-- .element: class="fragment" -->

Note:
Walk through each phase live. Show the TUI output. Explain what's happening at each step.

---

## Demo 2: Exploring `__cluster_metadata`

```bash
# Dump the metadata log
bin/kafka-metadata.sh --snapshot latest \
  --cluster-id $CLUSTER_ID
```

- <!-- .element: class="fragment" --> Show metadata records: `TopicRecord`, `PartitionRecord`, `RegisterBrokerRecord`
- <!-- .element: class="fragment" --> Visualize the Raft log: offsets, epochs, committed entries
- <!-- .element: class="fragment" --> Compare: in the ZK era, this was opaque znodes — now it's a <strong>readable Kafka log</strong>

Note:
This is the "aha" moment. The audience sees that metadata is just another Kafka log.

---

## Demo 3: Controller <span class="accent-red">Failover</span>

Adversarial — push the system to its limits <!-- .element: class="subtitle" -->

- <!-- .element: class="fragment" --> **Scenario 1:** Kill active controller
  - Watch Raft election in real time (logs + quorum status)
  - New leader elected in <strong><span class="accent-green">seconds</span></strong>
  - Produce/consume during failover → no data loss
- <!-- .element: class="fragment" --> **Scenario 2:** Kill ZK majority (pre-migration)
  - Entire cluster freezes — no new topics, no producer acks
  - <strong>Contrast</strong>: KRaft handles this gracefully

```bash
# Kill the active controller and watch recovery
make controller-failover
# Then check quorum status
make quorum-status
```
<!-- .element: class="fragment" -->

Note:
This is the crowd-pleaser. Killing the leader and watching instant recovery is dramatic. Contrast with the ZK quorum loss.

---

## Demo 4: <span class="accent-green">Partition Scaling</span> & Recovery

Stress-testing the cluster <!-- .element: class="subtitle" -->

- <!-- .element: class="fragment" --> Scale a topic to **10,000 partitions** incrementally
  - Watch partition creation in real time
  - Monitor broker resource usage
- <!-- .element: class="fragment" --> Kill a broker during scaling
  - Run `make restart-brokers` to recover
  - Show automatic ISR recovery

```bash
# Scale partitions
make scale-partitions
# Monitor with live dashboard
make watch
# Restart dead nodes
make restart-brokers
```
<!-- .element: class="fragment" -->

Note:
Reference the file descriptor lesson from the production slides. This demo proves the OS tuning advice.
