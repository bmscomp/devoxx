# Devoxx France 2026

## Kafka with KRaft in Production

All the files and directories in this folder are resources for the **Devoxx France 2026** talk:  
**"Kafka with KRaft in Production — Goodbye ZooKeeper, Hello Simplicity"**

---

### Abstract

Apache Kafka has officially removed its dependency on Apache ZooKeeper starting with version 4.0. KRaft (Kafka Raft) is now the only supported metadata management mode. But what does running KRaft in production actually look like?

This session covers the real-world experience of migrating and operating Kafka clusters with KRaft at scale. We will explore:

- **Architecture deep-dive** — How KRaft replaces ZooKeeper for metadata quorum management
- **Migration strategies** — Step-by-step approaches for moving existing clusters from ZooKeeper to KRaft
- **Production hardening** — Controller quorum sizing, performance tuning, and failure domain design
- **Day-2 operations** — Monitoring, alerting, rolling upgrades, and disaster recovery with KRaft
- **Lessons learned** — Real incidents, pitfalls, and best practices gathered from production deployments

### Target Audience

This talk is aimed at developers, SREs, and platform engineers who operate or plan to operate Apache Kafka in production environments. Familiarity with Kafka fundamentals is expected.

### Repository Structure

```
2026/
├── README.md            # This file
├── slides/              # Presentation slides
├── demo/                # Live demo scripts and configurations
│   ├── kraft-cluster/   # KRaft cluster deployment manifests
│   ├── migration/       # ZooKeeper-to-KRaft migration scripts
│   └── monitoring/      # Prometheus & Grafana dashboards
└── resources/           # Additional references and reading material
```

### Tech Stack

| Component          | Version / Tool         |
|--------------------|------------------------|
| Apache Kafka       | 4.x (KRaft-only)       |
| Deployment         | Kubernetes / Kind      |
| Monitoring         | Prometheus + Grafana   |
| Infrastructure     | Helm Charts            |

### Key References

- [KIP-500: Replace ZooKeeper with a Self-Managed Metadata Quorum](https://cwiki.apache.org/confluence/display/KAFKA/KIP-500)
- [Apache Kafka 4.0 Release Notes](https://kafka.apache.org/downloads)
- [KRaft Configuration Reference](https://kafka.apache.org/documentation/#kraft)
- [Devoxx France 2026](https://www.devoxx.fr/)

### Contributing

If you think you can contribute to this project, you are most welcome!  
Feel free to open an issue or submit a pull request.

### License

This project is provided for educational and conference purposes.
