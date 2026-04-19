<!-- .slide: class="center-slide title-slide" data-background-color="#0b1929" -->

<h1 style="color: #ffffff; font-size: 2.3em; line-height: 1; display: flex; align-items: flex-end; justify-content: center; gap: 16px; margin-bottom: 0; font-weight: 700; text-transform: lowercase;"><img src="img/kafka-logo.png" alt="Kafka" style="height: 5em; filter: invert(1) brightness(2); margin-bottom: -0.4em;">with <span style="color: #5b9cf5;">KRaft</span> in production</h1>

<p style="font-size: 0.85em; color: #c9d6e3; margin-top: 15px;">
 — <b>A New Era for Distributed Commit Logs </b>
</p>

<div style="margin-top: 50px; font-size: 0.6em; color: #7a8fa6;">

<b>Devoxx France </b> 2026 — Deep Dive (2h)

<span style="color: #5b9cf5;">By <b>Said BOUDJELDA</b></span>

</div>

Note:
Welcome everyone. This is a 2-hour deep dive into how Kafka manages its own metadata now — and why it took 12 years to get here.

---

## What is a <span class="accent-blue">Distributed System</span>?

- <!-- .element: class="fragment" --> A collection of <strong>independent nodes</strong> that communicate over a network
- <!-- .element: class="fragment" --> They <strong>coordinate</strong> to appear as a single coherent system to the outside world
- <!-- .element: class="fragment" --> Each node has its own <strong>local state</strong> — no shared memory, no shared clock

<!-- .element: class="fragment" -->

<div class="card-grid three-col" style="margin-top: 15px;">
<div class="card">
<h4>Network</h4>
<p>The only way nodes can communicate — and it can fail</p>
</div>
<div class="card">
<h4>Concurrency</h4>
<p>Multiple nodes act simultaneously without global synchronization</p>
</div>
<div class="card">
<h4>Partial failure</h4>
<p>Some nodes crash while others continue — the system must cope</p>
</div>
</div>

Examples: Kafka, Cassandra, etcd, Kubernetes, any microservices architecture <!-- .element: class="fragment" style="font-size: 0.75em; margin-top: 15px; color: #333;" -->

Note:
Start with the basics. Make sure everyone has the same mental model before diving into coordination challenges.

---

## Challenges of <span class="accent-blue">Distributed Systems</span>

- <!-- .element: class="fragment" --> <strong>Consensus</strong> — how do N nodes agree on a single value when some may fail?
- <!-- .element: class="fragment" --> <strong>Failure detection</strong> — is that node dead, or just slow?
- <!-- .element: class="fragment" --> <strong>Split brain</strong> — two nodes both think they are the leader
- <!-- .element: class="fragment" --> <strong>Ordering</strong> — events happen concurrently, but we need a total order
- <!-- .element: class="fragment" --> <strong>Consistency vs. Availability</strong> — the CAP theorem forces a trade-off

<!-- .element: class="fragment" -->

<div class="quote-block">
"A distributed system is one in which the failure of a computer you didn't even know existed can render your own computer unusable."
<span class="author">— Leslie Lamport</span>
</div>

These are the problems every distributed system must solve — and Kafka is no exception. <!-- .element: class="fragment" style="font-size: 0.8em; margin-top: 15px; color: #333;" -->

Note:
Set the stage. The audience needs to feel the weight of these challenges before we show how Kafka addresses them.

---

<!-- .slide: data-auto-animate -->

<span class="tag tag-part">Part 1</span>

## Kafka Is a <span class="accent-orange">Distributed System</span>

- <!-- .element: class="fragment" --> Multiple <strong>brokers</strong>, each holding a subset of <strong>partitions</strong>
- <!-- .element: class="fragment" --> Partitions are <strong>replicated</strong> across brokers for fault tolerance
- <!-- .element: class="fragment" --> One replica is the <strong><span class="accent-orange">Leader</span></strong>, others are <strong>Followers</strong> (ISR)

<!-- .element: class="fragment" -->

<div class="card-grid three-col" style="margin-top: 10px;">
<div class="card">
<h4>No shared clock</h4>
<p>Each broker has its own notion of time</p>
</div>
<div class="card">
<h4>No shared memory</h4>
<p>Brokers communicate only through the network</p>
</div>
<div class="card">
<h4>Partial failures</h4>
<p>A broker can die while others continue</p>
</div>
</div>

Note:
The audience knows Kafka. Don't dwell on basics. Frame it as a distributed system to set up the coordination problem.

---

## The <span class="accent-blue">Coordination</span> Questions

- <!-- .element: class="fragment" --> Who decides which broker <strong>leads</strong> which partition?
- <!-- .element: class="fragment" --> Who <strong>detects</strong> that a broker has died?
- <!-- .element: class="fragment" --> Who <strong>reassigns</strong> partitions after a failure?
- <!-- .element: class="fragment" --> Where is the cluster <strong>metadata</strong> stored?
- <!-- .element: class="fragment" --> Who ensures there's exactly <strong><span class="accent-orange">one controller</span></strong> at a time?

These are all <strong><span class="accent-blue">consensus problems</span></strong> — and consensus is fundamentally hard. <!-- .element: class="fragment" style="font-size: 0.8em; margin-top: 20px;" -->

Note:
Let each question land. The audience should feel the weight of these decisions. Then transition: "This talk is the story of how Kafka solved these questions — and how the answer changed."
