<!-- .slide: class="center-slide" data-background-gradient="radial-gradient(circle at 50% 50%, rgba(78,205,196,0.12) 0%, transparent 50%)" -->

<span class="tag tag-demo">Part 7</span>

# Live Demo <!-- .element: class="section-title accent-green" -->

25 minutes — 4 scenarios <!-- .element: class="section-subtitle" -->

<div class="card-grid" style="margin-top: 30px; text-align: left;">
<div class="card">
<h4>Demo 1 (10 min)</h4>
<p>Deploy KRaft cluster on Kind</p>
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
<p>ZK→KRaft migration walkthrough</p>
</div>
</div>

Note:
Switch to live terminal. Have backup pre-recorded videos ready. Keep "watch kubectl get pods" visible.

---

## Demo 1: KRaft on <span class="accent-blue">Kind</span>

3 controllers + 3 brokers — from zero <!-- .element: class="subtitle" -->

- Walk through Helm chart manifests:
  - `process.roles`, `node.id`, `controller.quorum.voters`
  - Listener config: CONTROLLER vs PLAINTEXT
- Watch cluster come up, controllers elect a leader
- Create a topic, produce & consume — it works, <strong>no ZooKeeper</strong>

```bash
# Create topic
kafka-topics.sh --create --topic demo-kraft \
  --partitions 6 --replication-factor 3 \
  --bootstrap-server localhost:9092

# Produce
echo "Hello KRaft!" | kafka-console-producer.sh \
  --topic demo-kraft --bootstrap-server localhost:9092

# Consume
kafka-console-consumer.sh --topic demo-kraft \
  --from-beginning --bootstrap-server localhost:9092
```

Note:
Terminal time. Make it interactive. Maybe ask someone in the audience to give you a topic name.

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

- <!-- .element: class="fragment" --> <strong>Scenario 1:</strong> Kill active controller pod
  - Watch Raft election in real time (logs + metrics)
  - New leader elected in <strong><span class="accent-green">seconds</span></strong>
  - Produce/consume during failover → no data loss
- <!-- .element: class="fragment" --> <strong>Scenario 2:</strong> Network partition (`tc netem` / NetworkPolicy)
  - Isolate the leader → watch it step down
  - Majority side elects new leader
  - Heal partition → old leader rejoins as follower

Note:
This is the crowd-pleaser. Killing the leader and watching instant recovery is dramatic.

---

## Demo 4: ZK → KRaft <span class="accent-green">Migration</span>

Pre-recorded walkthrough with live narration <!-- .element: class="subtitle" -->

1. <!-- .element: class="fragment" --> Start with ZK-based cluster (3 ZK + 3 brokers)
2. <!-- .element: class="fragment" --> Deploy KRaft controllers alongside
3. <!-- .element: class="fragment" --> Enable bridge mode — dual-write visible in logs
4. <!-- .element: class="fragment" --> Finalize migration — remove ZK dependency
5. <!-- .element: class="fragment" --> Decommission ZooKeeper ensemble 

Note:
This can be pre-recorded if the live setup is too complex. Narrate the video, pause on key steps.
