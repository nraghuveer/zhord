## Rough Roadmap

Phase 1: Basic Ring

Simple consistent hash ring with MD5/SHA-1
Node addition/removal
Key-to-node mapping
Basic concurrent reads (RWLock)

Phase 2: Virtual Nodes

Replica points per node (configurable)
Weighted node capacity
Better distribution metrics

Phase 3: Concurrency

Segment-based locking (like ConcurrentHashMap)
Lock-free reads with epoch-based reclamation
Compare-and-swap for node updates
