hauntstack
=====

"A haunted network simulator"

This is a learning project to implement Layer 2-4 of the [Open Systems
Interconnection (OSI)][osi] model via haunted hardware. A haunted piece of
hardware is unpredictable and may fail in many ways. My understanding is that
these layers are supposed to be robust even in these conditions.

# Parts

1. Two Network Interface Cards (NIC) connected via a perfect wire
    - Topology is driven by a behavior (attach, detach, and deliver)
        - `attach(Endpoint :: pid(), Wire :: pid())`
        - `detach(Endpoint :: pid())`
        - `deliver(Endpoint :: pid(), Frame :: binary()` 
    - Topology connections happen via `topology.erl`
        - `connect({Mod, Endpoint}, Wire())` which calls the behavior `attach`
        - `disconnect(Wire())`
    - A wire is composed of two unidirectional "channels"
    - Channels are responsible for sending data
        - Wire owns the channels, behavior dictates how the endpoint stores state
    - A wire has a `left_to_right` and `right_to_left` channel
        - Each of these are `{Mod, Pid}`, i.e. `{server_nic, NicPid}`
        - The wire is central for managing the endpoint's callbacks
    - A NIC connects to one channel of a wire
    - A NIC is identified by a MAC Address i.e. 6 bytes
    - Channels, wires, and NICs are simple_one_for_one
        - No names needed, identified only by Pid is fine
        - Pids are basically used to build topology and send frames
    - Ethernet II frames sent via binary encoding, gen_server only ever expects
      to recieve casts on binary data

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
