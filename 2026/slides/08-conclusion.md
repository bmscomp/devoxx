<!-- .slide: class="center-slide section-divider" data-background-color="#0f172a" -->

<div style="font-size: 3.5em; margin-bottom: 10px;">🎯</div>

## <span style="color: #e2e8f0;">Wrapping Up</span>

7 parts, 1 story — from theory to production <!-- .element: style="color: #94a3b8; font-size: 0.75em;" -->

Note:
Section divider. Take a breath. We've covered a lot — let's tie it together.

---

<!-- .slide: data-background-color="#0f172a" -->

## <span style="color: #e2e8f0;">Key Takeaways</span> <!-- .element: style="text-align: center;" -->

<div style="text-align: left; max-width: 850px; margin: 25px auto 0;">
<div class="progress-line fragment" style="border-left-color: #ea580c; background: rgba(234, 88, 12, 0.08);">
  <span class="year" style="background: #ea580c;">1</span>
  <span style="color: #e2e8f0;"><strong>Kafka is a distributed system</strong> — consensus is fundamental</span>
</div>
<div class="progress-line fragment" style="border-left-color: #7c3aed; background: rgba(124, 58, 237, 0.08);">
  <span class="year" style="background: #7c3aed;">2</span>
  <span style="color: #e2e8f0;"><strong>Paxos laid the foundation</strong> — but complexity drove need for simpler protocols</span>
</div>
<div class="progress-line fragment" style="border-left-color: #0891b2; background: rgba(8, 145, 178, 0.08);">
  <span class="year" style="background: #0891b2;">3</span>
  <span style="color: #e2e8f0;"><strong>Raft made consensus accessible</strong> — and KRaft brought it inside Kafka</span>
</div>
<div class="progress-line fragment" style="border-left-color: #16a34a; background: rgba(22, 163, 74, 0.08);">
  <span class="year" style="background: #16a34a;">4</span>
  <span style="color: #e2e8f0;"><strong>KRaft simplifies operations</strong> — one system, one team, one set of runbooks</span>
</div>
<div class="progress-line fragment" style="border-left-color: #2563eb; background: rgba(37, 99, 235, 0.08);">
  <span class="year" style="background: #2563eb;">5</span>
  <span style="color: #e2e8f0;"><strong>The demo proved it works</strong> — migration is real and achievable</span>
</div>
<div class="progress-line fragment" style="border-left-color: #dc2626; background: rgba(220, 38, 38, 0.08);">
  <span class="year" style="background: #dc2626;">6</span>
  <span style="color: #e2e8f0;"><strong>KRaft has its own challenges</strong> — static quorum, monitoring, tooling maturity</span>
</div>
<div class="progress-line fragment" style="border-left-color: #ca8a04; background: rgba(202, 138, 4, 0.08);">
  <span class="year" style="background: #ca8a04;">7</span>
  <span style="color: #e2e8f0;"><strong>The migration is a one-way door</strong> — test thoroughly, plan carefully</span>
</div>
</div>

Note:
Each color matches the section it references. This visual callback reinforces the journey we just took together.

---

## Your <span class="accent-green">Action Plan</span>

<div class="card-grid three-col" style="margin-top: 25px;">
<div class="card card-warning" style="border-top: 3px solid var(--accent-yellow);">
<h4 class="accent-orange">📋 This Week</h4>
<ul>
<li>Check your current Kafka version</li>
<li>Read <a href="https://cwiki.apache.org/confluence/display/KAFKA/KIP-500">KIP-500</a></li>
<li>Inventory your ZK dependencies</li>
<li>Identify tools that talk directly to ZK</li>
</ul>
</div>
<div class="card" style="border-top: 3px solid var(--accent-blue);">
<h4 class="accent-blue">🔬 This Quarter</h4>
<ul>
<li>Set up a KRaft test cluster</li>
<li>Run the migration in staging</li>
<li>Update monitoring dashboards</li>
<li>Train your team on KRaft ops</li>
</ul>
</div>
<div class="card card-success" style="border-top: 3px solid var(--accent-green);">
<h4 class="accent-green">🚀 This Year</h4>
<ul>
<li>Execute production migration</li>
<li>Validate with bridge mode (weeks)</li>
<li>Finalize and decommission ZK</li>
<li>Welcome to the KRaft era 🎉</li>
</ul>
</div>
</div>

Note:
Give the audience something actionable. Most conference talks end with theory. End with a checklist they can start Monday.

---

## Resources

- [KIP-500: Replace ZooKeeper with a Self-Managed Metadata Quorum](https://cwiki.apache.org/confluence/display/KAFKA/KIP-500)
- [KIP-853: Dynamic KRaft Quorum Reconfiguration](https://cwiki.apache.org/confluence/display/KAFKA/KIP-853)
- [In Search of an Understandable Consensus Algorithm (Raft paper)](https://raft.github.io/raft.pdf)
- [The Part-Time Parliament (Paxos paper)](https://lamport.azurewebsites.net/pubs/lamport-paxos.pdf)
- [Apache Kafka Documentation — KRaft](https://kafka.apache.org/documentation/#kraft)

<div class="highlight-box" style="margin-top: 25px; text-align: center;">
<p style="font-size: 0.8em; margin: 0;">📂 Slides, demo code & Makefile:</p>
<p style="font-size: 1em; margin: 8px 0 0 0;"><strong><a href="https://github.com/bmscomp/devoxx/2026" style="color: var(--accent-blue);">github.com/bmscomp/devoxx/2026</a></strong></p>
</div>

Note:
These links are in the repo README too. The audience can find everything there.

---

<!-- .slide: class="center-slide" data-background-color="#0b1929" -->

<h1 style="color: #ffffff; font-size: 2.5em;">Thank You!</h1>

<p style="font-size: 1em; color: #c9d6e3; margin-top: 20px;">Questions?</p>

<div style="margin-top: 40px; display: flex; align-items: center; justify-content: center; gap: 40px;">
<div style="text-align: center;">
<img src="img/qrcode-repo.png" alt="QR Code" style="width: 140px; height: 140px; border-radius: 8px; background: #fff; padding: 8px;" onerror="this.style.display='none'">
</div>
<div style="text-align: left; font-size: 0.75em; color: #7a8fa6;">
<p style="margin: 0;"><span style="color: #5b9cf5; font-weight: 700;">@bmscomp</span></p>
<p style="margin: 8px 0 0 0;"><a href="https://github.com/bmscomp/devoxx/2026" style="color: #5b9cf5; text-decoration: none;">github.com/bmscomp/devoxx/2026</a></p>
<p style="margin: 12px 0 0 0; color: #475569; font-size: 0.9em;">Devoxx France 2026 — Deep Dive (2h)</p>
</div>
</div>

Note:
Open floor for Q&A. Deep dive audiences have great questions — engage fully.
