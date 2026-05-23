hauntstack
=====

"A haunted network simulator"

This is a learning project to implement Layer 2-4 of the [Open Systems
Interconnection (OSI)][osi] model via haunted hardware. A haunted piece of
hardware is unpredictable and may fail in many ways. My understanding is that
these layers are supposed to be robust even in these conditions.

# Parts

1. Two Network Interface Cards (NIC) connected via a perfect wire

# Later

- MAC registry service, start with globally unique MAC addresses
- Set up OTEL tracing for packets and metrics for components
- Tap is an endpoint which simply records what it recieved
- Switches are `#{PortNumber :: integer() => Port :: pid()}`, Port is similar to
  NIC but without a MAC address.
- Topology DSL, define endpoints with names/options and wires which connect endpoints

# Haunting ideas

- Wires
    - Latency (via event based clock)
    - Loss
    - Corruption
    - Re-ordering (needs a buffer to support this)
    - Bandwidth (via event based clock)
- NIC
    - MAC address change
    - MAC address overlap

# Potential inspiration

- Simulate bad network connections with [comcast][comcast]
- Chaos engineering for Kubernetes with [Chaos Mesh][chaos-mesh] 

[comcast]: https://github.com/tylertreat/comcast
[chaos-mesh]: https://github.com/chaos-mesh/chaos-mesh
[osi]: https://en.wikipedia.org/wiki/OSI_model
