hauntstack
=====

![NixCI Badge](https://nix-ci.com/badge/gh:chiroptical:hauntstack)

"A haunted network simulator"

This is a learning project to implement Layer 2-4 of the [Open Systems
Interconnection (OSI)][osi] model via haunted hardware. A haunted piece of
hardware is unpredictable and may fail in many ways. My understanding is that
these layers are supposed to be robust even in these conditions.

# Parts

- [x] Two network interface cards (NICs) connected via a perfect wire
- [x] Multi-port switch with learning and flooding
- [ ] IPv4
    - [x] Basic codec
    - [ ] Fragmentation of packets
- [ ] ARP
    - [ ] Codec
    - [ ] Fix ethernet.erl to stop using `~"2048"` and use integers (similar to IPv4)
    - [ ] ARP is embedded directly into an ethernet frame padded to 46 bytes
        - decode needs to trim based on TotalLength
- [ ] ICMP
    - [ ] Codec
        - Type - 8 bits
        - Code - 8 bits
        - Checksum - 16 bits, same checksum as IPv4 packet
        - Rest of Header - 32 bits
        - Messages - https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol#Control_messages 
            - Start with echo request/reply
- [ ] Add host gen_server which owns a NIC
    - [ ] Test an ARP request/reply between two hosts
    - [ ] Test an ICMP echo request/reply between two hosts
- [ ] Add router network endpoint
    - [ ] ipv4:encode/decode extended to deal with TTL properly
- [ ] UDP
- [ ] TCP

# Later

- Larger MTUs (Maximum Transmission Unit)
    - max is currently 1500 bytes in ethernet.erl
- Topology DSL, define endpoints with names/options and wires which connect endpoints
- MAC registry service, start with globally unique MAC addresses
- TAP is a network endpoint which records ethernet frames
- TUN is a network endpoint which records IP packets
- Set up OTEL tracing for packets and metrics for components
- Support for special addresses (e.g. 127.0.0.0/8)

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

# Local Development

## Re-run `nix flake check`

```shell
# Get current system value
$ nix eval --impure --raw --expr 'builtins.currentSystem'
# Get nix store paths we would need to delete to re-run the checks
$ nix path-info .#checks.<system>.ct .#checks.<system>.eunit .#checks.<system>.treefmt
# Delete the store paths from the store
$ nix-store --delete <paths...>
# Re-run the checks, printing the build output and with more verbosity
$ nix flake check -L -v
```

# Potential inspiration

- Simulate bad network connections with [comcast][comcast]
- Chaos engineering for Kubernetes with [Chaos Mesh][chaos-mesh] 

[comcast]: https://github.com/tylertreat/comcast
[chaos-mesh]: https://github.com/chaos-mesh/chaos-mesh
[osi]: https://en.wikipedia.org/wiki/OSI_model
