-module(ethernet).
-moduledoc """
    
""".

-export([
    encode/3,
    decode/1
]).

-type encode_error() :: mac_invalid_size | too_small_payload | too_large_payload.

-spec encode(SrcNicMac :: binary(), DestNicMac :: binary(), Payload :: binary()) ->
    {ok, binary()} | {error, encode_error()}.
-doc """
Excerpts from https://en.wikipedia.org/wiki/Ethernet_frame#Ethernet_II

EtherType value of 0x0800 indicates that the frame contains an IPv4 datagram,
0x0806 indicates an ARP datagram, and 0x86DD indicates an IPv6 datagram.

Anything below 0x0600 is an 802.3 standard length

# Notes

Technically, this isn't a valid Ethernet II frame because pattern matching on
the Payload is simpler if the CheckSum comes first.

# Learning opportunities

- Why is there a minimum frame size?
- Reimplement `erlang:crc32/1` yourself i.e. https://en.wikipedia.org/wiki/Frame_check_sequence

# Future considerations

- Runt frames?
- Long frames?
- IPv6 and ARP EtherType
- IEEE 802.3 length i.e. < 0x0600
""".
encode(SrcNicMac, _, _) when byte_size(SrcNicMac) =/= 6 ->
    {error, mac_invalid_size};
encode(_, DestNicMac, _) when byte_size(DestNicMac) =/= 6 ->
    {error, mac_invalid_size};
encode(SrcNicMac, DestNicMac, Payload) ->
    Size = byte_size(Payload),
    case Size of
        Size when Size < 46 -> {error, too_small_payload};
        Size when Size > 1500 -> {error, too_large_payload};
        _ ->
            EtherType = ~"2048",
            CheckSum = erlang:crc32(Payload),
            {ok,
                <<SrcNicMac:6/binary, DestNicMac:6/binary, EtherType:4/binary, CheckSum:32,
                    Payload:Size/binary>>}
    end.

-type decode_error() :: invalid_checksum | invalid_ethernet_message.

-spec decode(Msg :: binary()) ->
    {ok, {SrcNicMac :: binary(), DestNicMac :: binary(), Payload :: binary()}}
    | {error, decode_error()}.
-doc """

""".
decode(
    <<SrcNicMac:6/binary, DestNicMac:6/binary, _EtherType:4/binary, CheckSum:32, Payload/binary>>
) ->
    ComputedCheckSum = erlang:crc32(Payload),
    case CheckSum of
        ComputedCheckSum -> {ok, {SrcNicMac, DestNicMac, Payload}};
        _ -> {error, invalid_checksum}
    end;
decode(_) ->
    {error, invalid_ethernet_message}.
