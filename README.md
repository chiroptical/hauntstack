hauntstack
=====

"A haunted network simulator"

This is a learning project to implement Layer 2-4 of the [Open Systems
Interconnection (OSI)][osi] model via haunted hardware. A haunted piece of
hardware is unpredictable and may fail in many ways. My understanding is that
these layers are supposed to be robust even in these conditions.

# Parts

1. Two Network Interface Cards (NIC) connected via a perfect wire
    - A wire has a `left` and `right` side
    - A wire is a process with a Pid
    - A NIC connects to one side of a wire, i.e `nic:connect(WirePid)`
        - NIC stores WirePid
        - Wire stores MAC
    - A NIC is identified by a MAC Address i.e. 6 bytes
    - Both a wire and a NIC are simple_one_for_one
        - Neither need names, identified only by Pid is fine
        - Pids are basically used to build topology and send frames
    - Ethernet II frames sent via binary encoding, gen_server only ever expects
      to recieve casts on binary data

# Later

- MAC registry service, start with globally unique MAC addresses

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

[osi]: https://en.wikipedia.org/wiki/OSI_model
