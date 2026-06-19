<!-- .slide: class="center-slide section-divider" data-background-color="#1e1b4b" -->

<div style="font-size: 3.5em; margin-bottom: 10px;">🧬</div>

## The <span style="color: #a78bfa;">Consensus</span> Problem <!-- .element: style="color: #e2e8f0;" -->

How do N nodes agree — when some may fail? <!-- .element: style="color: #94a3b8; font-size: 0.75em;" -->

Note:
Section divider. Pause, let the audience reset. We're moving from Kafka-as-distributed-system to the theory behind it.

---

<span class="tag tag-part">Part 2</span>

## The <span class="accent-purple">Consensus</span> Problem

Getting N nodes to agree on a single value, even if some nodes fail. <!-- .element: style="font-size: 0.85em; color: #333;" -->

<div class="card-grid three-col fragment">
<div class="card">
<h4 class="accent-purple">Validity</h4>
<p>Only proposed values can be chosen</p>
</div>
<div class="card">
<h4 class="accent-purple">Agreement</h4>
<p>All correct nodes choose the same value</p>
</div>
<div class="card">
<h4 class="accent-purple">Termination</h4>
<p>Every correct node eventually decides</p>
</div>
</div>

<div class="highlight-box fragment" style="margin-top: 25px;">
<p style="font-size: 0.75em; margin: 0;"><strong class="accent-red">FLP Impossibility (1985)</strong> — Consensus is <em>impossible</em> in a fully asynchronous system with even one faulty process.</p>
<p style="font-size: 0.7em; margin: 8px 0 0 0; color: #555;">Real systems work around this with <strong>timeouts</strong> and <strong>failure detectors</strong>.</p>
</div>

Note:
Set the theoretical foundation. FLP is important because it explains why every consensus protocol uses timeouts — there's no perfect solution.

---

<!-- .slide: data-background-gradient="radial-gradient(circle at 50% 50%, rgba(168,85,247,0.08) 0%, transparent 60%)" -->

## <span class="accent-purple">Paxos</span> — Where It All Began

1989 / Leslie Lamport <!-- .element: class="subtitle" -->

<div style="display: flex; gap: 30px; align-items: flex-start;">
<div style="flex: 1;">

- <!-- .element: class="fragment" --> Invented by <strong>Leslie Lamport</strong> — also created LaTeX & defined distributed systems
- <!-- .element: class="fragment" --> First described in <em>"The Part-Time Parliament"</em> (1989) — set on a fictional <strong>Greek island</strong> where legislators came and went
- <!-- .element: class="fragment" --> <span class="accent-red">Rejected by reviewers for nearly a decade</span> — too unconventional
- <!-- .element: class="fragment" --> Lamport's response: write <em>"Paxos Made Simple"</em> (2001)

<div class="quote-block fragment">
"Paxos Made Simple: the title was a joke."
<span class="author">— Leslie Lamport</span>
</div>

</div>
<div style="flex: 0 0 220px; text-align: center;">
<img src="img/leslie-lamport.jpg" alt="Leslie Lamport" style="width: 220px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.15);">
<div style="font-size: 0.5em; color: #64748b; margin-top: 8px;">Leslie Lamport<br>Turing Award 2013</div>
</div>
</div>

The most influential consensus algorithm in history — <strong><span class="accent-purple">and the hardest to understand.</span></strong> <!-- .element: class="fragment" style="font-size: 0.8em; margin-top: 15px;" -->

Note:
The Paxos story is entertaining. Lamport wrote it as a story about Greek legislators. Reviewers didn't get it. For a decade. This sets up the next slide.

---

## Let Me Try to Explain <span class="accent-blue">Paxos</span> <span class="accent-red"> - feel the pain</span>

<div style="font-size: 0.72em; line-height: 1.5;">
<p>Three roles: <strong>Proposers</strong>, <strong>Acceptors</strong>, <strong>Learners</strong></p>
<ol>
<li class="fragment" data-fragment-index="1"><strong>Phase 1a</strong> — Proposer picks a number <code>n</code>, sends <code>Prepare(n)</code> to acceptors</li>
<li class="fragment" data-fragment-index="2"><strong>Phase 1b</strong> — Acceptors respond with a <code>Promise</code>: "I won't accept anything &lt; <code>n</code>" (+ any previously accepted value)</li>
<li class="fragment" data-fragment-index="3"><strong>Phase 2a</strong> — If majority promised, Proposer sends <code>Accept(n, value)</code> — <strong>must</strong> use the highest previously accepted value, or its own</li>
<li class="fragment" data-fragment-index="4"><strong>Phase 2b</strong> — Acceptors accept if they haven't promised a higher number</li>
<li class="fragment" data-fragment-index="5"><strong>Chosen</strong> — a value is chosen when a majority accept it</li>
</ol>
</div>


Note:
DELIVER THE PHASES FAST. The audience should feel overwhelmed on purpose — that's the whole point of this slide. Pause after the last phase and let the silence land before moving on.

---

## Let's Visualize the <span class="accent-blue">"Happy Path"</span>

Even without failures, look at the message complexity just to agree on one value! <!-- .element: class="subtitle" -->

<div style="width: 100%; height: 560px; border: 2px solid #ccc; border-radius: 8px; overflow: hidden; margin-top: 10px; background: #fff;">
  <iframe data-src="paxos-happy-animation.html" width="100%" height="100%" style="border: none;"></iframe>
</div>

Note:
This shows the literal happy path — the simplest possible sequence for Paxos to work. Notice the explosion of arrows when Acceptors broadcast to Learners. This illustrates WHY people struggled to build efficient, correct implementations of Paxos. Click through the 5 steps to show how convoluted even a clean run is.

---

## Paxos in Action: <span class="accent-red">Dueling Proposers</span>

What happens when there's no stable leader <!-- .element: class="subtitle" -->

<div style="width: 100%; height: 600px; border: 2px solid #ccc; border-radius: 8px; overflow: hidden; margin-top: 20px; background: #fff;">
  <iframe data-src="paxos-animation.html" width="100%" height="100%" style="border: none;"></iframe>
</div>

No stable leader → no progress → <strong><span class="accent-red">fundamental design flaw</span></strong> for real systems. <!-- .element: class="fragment" data-fragment-index="7" style="font-size: 0.85em; margin-top: 15px;" -->

"This is why nobody implements raw Paxos. This is why <strong><span class="accent-yellow">ZooKeeper</span></strong> exists." <!-- .element: class="fragment" data-fragment-index="8" style="font-size: 0.85em; color: #555;" -->

Note:
Animate step by step. Let them see the two proposers outbidding each other. The visual makes it visceral.

---

## Why Kafka Chose <span class="accent-yellow">ZooKeeper</span>

2010–2011 / LinkedIn <!-- .element: class="subtitle" -->

Jay Kreps, Neha Narkhede, and Jun Rao needed coordination for Kafka. <!-- .element: style="font-size: 0.8em; color: #333;" -->

<div class="card-grid" style="margin-top: 25px;">
<div class="card fragment">
<h4 class="accent-red strikethrough">Build from Paxos</h4>
<p>"You just saw how well that explanation went."</p>
</div>
<div class="card fragment" style="border-color: var(--accent-black); background: rgba(251,191,36,0.06);">
<h4 class="accent-yellow">✓ Use ZooKeeper</h4>
<p>Already at LinkedIn. Battle-tested. Apache project since 2008.</p>
</div>
</div>

<!-- .element: class="fragment" style="margin-top: 25px;" -->

ZooKeeper uses <strong><span class="accent-yellow">ZAB</span></strong> (ZooKeeper Atomic Broadcast) — Paxos-inspired, but with a <strong>stable leader</strong> and <strong>total ordering</strong>. <!-- .element: style="font-size: 0.8em;" -->

<div class="quote-block fragment" style="border-color: var(--accent-black);">
The pragmatic choice: don't reinvent consensus — delegate it to people who already suffered through Paxos.
</div>

Note:
The callback to "you just saw how well that went" gets a laugh. ZooKeeper was the right call in 2010.

---

## Visualizing <span class="accent-yellow">ZAB</span>: The Happy Path

How ZooKeeper sequences transactions to solve the Paxos problem. <!-- .element: class="subtitle" -->

<div style="width: 100%; height: 560px; border: 2px solid #ccc; border-radius: 8px; overflow: hidden; margin-top: 10px; background: #fff;">
  <iframe data-src="zab-animation.html" width="100%" height="100%" style="border: none;"></iframe>
</div>

Note:
Explain that ZAB guarantees FIFO delivery of proposals by a single stable leader, completely avoiding the dueling proposer issue. Shows the PROPOSE -> ACK -> COMMIT flow which is exactly what Raft copied later.

---

## What Is <span class="accent-yellow">ZooKeeper</span>?

Yahoo! Research, 2007 — Apache, 2008 <!-- .element: class="subtitle" -->

A centralized coordination service for distributed applications. <!-- .element: style="font-size: 0.78em; color: #333;" -->

<div class="card-grid three-col fragment">
<div class="card">
<h4>Znodes</h4>
<p>Hierarchical key-value store, like a filesystem</p>
</div>
<div class="card">
<h4>Ephemeral Nodes</h4>
<p>Auto-deleted when client session ends</p>
</div>
<div class="card">
<h4>Watches</h4>
<p>Notifications when data changes</p>
</div>
</div>

<div class="card-grid fragment">
<div class="card">
<h4>Sequential Nodes</h4>
<p>Auto-incrementing names for ordering</p>
</div>
<div class="card">
<h4>Versioned Writes</h4>
<p>Optimistic concurrency via version checks</p>
</div>
</div>

ZAB guarantees <strong><span class="accent-yellow">total order</span></strong> + <strong>stable leader</strong> — reliable and well-understood, unlike raw Paxos. <!-- .element: class="fragment" style="font-size: 0.75em; color: #555; margin-top: 20px;" -->

Note:
Quick overview. The audience likely knows ZooKeeper. The key point: ephemeral nodes are the magic that made ZK great for Kafka.

---

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

<div class="highlight-box fragment" style="margin-top: 20px;">
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

<!-- .slide: class="center-slide" data-background-color="#0f172a" -->

<div style="color: #f87171; font-size: 4.5em; font-weight: 900; line-height: 1; letter-spacing: -0.03em;">
MINUTES
</div>

<p style="color: #94a3b8; font-size: 0.9em; margin-top: 25px;">
Controller failover time at LinkedIn<br>
with <strong style="color: #ffffff;">~2 million partitions</strong>
</p>

<p class="fragment" style="color: #475569; font-size: 0.7em; margin-top: 35px;">
vs. <strong style="color: #4ade80; font-size: 1.4em;">1–3 seconds</strong> with KRaft
</p>

Note:
Let this slide breathe. No click-through. Just stare at it. The contrast is the argument.

---

## The Writing on the Wall

<div class="progress-line fragment"><span class="year">2015</span> Kafka 0.9: consumer groups <strong>moved out of ZK</strong> → <code>__consumer_offsets</code></div>
<div class="progress-line fragment"><span class="year">2017+</span> Kafka 2.x: admin operations stop requiring direct ZK access</div>
<div class="progress-line fragment" style="border: 1px solid var(--accent-blue);"><span class="year">2019</span> <strong>KIP-500</strong> — Colin McCabe proposes removing ZooKeeper entirely</div>

<div class="quote-block" style="margin-top: 25px; border-color: var(--accent-blue);">
"We should manage metadata the same way we manage data: with Apache Kafka itself."
<span class="author">— KIP-500</span>
</div>

<!-- .element: class="fragment" -->

The pattern was clear: Kafka was slowly <strong>absorbing ZooKeeper's responsibilities</strong> — and KIP-500 made it official. <!-- .element: class="fragment" style="font-size: 0.8em; margin-top: 15px; color: #333;" -->

Note:
🎤 Pause for audience questions here (2 min). "Before we move to Raft, any questions on the ZooKeeper story?"
