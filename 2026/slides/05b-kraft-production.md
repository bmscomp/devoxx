<span class="tag tag-part">Part 5b</span>

## <span class="accent-green">KRaft</span> in Production

Key requirements for a stable deployment <!-- .element: class="subtitle" -->

<div class="card-grid" style="margin-top: 20px;">
<div class="card fragment">
<h4 class="accent-green">Dedicated Controllers</h4>
<p>Deploy 3 (or 5) <strong>dedicated</strong> controllers. Do not use combined mode for production.</p>
</div>
<div class="card fragment">
<h4 class="accent-green">Fast Storage (SSD/NVMe)</h4>
<p>Controllers persist the <code>__cluster_metadata</code> log. Fast I/O prevents Raft election timeouts.</p>
</div>
<div class="card fragment">
<h4 class="accent-green">Network Prioritization</h4>
<p>Controller quorum traffic should utilize a low-latency network backbone to maintain stability.</p>
</div>
<div class="card fragment">
<h4 class="accent-green">Key Metrics</h4>
<p>Alert on <code>ActiveControllerCount</code>, <code>MetadataErrorCount</code>, and <code>CurrentState</code> to detect split-brain or election storms.</p>
</div>
</div>

<strong>Production Tip:</strong> Formatting the storage directory (<code>kafka-storage.sh format</code>) is a hard requisite before starting any node! <!-- .element: class="fragment" style="font-size: 0.75em; margin-top: 20px; color: #555;" -->

Note:
When running KRaft, treat the controllers with the same respect you gave ZK nodes. Fast disks are non-negotiable!
