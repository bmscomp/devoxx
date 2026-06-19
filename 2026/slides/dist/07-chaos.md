<!-- .slide: class="center-slide section-divider" data-background-color="#1a0533" -->

<div style="font-size: 3.5em; margin-bottom: 10px;">💥</div>

## Kafka & <span style="color: #c084fc;">Chaos Engineering</span> <!-- .element: style="color: #e2e8f0;" -->

Break it on purpose — before production does <!-- .element: style="color: #94a3b8; font-size: 0.75em;" -->

Note:
Section divider. We shift from "what can go wrong" to "how to prove your cluster survives it."

---

<span class="tag" style="background: rgba(192,132,252,0.12); color: #a855f7;">Part 7</span>

## Kafka & <span style="color: #a855f7;">Chaos Engineering</span>

Validate resilience before your users discover the gaps <!-- .element: class="subtitle" -->

<div class="card-grid" style="margin-top: 25px;">
<div class="card fragment" style="border-top: 3px solid #a855f7;">
<h4 style="color: #7c3aed !important;">🧪 The Principle</h4>
<p>Intentionally inject <strong>controlled failures</strong> into your system to discover weaknesses before they become incidents.</p>
</div>
<div class="card fragment" style="border-top: 3px solid #dc2626;">
<h4 style="color: #dc2626 !important;">❓ Why Kafka Specifically?</h4>
<p>Kafka is the <strong>nervous system</strong> of your architecture. If it fails unexpectedly, every downstream service fails with it.</p>
</div>
</div>

<div class="highlight-box fragment" style="margin-top: 15px; border-left-color: #a855f7; background: rgba(168,85,247,0.05);">
<p style="font-size: 0.75em; margin: 0;">💡 <strong>Netflix principle:</strong> "Hope is not a strategy. Chaos is." — systems that are <em>never</em> tested under failure are systems <em>guaranteed</em> to fail when it matters most.</p>
</div>

Note:
Chaos Engineering originated at Netflix (Chaos Monkey, 2010). The discipline has matured into a full engineering practice. Kafka is a perfect target: it's distributed, stateful, and often the single point of data flow.

---

## What to <span class="accent-red">Break</span> in Kafka

Four failure domains that matter <!-- .element: class="subtitle" -->

<div class="card-grid" style="margin-top: 20px;">
<div class="card card-danger fragment">
<h4 class="accent-red">💀 Controller Failure</h4>
<ul>
<li>Kill the active KRaft leader</li>
<li>Measure: re-election time</li>
<li>Verify: metadata ops resume</li>
<li>Goal: <strong>&lt; 3 seconds</strong> with KRaft</li>
</ul>
</div>
<div class="card card-danger fragment">
<h4 class="accent-red">💀 Broker Failure</h4>
<ul>
<li>Kill the partition leader broker</li>
<li>Measure: ISR re-election latency</li>
<li>Verify: producers/consumers recover</li>
<li>Goal: <strong>zero data loss</strong> with <code>acks=all</code></li>
</ul>
</div>
<div class="card card-danger fragment">
<h4 class="accent-red">🌐 Network Partition</h4>
<ul>
<li>Isolate controller from quorum majority</li>
<li>Verify: leader steps down, new leader elected</li>
<li>Verify: minority side stalls (metadata only)</li>
<li>Tool: <strong>tc netem</strong> / Toxiproxy</li>
</ul>
</div>
<div class="card card-danger fragment">
<h4 class="accent-red">💽 Disk Pressure</h4>
<ul>
<li>Fill broker log disk to 90%</li>
<li>Verify: broker sets partitions to read-only</li>
<li>Verify: alerts fire before full saturation</li>
<li>Tool: <strong>stress-ng</strong> / Litmus</li>
</ul>
</div>
</div>

Note:
Each failure domain maps to a real incident category. These are not hypotheticals — they are the most common Kafka production outages.

---

## 🧪 Experiment: <span class="accent-purple">Controller Failover</span>

The most impactful KRaft chaos test <!-- .element: class="subtitle" -->

<div class="card-grid" style="margin-top: 20px;">
<div class="card fragment" style="border-top: 3px solid #a855f7;">
<h4 style="color: #7c3aed !important;">📋 Hypothesis</h4>
<p>When the active KRaft leader is killed, a new leader will be elected in <strong>under 3 seconds</strong> and metadata operations will resume without operator intervention.</p>
</div>
<div class="card fragment" style="border-top: 3px solid #16a34a;">
<h4 class="accent-green">✅ Steady State</h4>
<ul>
<li>All 3 controllers running</li>
<li>Leaders elected, lag = 0</li>
<li>Producers writing at nominal rate</li>
<li>Consumer lag ≤ 500ms</li>
</ul>
</div>
</div>

```bash
# 1. Identify the active leader
make quorum-status

# 2. Inject failure (from the demo Makefile!)
make controller-failover

# 3. Observe metrics — time the election
# 4. Verify producers / consumers recovered
make verify-bridge
```
<!-- .element: class="fragment" -->

<div class="highlight-box fragment" style="margin-top: 10px; border-left-color: #a855f7; background: rgba(168,85,247,0.05);">
<p style="font-size: 0.72em; margin: 0;">🎯 <strong>Expected result with KRaft:</strong> election in 1–3s · data plane uninterrupted · no manual action</p>
</div>

Note:
This experiment is already implemented in our Makefile as `make controller-failover`. The audience saw it in the demo. Now we're framing it as a chaos experiment with a hypothesis and measurable outcome.

---

## 🧪 Experiment: <span class="accent-red">Broker Loss Under Load</span>

Does `acks=all` + `min.insync.replicas` actually hold? <!-- .element: class="subtitle" -->

```bash
# Terminal 1: Produce continuously
make produce-messages

# Terminal 2: Watch consumer lag
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group my-group

# Terminal 3: Kill the partition leader
kill -9 $(cat .pids/broker1.pid)

# Expected: producers retry, zero messages lost
# Failure: any "NOT_ENOUGH_REPLICAS" errors slip through
```
<!-- .element: class="fragment" -->

<div class="card-grid" style="margin-top: 15px;">
<div class="card card-success fragment">
<h4 class="accent-green">✅ Passing Criteria</h4>
<ul>
<li>No data loss (verify with <code>--from-beginning</code>)</li>
<li>Producer retries visible in logs</li>
<li>New partition leader elected within ISR</li>
<li>Consumer recovers automatically</li>
</ul>
</div>
<div class="card card-danger fragment">
<h4 class="accent-red">❌ Failing Criteria</h4>
<ul>
<li>Messages silently dropped</li>
<li>Producer throws unhandled exception</li>
<li>Consumer stuck, never re-assigned</li>
<li>ISR never recovers after broker restart</li>
</ul>
</div>
</div>

Note:
This test validates your producer and consumer configuration, not just the broker. acks=all with min.insync.replicas=2 must be set on both sides.

---

## Chaos Engineering <span class="accent-purple">Toolbox</span>

<div class="card-grid three-col" style="margin-top: 20px;">
<div class="card fragment" style="border-top: 3px solid #a855f7;">
<h4 style="color: #7c3aed !important;">🐒 Chaos Monkey</h4>
<p>Netflix OSS. Randomly kills instances in a service group.</p>
<p style="margin-top: 8px; font-size: 0.75em; color: #64748b;">Best for: broker/controller kill injection in cloud envs</p>
</div>
<div class="card fragment" style="border-top: 3px solid #0891b2;">
<h4 class="accent-cyan">🔧 Toxiproxy</h4>
<p>Shopify OSS. TCP proxy that simulates network conditions: latency, jitter, packet loss, timeouts.</p>
<p style="margin-top: 8px; font-size: 0.75em; color: #64748b;">Best for: network partition & degradation tests</p>
</div>
<div class="card fragment" style="border-top: 3px solid #16a34a;">
<h4 class="accent-green">⚗️ Chaos Mesh / Litmus</h4>
<p>CNCF projects for Kubernetes. Native pod kill, network chaos, I/O failure injection via CRDs.</p>
<p style="margin-top: 8px; font-size: 0.75em; color: #64748b;">Best for: Strimzi/K8s-based Kafka deployments</p>
</div>
</div>

<div class="card-grid" style="margin-top: 16px;">
<div class="card fragment" style="border-top: 3px solid #ea580c;">
<h4 class="accent-orange">🐛 Byteman / JVM Fault Injection</h4>
<p>Inject faults directly into the JVM at method level — simulate ZK session expiry, GC stalls, or slow disk writes without touching infra.</p>
</div>
<div class="card fragment" style="border-top: 3px solid #ca8a04;">
<h4 class="accent-yellow">📊 tc netem (Linux)</h4>
<p>Kernel-level network emulation: <code>tc qdisc add dev eth0 netem delay 200ms loss 10%</code> — zero dependency, available everywhere.</p>
</div>
</div>

Note:
Don't be overwhelmed by tool choice. Start with kill signals and tc netem — they cover 80% of real-world scenarios and require zero infra. Graduate to Chaos Mesh for Kubernetes deployments.

---

## Toxiproxy: <span class="accent-cyan">Network Chaos</span> for Kafka

Simulate degraded network between clients and brokers <!-- .element: class="subtitle" -->

```bash
# Install and start Toxiproxy
brew install toxiproxy
toxiproxy-server &

# Create a proxy sitting in front of broker 1
toxiproxy-cli create kafka-broker1 \
  --listen  localhost:19092 \
  --upstream localhost:9092

# Add 200ms latency with 20ms jitter
toxiproxy-cli toxic add kafka-broker1 \
  --type latency --attribute latency=200 --attribute jitter=20

# Simulate 10% packet loss
toxiproxy-cli toxic add kafka-broker1 \
  --type bandwidth --attribute rate=100

# Point your producer at :19092 instead of :9092
# Watch consumer lag and retry rates climb
```
<!-- .element: class="fragment" -->

<div class="highlight-box fragment" style="margin-top: 12px;">
<p style="font-size: 0.72em; margin: 0;">🎯 <strong>What this proves:</strong> your <code>request.timeout.ms</code>, <code>retry.backoff.ms</code>, and <code>delivery.timeout.ms</code> settings are tuned for degraded conditions — not just the happy path.</p>
</div>

Note:
Toxiproxy is the fastest way to prove your Kafka client configuration holds under adverse network conditions without touching production. Run it in CI.

---

## Chaos Testing <span class="accent-green">Checklist</span>

Run this against every environment before go-live <!-- .element: class="subtitle" -->

| Experiment | Tool | Pass Criteria | Frequency |
|------------|------|--------------|-----------|
| Kill active KRaft leader | `kill -9` / Makefile | Re-election < 3s, no data loss | Before every major change |
| Kill 1 of 3 brokers | `kill -9` | ISR recovers, consumers reconnect | Weekly |
| Kill 2 of 3 brokers | `kill -9` | Cluster degrades gracefully, no corruption | Monthly |
| Network partition (controller) | `tc netem` / Toxiproxy | Minority stalls, majority continues | Quarterly |
| Disk full on broker | `fallocate -l 95%` | Read-only mode, alert fires | Monthly |
| Slow disk on controller | `ionice` / stress-ng | Raft lag alerts trigger | Quarterly |
| Consumer group crash | `kill -9` | Group rebalances, lag recovers | Before every deploy |
| ZK unavailable (bridge mode) | `kill -9 zk*` | Brokers continue, new metadata stalls | During migration only |

<!-- .element: class="fragment" -->

Note:
🎤 This table is the most practical output of this section. The audience should photograph it and adapt it into their team's runbook.

---

## <span class="accent-purple">Observability</span> During Chaos

You can't fix what you can't see <!-- .element: class="subtitle" -->

<div class="card-grid" style="margin-top: 20px;">
<div class="card fragment" style="border-top: 3px solid #a855f7;">
<h4 style="color: #7c3aed !important;">📈 Key Metrics to Watch</h4>
<ul>
<li><code>UnderReplicatedPartitions</code> — must return to 0</li>
<li><code>ActiveControllerCount</code> — must be exactly 1</li>
<li><code>LeaderElectionRateAndTimeMs</code> — spike = failover event</li>
<li><code>kafka.server:RequestHandlerAvgIdlePercent</code></li>
<li>Consumer group lag (Prometheus <code>kafka_consumergroup_lag</code>)</li>
</ul>
</div>
<div class="card fragment" style="border-top: 3px solid #0891b2;">
<h4 class="accent-cyan">🔍 KRaft-Specific Metrics</h4>
<ul>
<li><code>QuorumController:EventQueueTimeMs</code></li>
<li><code>MetadataLoader:CurrentMetadataVersion</code></li>
<li><code>LastAppliedRecordOffset</code> — controller lag</li>
<li><code>KafkaController:LastCommittedRecordOffset</code></li>
</ul>
</div>
</div>

<div class="highlight-box fragment" style="margin-top: 12px;">
<p style="font-size: 0.72em; margin: 0;">⚠️ <strong>Rule:</strong> Never run a chaos experiment without your <strong>full observability stack active</strong>. Chaos without dashboards is just random destruction.</p>
</div>

Note:
Set up dashboards BEFORE you inject chaos. The goal is to observe, learn, and tune — not to accidentally take down prod.

---

## Chaos Engineering <span class="accent-green">Maturity Model</span>

Where is your team today? <!-- .element: class="subtitle" -->

<div style="max-width: 860px; margin: 20px auto 0;">
<div class="progress-line fragment" style="border-left-color: #64748b; background: rgba(100,116,139,0.08);">
  <span class="year" style="background: #64748b;">L0</span>
  <span><strong>No testing</strong> — failures discovered by users in production</span>
</div>
<div class="progress-line fragment" style="border-left-color: #ea580c; background: rgba(234,88,12,0.08);">
  <span class="year" style="background: #ea580c;">L1</span>
  <span><strong>Manual kill tests</strong> — kill a broker, watch what happens, fix config</span>
</div>
<div class="progress-line fragment" style="border-left-color: #ca8a04; background: rgba(202,138,4,0.08);">
  <span class="year" style="background: #ca8a04;">L2</span>
  <span><strong>Scripted experiments</strong> — repeatable tests, documented hypotheses, Makefile/scripts</span>
</div>
<div class="progress-line fragment" style="border-left-color: #2563eb; background: rgba(37,99,235,0.08);">
  <span class="year" style="background: #2563eb;">L3</span>
  <span><strong>Automated chaos in CI</strong> — experiments run on every major change with pass/fail gates</span>
</div>
<div class="progress-line fragment" style="border-left-color: #16a34a; background: rgba(22,163,74,0.08);">
  <span class="year" style="background: #16a34a;">L4</span>
  <span><strong>GameDays</strong> — scheduled, cross-team failure drills with real production traffic</span>
</div>
<div class="progress-line fragment" style="border-left-color: #a855f7; background: rgba(168,85,247,0.08);">
  <span class="year" style="background: #a855f7;">L5</span>
  <span><strong>Continuous chaos</strong> — automated random fault injection in production, 24/7 (Netflix/LinkedIn scale)</span>
</div>
</div>

Note:
Most teams are at L0 or L1. Getting to L2 is achievable in a sprint. L3 requires CI integration but pays dividends immediately. L4/L5 require organizational maturity.
