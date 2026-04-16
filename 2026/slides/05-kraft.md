<span class="tag tag-part">Part 5</span>

## The Birth of <span class="accent-green">KRaft</span>

KIP-500 (2019) — "Replace ZooKeeper with a Self-Managed Metadata Quorum" <!-- .element: class="subtitle" -->

<div class="card-grid" style="margin-top: 25px;">
<div class="card fragment">
<h4 class="accent-green">Single system</h4>
<p>One deployment, one team, one set of runbooks</p>
</div>
<div class="card fragment">
<h4 class="accent-green">Scalable metadata</h4>
<p>Millions of partitions (vs ~200K practical limit with ZK)</p>
</div>
<div class="card fragment">
<h4 class="accent-green">Fast failover</h4>
<p>Seconds, not minutes</p>
</div>
<div class="card fragment">
<h4 class="accent-green">Strong consistency</h4>
<p>Single source of truth — the Raft log</p>
</div>
</div>

Kafka implemented <strong>its own Raft variant</strong> rather than embedding etcd's — tight integration with Kafka's event-driven, log-based architecture. <!-- .element: class="fragment" style="font-size: 0.78em; margin-top: 20px; color: #444;" -->

Note:
This is the turning point of the talk. Everything before was context — now we get to the meat.

---

## <span class="accent-green">KRaft</span> Architecture

<div class="split-layout">
<div class="split-left">
<img src="img/kraft-architecture.png" alt="KRaft Architecture" style="max-height: 420px; border-radius: 8px;">
</div>
<div class="split-right" style="font-size: 0.78em;">

- <!-- .element: class="fragment" --> <strong>Controllers</strong> (3 or 5) — Raft voters, one is Active Controller (leader)
- <!-- .element: class="fragment" --> <strong>Brokers</strong> — observers, not voters. They <strong>tail</strong> the metadata log
- <!-- .element: class="fragment" --> Combined mode (`process.roles=broker,controller`) — dev/test only
- <!-- .element: class="fragment" --> Brokers are <strong>not</strong> part of the quorum — this is what makes it scale

</div>
</div>

Note:
Key architectural difference: brokers are NOT part of the quorum. They're consumers of the metadata log. This is what makes it scale.

---

## The `__cluster_metadata` Topic

All metadata is a Kafka log — the same model Kafka uses for everything <!-- .element: class="subtitle" -->

<div class="split-layout">
<div class="split-left">

```json
// RegisterBrokerRecord
{
  "type": "RegisterBrokerRecord",
  "version": 1,
  "data": {
    "brokerId": 0,
    "incarnationId": "kRaft-abc-123",
    "brokerEpoch": 42,
    "endPoints": [{"name": "PLAINTEXT", 
                   "host": "broker0", 
                   "port": 9092
                  }],
    "rack": "rack-1"
  }
}
```

</div>
<div class="split-right fragment">

```json
// PartitionRecord
{
  "type": "PartitionRecord",
  "data": {
    "partitionId": 0,
    "topicId": "Tf3Y-TMQR2y9MkZ4eLO_Kg",
    "replicas": [0, 1, 2],
    "isr": [0, 1, 2],
    "leader": 0,
    "leaderEpoch": 1
  }
}
```

</div>
</div>

Note:
Show actual record format. The audience can photograph this. Point out: this is JSON — it's readable.

---

## KRaft ≠ Standard <span class="accent-cyan">Raft</span>

Tailored for Kafka's specific needs <!-- .element: class="subtitle" -->

<div class="card-grid" style="margin-top: 20px;">
<div class="card fragment">
<h4>Event-driven</h4>
<p>Uses Kafka's event loop, not blocking RPC threads</p>
</div>
<div class="card fragment">
<h4>Observers</h4>
<p>Brokers tail the log without voting — standard Raft has only voters</p>
</div>
<div class="card fragment">
<h4>Pull-based</h4>
<p>Followers <strong>fetch</strong> from leader (like Kafka consumers), not push-based</p>
</div>
<div class="card fragment">
<h4>Batch commits</h4>
<p>Multiple metadata changes committed in a single Raft round</p>
</div>
</div>

These choices make KRaft efficient for Kafka's workload: <strong>bursty metadata changes with many observers</strong>. <!-- .element: class="fragment" style="font-size: 0.75em; margin-top: 20px; color: #555;" -->

Note:
The pull-based model is the big insight — brokers fetch metadata like consumers fetch messages. Same model, same efficiency.

---

## Inside the <span class="accent-green">Source Code</span>

Raft is understandable — even in the implementation <!-- .element: class="subtitle" -->

```java
// Simplified from KafkaRaftClient.java — leader election
private void handleVoteRequest(VoteRequestData request) {
    // Step down if we see a higher term
    if (request.candidateEpoch() > quorum.epoch()) {
        transitionToFollower(request.candidateEpoch(), ...);
    }

    // Grant vote if candidate is eligible
    if (canGrantVote(request)) {
        grantVote(request.candidateId());
    } else {
        rejectVote(request.candidateId());
    }
}
```

Key classes: `KafkaRaftClient.java` · `QuorumController.java` · `MetadataLoader.java` <!-- .element: class="fragment" style="font-size: 0.7em; color: #555; margin-top: 10px;" -->

The point: <strong>this isn't a black box</strong>. Raft's design goal (understandability) pays off in the implementation. <!-- .element: class="fragment" style="font-size: 0.78em; margin-top: 10px;" -->

Note:
🎤 Pause for audience questions here (2 min). This is the theoretical half done — good time for Q&A before moving to production.

---

## <span class="accent-green">KRaft</span> Timeline

<div class="progress-line fragment"><span class="year">2019</span> KIP-500 proposed (Colin McCabe, Confluent)</div>
<div class="progress-line fragment"><span class="year">2020</span> Early access / preview in Kafka 2.8</div>
<div class="progress-line fragment" style="border: 1px solid var(--accent-blue);"><span class="year">2022</span> Kafka 3.3: KRaft marked <strong class="accent-green">PRODUCTION-READY</strong></div>
<div class="progress-line fragment"><span class="year">2023</span> Kafka 3.5: ZK-to-KRaft migration GA</div>
<div class="progress-line fragment"><span class="year">2024</span> Kafka 3.7: migration improvements</div>
<div class="progress-line fragment" style="border: 1px solid var(--accent-blue);"><span class="year">2024</span> Kafka 4.0: ZooKeeper support <strong class="accent-red">REMOVED</strong></div>
<div class="progress-line fragment"><span class="year">2025+</span> KRaft-only world — no going back</div>

Note:
5 years from proposal to ZK removal. Show that this wasn't rushed — it was carefully planned and gradually rolled out.
