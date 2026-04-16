<span class="tag tag-part">Part 4</span>

## <span class="accent-cyan">Raft</span>: The Consensus Revolution

2014 / Diego Ongaro &amp; John Ousterhout — Stanford <!-- .element: class="subtitle" -->

- <!-- .element: class="fragment" --> *"In Search of an <strong>Understandable</strong> Consensus Algorithm"*
- <!-- .element: class="fragment" --> Thesis: <strong><span class="accent-purple">Paxos is correct but incomprehensible</span></strong>
  - User study: 43 students learned both → Raft scores <strong>significantly better</strong>
- <!-- .element: class="fragment" --> Design principle: *"If you can't understand the protocol, you can't implement it correctly, debug it, or operate it"*
- <!-- .element: class="fragment" --> Same safety guarantees as Multi-Paxos
- <!-- .element: class="fragment" --> Key insight: decompose consensus into <strong><span class="accent-cyan">three independent subproblems</span></strong>

Note:
Raft's whole reason for existing is understandability. The user study is compelling — same guarantees, but people actually understand it.

---

## Raft Subproblem 1: <span class="accent-cyan">Leader Election</span>

<div class="diagram-box" style="text-align: center; font-size: 0.6em;">
┌──────────┐  election timeout  ┌───────────┐  majority vote  ┌────────┐
│ <span class="accent-blue">Follower</span> │ ─────────────────► │ <span class="accent-yellow">Candidate</span> │ ──────────────► │ <span class="accent-green">Leader</span> │
└──────────┘                    └───────────┘                 └────────┘
     ▲                               │ │                          │
     │        discovers higher term  │ │   discovers higher term  │
     └───────────────────────────────┘ └──────────────────────────┘
</div>

- <!-- .element: class="fragment" --> <strong>Terms</strong>: monotonically increasing epoch number — logical clock
- <!-- .element: class="fragment" --> Follower's election timer expires (randomized: `150–300ms`) → becomes <strong><span class="accent-yellow">Candidate</span></strong>
- <!-- .element: class="fragment" --> Candidate votes for itself, sends `RequestVote(term, lastLogIndex, lastLogTerm)`
- <!-- .element: class="fragment" --> Peer grants vote if: term ≥ own <strong>AND</strong> candidate's log is at least as up-to-date
- <!-- .element: class="fragment" --> Majority → becomes <strong><span class="accent-green">Leader</span></strong>, starts heartbeats
- <!-- .element: class="fragment" --> <strong><span class="accent-cyan">Random timeout</span></strong> prevents split-vote livelocks — contrast with Paxos dueling proposers!

Note:
Draw the contrast with Paxos explicitly. The random timeout is elegant — it solves the dueling proposers problem they just saw.

---

## Raft Subproblem 2: <span class="accent-cyan">Log Replication</span>

The heart of Raft — and the heart of KRaft <!-- .element: class="subtitle" -->

<div class="diagram-box" style="font-size: 0.6em;">
┌───────┬───────┬──────────────────┐
│ Index │ Term  │     Command      │
├───────┼───────┼──────────────────┤
│   1   │   1   │ SET x = 5        │
│   2   │   1   │ SET y = 10       │
│   3   │   2   │ SET x = 7        │  ← <span class="accent-green">committed</span> (majority)
│   4   │   3   │ DELETE z         │  ← <span class="accent-yellow">replicated, not yet committed</span>
└───────┴───────┴──────────────────┘
</div>

1. <!-- .element: class="fragment" --> Client sends command to <strong><span class="accent-green">Leader</span></strong>
2. <!-- .element: class="fragment" --> Leader appends to its local log
3. <!-- .element: class="fragment" --> Leader sends `AppendEntries(term, prevLogIndex, prevLogTerm, entries[], commitIndex)` to followers
4. <!-- .element: class="fragment" --> Follower checks: does my log match at `prevLogIndex/prevLogTerm`?
   - <span class="accent-green">Yes</span> → append, respond success
   - <span class="accent-red">No</span> → reject → leader decrements `nextIndex`, retries
5. <!-- .element: class="fragment" --> Majority replicated → leader advances `commitIndex`

Note:
Go slow here. The log structure is EXACTLY what KRaft uses for __cluster_metadata. They need to internalize this.

---

## Log Reconciliation After <span class="accent-red">Failure</span>

What happens when a leader crashes mid-replication? <!-- .element: class="subtitle" -->

<div class="diagram-box" style="font-size: 0.58em;">
Node A <span class="accent-red">(old leader, crashed)</span>:  [1:1] [2:1] [3:2] [4:2]
Node B <span class="accent-green">(new leader)</span>:           [1:1] [2:1] [3:2]
Node C (follower):             [1:1] [2:1] [3:2]
Node D (follower):             [1:1] [2:1]
Node E (follower):             [1:1] [2:1] [3:2]
</div>

- <!-- .element: class="fragment" --> Entry `[4:2]` was <strong>not committed</strong> (only on Node A) → can be safely overwritten
- <!-- .element: class="fragment" --> New leader (B) sends `AppendEntries` to Node D:
  - `prevLogIndex=2, prevLogTerm=1` → matches → appends `[3:2]` → logs converge
- <!-- .element: class="fragment" --> <strong><span class="accent-green">Safety guarantee</span></strong>: a committed entry (majority-replicated) can <strong>never</strong> be lost

This log reconciliation is <strong>exactly</strong> what KRaft does for Kafka metadata. <!-- .element: class="fragment" style="font-size: 0.8em; margin-top: 15px; color: #555;" -->

Note:
Make the connection to KRaft explicit. This same mechanism handles metadata recovery in Kafka now.

---

## Raft in Action: <span class="accent-cyan">Live Animation</span>

Visualizing leader election, log replication, and log reconciliation. <!-- .element: class="subtitle" -->

<div style="width: 100%; height: 550px; border: 2px solid #ccc; border-radius: 8px; overflow: hidden; margin-top: 20px; background: #fff;">
  <iframe data-src="raft-animation.html" width="100%" height="100%" style="border: none;"></iframe>
</div>

Note:
Use this interactive animation to walk the audience through the exact steps discussed. Click through the 14 steps to demonstrate a standard election, normal log replication, and the "slow node" partition/crash-recovery scenario.

---

## Raft: <span class="accent-cyan">Safety</span> Properties

<div class="card-grid three-col" style="margin-top: 25px;">
<div class="card fragment">
<h4 class="accent-cyan">Election Restriction</h4>
<p>Candidate's log must be at least as up-to-date as any majority member</p>
</div>
<div class="card fragment">
<h4 class="accent-cyan">Leader Completeness</h4>
<p>If an entry is committed in term T, it appears in all leaders for terms &gt; T</p>
</div>
<div class="card fragment">
<h4 class="accent-cyan">State Machine Safety</h4>
<p>If a node applies entry at index I, no other node applies a different entry at I</p>
</div>
</div>

<!-- .element: class="fragment" -->

<div class="highlight-box" style="margin-top: 25px; text-align: center;">
<p style="font-size: 0.9em; margin: 0;">Once Raft commits a value, it <strong>stays committed forever</strong>.</p>
</div>

Note:
These guarantees are what make KRaft safe for Kafka metadata. When a topic record is committed, it won't vanish.

---

## <span class="accent-purple">Paxos</span> vs <span class="accent-cyan">Raft</span>

| Aspect | <span class="accent-purple">Paxos</span> | <span class="accent-cyan">Raft</span> |
|--------|-------|------|
| <strong>Year</strong> | 1989 / 1998 | 2014 |
| <strong>Design goal</strong> | Correctness proof | Understandability |
| <strong>Leader</strong> | Optional, weak | Mandatory, strong |
| <strong>Agreement unit</strong> | Single value | Ordered log entries |
| <strong>Steady state</strong> | 2 RTT (Prepare + Accept) | 1 RTT (AppendEntries) |
| <strong>Log ordering</strong> | Unspecified | Strictly sequential |
| <strong>Membership</strong> | Underspecified | Joint consensus |
| <strong>Failure mode</strong> | Dueling proposers → livelock | Random timeout → fast re-election |
| <strong>Implementations</strong> | Chubby, Spanner | etcd, CockroachDB, <strong><span class="accent-green">KRaft</span></strong> |

<span class="accent-purple">Paxos</span> *(theory)* → <span class="accent-yellow">ZAB</span> *(ZooKeeper)* → <span class="accent-cyan">Raft</span> *(simplicity)* → <span class="accent-green">KRaft</span> *(Kafka-native)* <!-- .element: class="fragment" style="font-size: 0.75em; text-align: center; margin-top: 15px; color: #555;" -->

Note:
This is a "photograph this slide" moment. The evolution line at the bottom ties the whole story together.
