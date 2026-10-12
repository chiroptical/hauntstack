-module(address_resolution).
-moduledoc """
    
""".

-export([
    probe/2,
    announce/2,
    encode/5,
    decode/1
]).

-define(BROADCAST, <<16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF>>).

probe(SrcMacAddr, DestIpAddr) ->
    encode(SrcMacAddr, <<0:32>>, <<0:48>>, DestIpAddr, send).

announce(SrcMacAddr, SrcIpAddr) ->
    encode(SrcMacAddr, SrcIpAddr, <<0:48>>, SrcIpAddr, send).

-type encode_error() :: err.

-type operation() :: send | recv.

-spec encode_operation(operation()) -> <<_:16>>.
-doc """
1 for send, 2 for reply
""".
encode_operation(send) -> <<1:16>>;
encode_operation(recv) -> <<2:16>>.

-spec decode_operation(<<_:16>>) -> operation().
decode_operation(<<1:16>>) -> send;
decode_operation(<<2:16>>) -> recv.

-spec encode(
    ethernet:mac(),
    ipv4:address(),
    ethernet:mac(),
    ipv4:address(),
    operation()
) -> {ok, binary()} | {error, encode_error()}.
-doc """
# Future considerations
- mac address with different length? Is this a thing?
- ip address with different length? I think ARP is replaced for IPv6?
""".
encode(SenderMac, SenderIp, TargetMac, TargetIp, Operation) ->
    % You can also write <<16#00, 16#01>>
    % 16#01 is 1 in hexadecimal and is 8 bits
    % 1 is ethernet
    % https://www.iana.org/assignments/arp-parameters lists other Hardware Types
    HardwareType = <<16#01:16>>,
    % The protocol for the intended ARP request
    ProtocolType = ether_type:encode(ipv4),
    % The size of mac addresses for the hardware in bytes
    HardwareLength = 6,
    % IPv4 address is 4 bytes
    ProtocolLength = 4,
    Op = encode_operation(Operation),
    {ok,
        <<HardwareType/binary, ProtocolType/binary, HardwareLength:8, ProtocolLength:8, Op/binary,
            SenderMac/binary, SenderIp/binary, TargetMac/binary, TargetIp/binary>>}.

-type decode_error() :: err.

-spec decode(binary()) ->
    {ok, {operation(), binary(), binary(), binary(), binary()}} | {error, decode_error()}.
decode(
    <<_HardwareType:16, _ProtocolType:16, _HardwareLength:8, _ProtocolLength:8, Operation:2/binary,
        SenderMac:6/binary, SenderIp:4/binary, TargetMac:6/binary, TargetIp:4/binary>>
) ->
    Op = decode_operation(Operation),
    {ok, {Op, SenderMac, SenderIp, TargetMac, TargetIp}}.
