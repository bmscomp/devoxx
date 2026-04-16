<span class="tag tag-part">Part 2</span>

## The <span class="accent-purple">Consensus</span> Problem

Getting N nodes to agree on a single value, even if some nodes fail. <!-- .element: style="font-size: 0.85em; color: #333;" -->

<!-- .element: class="fragment" -->

<div class="card-grid three-col">
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

<!-- .element: class="fragment" -->

<div class="highlight-box" style="margin-top: 25px;">
<p style="font-size: 0.75em; margin: 0;"><strong class="accent-red">FLP Impossibility (1985)</strong> — Consensus is <em>impossible</em> in a fully asynchronous system with even one faulty process.</p>
<p style="font-size: 0.7em; margin: 8px 0 0 0; color: #555;">Real systems work around this with <strong>timeouts</strong> and <strong>failure detectors</strong>.</p>
</div>

Note:
Set the theoretical foundation. FLP is important because it explains why every consensus protocol uses timeouts — there's no perfect solution.

---

<!-- .slide: data-background-gradient="radial-gradient(circle at 50% 50%, rgba(168,85,247,0.08) 0%, transparent 60%)" -->

## <span class="accent-purple">Paxos</span> — Where It All Began

1989 / Leslie Lamport <!-- .element: class="subtitle" -->

- <!-- .element: class="fragment" --> Invented by <strong>Leslie Lamport</strong> — also created LaTeX & defined distributed systems
- <!-- .element: class="fragment" --> First described in *"The Part-Time Parliament"* (1989) — set on a fictional <strong>Greek island</strong> where legislators came and went
- <!-- .element: class="fragment" --> <span class="accent-red">Rejected by reviewers for nearly a decade</span> — too unconventional
- <!-- .element: class="fragment" --> Lamport's response: write *"Paxos Made Simple"* (2001)

<!-- .element: class="fragment" -->

<div class="quote-block">
"Paxos Made Simple: the title was a joke."
<span class="author">— Leslie Lamport</span>
</div>

The most influential consensus algorithm in history — <strong><span class="accent-purple">and the hardest to understand.</span></strong> <!-- .element: class="fragment" style="font-size: 0.8em; margin-top: 15px;" -->

Note:
The Paxos story is entertaining. Lamport wrote it as a story about Greek legislators. Reviewers didn't get it. For a decade. This sets up the next slide.

---

## Let Me Try to Explain <span class="accent-blue">Paxos</span> <span class="accent-red"> - feel the pain</span>


<!-- .element: class="fragment" data-fragment-index="1" -->

<div style="font-size: 0.72em; line-height: 1.5;">

Three roles: <strong>Proposers</strong>, <strong>Acceptors</strong>, <strong>Learners</strong>

1. <!-- .element: class="fragment" data-fragment-index="1" --> <strong>Phase 1a</strong> — Proposer picks a number <code>n</code>, sends <code>Prepare(n)</code> to acceptors
2. <!-- .element: class="fragment" data-fragment-index="1" --> <strong>Phase 1b</strong> — Acceptors respond with a <code>Promise</code>: "I won't accept anything &lt; <code>n</code>" (+ any previously accepted value)
3. <!-- .element: class="fragment" data-fragment-index="1" --> <strong>Phase 2a</strong> — If majority promised, Proposer sends <code>Accept(n, value)</code> — <strong>must</strong> use the highest previously accepted value, or its own
4. <!-- .element: class="fragment" data-fragment-index="1" --> <strong>Phase 2b</strong> — Acceptors accept if they haven't promised a higher number
5. <!-- .element: class="fragment" data-fragment-index="1" --> <strong>Chosen</strong> — a value is chosen when a majority accept it

</div>

Did you follow all of that? <!-- .element: class="fragment" data-fragment-index="2" style="font-size: 1.3em; font-weight: 700; text-align: center; margin: 30px 0;" -->

Neither did the reviewers. <strong><span class="accent-blue">For ten years.</span></strong> <!-- .element: class="fragment" data-fragment-index="3" style="font-size: 1.1em; text-align: center; color: #555;" -->

<!-- .element: class="fragment" data-fragment-index="4" -->

<div style="font-size: 0.72em; color: #444;">

- And this agrees on <strong>a single value</strong> — real systems need a <strong>sequence</strong>
- Multi-Paxos extends it, but Lamport left it <strong><span class="accent-red">underspecified</span></strong>
- No leader election, no log gaps, no membership changes
- Every implementation is different: Google Chubby ≠ Spanner ≠ Amazon

</div>

Note:
DELIVER THIS FAST. The audience should feel overwhelmed. Pause after "Did you follow?" — let the silence land. They laugh because they relate.

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

<!-- .element: class="fragment" -->

<div class="quote-block" style="border-color: var(--accent-black);">
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

<!-- .element: class="fragment" -->

<div class="card-grid three-col">
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

<!-- .element: class="fragment" -->

<div class="card-grid">
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
