<span class="tag tag-part">Part 7</span>

## Key Takeaways

1. <!-- .element: class="fragment" --> <strong>Kafka is a distributed system</strong> — consensus is fundamental to operating it
2. <!-- .element: class="fragment" --> <strong>Paxos laid the foundation</strong> — but its complexity drove the need for simpler protocols
3. <!-- .element: class="fragment" --> <strong>ZooKeeper served Kafka for 12 years</strong> — the right choice at the right time
4. <!-- .element: class="fragment" --> <strong>Raft made consensus accessible</strong> — and KRaft brought it inside Kafka
5. <!-- .element: class="fragment" --> <strong>KRaft dramatically simplifies operations</strong> — one system, one team
6. <!-- .element: class="fragment" --> <strong>KRaft has its own challenges</strong> — static quorum, monitoring, tooling maturity
7. <!-- .element: class="fragment" --> <strong>The migration is a one-way door</strong> — test thoroughly, plan carefully

Note:
One takeaway per part. Each reinforces the story arc. Let each one land.

---

## Resources

- [KIP-500: Replace ZooKeeper with a Self-Managed Metadata Quorum](https://cwiki.apache.org/confluence/display/KAFKA/KIP-500)
- [KIP-853: Dynamic KRaft Quorum Reconfiguration](https://cwiki.apache.org/confluence/display/KAFKA/KIP-853)
- [In Search of an Understandable Consensus Algorithm (Raft paper)](https://raft.github.io/raft.pdf)
- [The Part-Time Parliament (Paxos paper)](https://lamport.azurewebsites.net/pubs/lamport-paxos.pdf)
- [Apache Kafka Documentation — KRaft](https://kafka.apache.org/documentation/#kraft)

<div style="margin-top: 30px; padding: 15px 20px; background: rgba(255,255,255,0.03); border-radius: 8px;">

Slides & demo code: <!-- .element: style="font-size: 0.8em; margin: 0;" -->

<strong>github.com/bmscomp/devoxx/2026</strong> <!-- .element: style="font-size: 0.9em; margin: 5px 0 0 0;" -->

</div>

Note:
These links are in the repo README too. The audience can find everything there.

---

<!-- .slide: class="center-slide" data-background-color="#0b1929" -->

<h1 style="color: #ffffff;">Thank You!</h1>

<p style="font-size: 0.9em; color: #c9d6e3; margin-top: 20px;">Questions?</p>

<div style="margin-top: 50px; font-size: 0.7em; color: #7a8fa6;">

<span style="color: #5b9cf5;">@bmscomp</span>

<a href="https://github.com/bmscomp/devoxx/2026" style="color: #5b9cf5; text-decoration: none;">github.com/bmscomp/devoxx/2026</a>

</div>

Note:
Open floor for Q&A. Deep dive audiences have great questions — engage fully.
