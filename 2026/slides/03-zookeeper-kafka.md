<span class="tag tag-part">Part 3</span>

## ZooKeeper's Role in <span class="accent-orange">Kafka</span>

<div class="diagram-box">
/kafka
├── /brokers
│   ├── /ids/[0,1,2...]          ← registered brokers <span class="accent-yellow">(ephemeral)</span>
│   └── /topics/[name]
│       └── /partitions/[0,1..]  ← partition assignments &amp; ISR
├── /controller                  ← current controller ID <span class="accent-yellow">(ephemeral)</span>
├── /controller_epoch            ← fencing token (monotonic)
├── /isr_change_notification     ← ISR change queue
├── /consumers                   ← consumer groups <span class="accent-red">(pre-0.9)</span>
└── /admin
    └── /delete_topics           ← pending topic deletions
</div>

Note:
Walk through the ZK tree. Highlight the ephemeral nodes — they're the key to failure detection.

---

## The <span class="accent-orange">Controller</span> + ZooKeeper Flow

- <!-- .element: class="fragment" --> Broker startup → creates `/brokers/ids/{id}` <strong><span class="accent-yellow">(ephemeral)</span></strong>
- <!-- .element: class="fragment" --> First broker to create `/controller` becomes <strong>the Controller</strong>
- <!-- .element: class="fragment" --> Controller sets <strong>watches</strong> on ZK:
  - Broker failure → ephemeral node disappears → watch fires
  - Topic creation → admin request written to `/admin`
  - ISR changes → brokers write to `/isr_change_notification`

<!-- .element: class="fragment" -->

<div class="highlight-box" style="margin-top: 20px;">
<p style="font-size: 0.75em; margin: 0; text-align: center;">
<strong>ZK</strong> ← <span class="accent-orange">Controller</span> → <strong>Brokers</strong> ← <strong>ZK</strong>
</p>
<p style="font-size: 0.65em; margin: 5px 0 0 0; color: #555; text-align: center;">
Metadata bounces between two systems
</p>
</div>

Note:
Show the data flow. Highlight that metadata lives in ZK but must be propagated to brokers. This dual-source-of-truth is where problems start.

---

<!-- .slide: data-background-gradient="radial-gradient(circle at 50% 50%, rgba(251,191,36,0.06) 0%, transparent 60%)" -->

## The Golden Era 

Why ZooKeeper worked well — for a while <!-- .element: class="subtitle" -->

- <!-- .element: class="fragment" --> <strong>Separation of concerns</strong> — Kafka did log storage, ZK did coordination
- <!-- .element: class="fragment" --> <strong>Battle-tested consensus</strong> — ZAB had years of production at Yahoo!, Hadoop, HBase
- <!-- .element: class="fragment" --> <strong>Ephemeral nodes</strong> — elegant failure detection, no custom heartbeat needed
- <!-- .element: class="fragment" --> <strong>Watches</strong> — reactive metadata updates, no polling
- <!-- .element: class="fragment" --> <strong>Ecosystem momentum</strong> — everyone used ZK, operational knowledge was widespread

At moderate scale (tens of thousands of partitions), this worked <strong>beautifully</strong>. <!-- .element: class="fragment" style="font-size: 0.8em; margin-top: 20px; color: #444;" -->

Note:
Give ZooKeeper its due. It was the right choice and served Kafka well. Don't trash ZK — acknowledge its value before showing the problems.

---

## The Cracks Appear: <span class="accent-red">Operational Burden</span>

- <!-- .element: class="fragment" --> <strong>Two distributed systems to operate</strong>
  - Separate deployment, monitoring, upgrades, JVM tuning, security
  - Kafka team ≠ ZooKeeper team in most organizations
- <!-- .element: class="fragment" --> <strong>Upgrade hell</strong>
  - Rolling upgrade ZK first (carefully!), then rolling upgrade Kafka
  - ZK 3.4 → 3.5 → 3.6 each had breaking behavioral changes
- <!-- .element: class="fragment" --> <strong>Security model mismatch</strong>
  - Kafka SASL/SSL completely separate from ZK authentication
  - Securing the ZK↔Kafka channel: often overlooked in production

Note:
Show empathy. "If you've operated ZK + Kafka, you know the pain of coordinating two rolling upgrades on a Friday."

---

## The Cracks Appear: <span class="accent-red">Scalability Limits</span>

- <!-- .element: class="fragment" --> <strong>Controller failover storm</strong>
  - New controller reads <strong>ALL metadata from ZK</strong>
  - Time: <strong>O(partitions × replicas)</strong>
  - LinkedIn: ~2M partitions → failover took <strong><span class="accent-red">minutes</span></strong>
- <!-- .element: class="fragment" --> <strong>Metadata inconsistency</strong> — dual source of truth
  - ZK has "official" metadata, brokers cache a local copy
  - After network issues: caches diverge → stale reads
- <!-- .element: class="fragment" --> <strong>ZK write throughput bottleneck</strong>
  - Every ISR change = ZK write
  - &gt;100K partitions: ZK becomes the bottleneck, not Kafka

Note:
The LinkedIn stat is powerful. Minutes of metadata unavailability during controller failover. This is the breaking point.

---

## The Writing on the Wall

<div class="progress-line fragment"><span class="year">2015</span> Kafka 0.9: consumer groups <strong>moved out of ZK</strong> → <code>__consumer_offsets</code></div>
<div class="progress-line fragment"><span class="year">2017+</span> Kafka 2.x: admin operations stop requiring direct ZK access</div>
<div class="progress-line fragment" style="border: 1px solid var(--accent-blue);"><span class="year" style="color: var(--accent-blue);">2019</span> <strong>KIP-500</strong> — Colin McCabe proposes removing ZooKeeper entirely</div>

<div class="quote-block" style="margin-top: 25px; border-color: var(--accent-blue);">
"We should manage metadata the same way we manage data: with Apache Kafka itself."
<span class="author">— KIP-500</span>
</div>

<!-- .element: class="fragment" -->

The pattern was clear: Kafka was slowly <strong>absorbing ZooKeeper's responsibilities</strong> — and KIP-500 made it official. <!-- .element: class="fragment" style="font-size: 0.8em; margin-top: 15px; color: #333;" -->

Note:
🎤 Pause for audience questions here (2 min). "Before we move to Raft, any questions on the ZooKeeper story?"
