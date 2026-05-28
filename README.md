hauntstack
=====

"A haunted network simulator"

This is a learning project to implement Layer 2-4 of the [Open Systems
Interconnection (OSI)][osi] model via haunted hardware. A haunted piece of
hardware is unpredictable and may fail in many ways. My understanding is that
these layers are supposed to be robust even in these conditions.

# Parts

- [x] Two network interface cards (NICs) connected via a perfect wire
- [ ] Multi-port switch with learning and flooding
- [ ] IPv4
- [ ] ARP
- [ ] UDP
- [ ] TCP

# Later

- Topology DSL, define endpoints with names/options and wires which connect endpoints
- MAC registry service, start with globally unique MAC addresses
- Tap is an endpoint which simply records what it received
- Set up OTEL tracing for packets and metrics for components

# Haunting ideas

- Wires
    - Latency (via event based clock)
    - Loss
    - Corruption
    - Re-ordering (needs a buffer to support this)
    - Bandwidth (via event based clock)
- NIC
    - MAC address change
    - MAC address overlap (via MAC registry)

# Potential inspiration

- Simulate bad network connections with [comcast][comcast]
- Chaos engineering for Kubernetes with [Chaos Mesh][chaos-mesh] 

[comcast]: https://github.com/tylertreat/comcast
[chaos-mesh]: https://github.com/chaos-mesh/chaos-mesh
[osi]: https://en.wikipedia.org/wiki/OSI_model
