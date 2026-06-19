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

Demo 1: make start → make controllers → make bridge → make verify-bridge → make kraft → make upgrade
Demo 2: make metadata-shell → make check-controllers-metadata
Demo 3: make controller-failover → make quorum-status
Demo 4: make scale-partitions → make watch → make restart-brokers
