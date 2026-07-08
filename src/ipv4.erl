-module(ipv4).
-moduledoc """
    
""".

-export([
    encode/3,
    decode/1,
    checksum/1
]).

-type encode_error() :: exceeds_maximum_length.

-type address() :: <<_:32>>.

-spec encode(SrcAddress :: address(), DestAddress :: address(), Payload :: binary()) ->
    {ok, binary()} | {error, encode_error()}.
-doc """
https://en.wikipedia.org/wiki/IPv4
- maximum IP length of 65,535 bytes

# TODO

- Do we want to allow the Options field? https://en.wikipedia.org/wiki/IPv4#Options
  Requires change to guard `> 65515` (65535 - 20 = 65515), compute proper
  InternetHeaderLength
- TimeToLive hardcoded to 10 probably doesn't make sense
- Protocol is hardcoded to ICMP
""".
encode(_, _, Payload) when byte_size(Payload) > 65515 ->
    % TODO: If we allow options, `> 65515` is no longer correct
    {error, exceeds_maximum_length};
encode(SrcAddress, DestAddress, Payload) ->
    % 4 bits, always set to 4
    Version = 4,
    % 4 bits, minimum size is 5, maximum size is 15
    InternetHeaderLength = 5,
    % 6 bits, sometimes used for VOIP
    % https://en.wikipedia.org/wiki/Differentiated_services#Class_Selector
    DifferentiatedServicesCodePoint = 0,
    % 2 bits, end to end notifications of network congestion without dropping packets
    % https://en.wikipedia.org/wiki/Explicit_Congestion_Notification#Operation_of_ECN_with_IP
    ExplicitCongestionNotification = 2#00,
    % 16 bits, identify groups of fragments of a single datagram
    Identification = 0,
    % Flags, 1 bit each
    % always set to zero
    Reserved = 0,
    % can the datagram be fragmented
    DontFragment = 0,
    % set to 1 when there are more fragments to a datagram
    MoreFragments = 0,
    % 13 bits, range 0-8191, first fragment is offset 0
    FragmentOffset = 0,
    % 8 bits, specified in seconds but in practice a "hop counter"
    TimeToLive = 10,
    % 8 bits
    % 1 - Internet Control Message Protocol (ICMP)
    % 2 - Internet Group Management Protocol (IGMP)
    % 6 - Transmission Control Protocol (TCP)
    % 17 - User Datagram Protocol (UDP)
    Protocol = 1,

    % 0-320 bits, padded to multiples of 32 bits
    % Options = 0,

    % 16 bits
    TotalLength = InternetHeaderLength * 4 + byte_size(Payload),

    % First 80 bits of the header
    Header =
        <<Version:4, InternetHeaderLength:4, DifferentiatedServicesCodePoint:6,
            ExplicitCongestionNotification:2, TotalLength:16, Identification:16, Reserved:1,
            DontFragment:1, MoreFragments:1, FragmentOffset:13, TimeToLive:8, Protocol:8>>,

    % Initialize checksum to zero to compute checksum
    HeaderWithoutChecksum =
        <<Header/binary, 0:16, SrcAddress/binary, DestAddress/binary>>,

    % 16 bits, 16-bit ones' complement of the ones' complement sum of all 16-bit words in the header
    Checksum = checksum(HeaderWithoutChecksum),

    {ok,
        <<Header/binary, Checksum:2/binary, SrcAddress/binary, DestAddress/binary, Payload/binary>>}.

-type decode_error() :: invalid_ipv4_message | invalid_ipv4_checksum.

-spec decode(In :: binary()) -> {ok, {binary(), binary(), binary()}} | {error, decode_error()}.
-doc """
# TODO

- Need encoders/decoders for each field matched from `<<Header:80>>`
""".
decode(
    <<Header:80, Checksum:2/binary, SrcAddress:32, DestAddress:32, Payload/binary>>
) ->
    <<_Version:4, _InternetHeaderLength:4, _DifferentiatedServicesCodePoint:6,
        _ExplicitCongestionNotification:2, _TotalLength:16, _Identification:16, _Reserved:1,
        _DontFragment:1, _MoreFragments:1, _FragmentOffset:13, _TimeToLive:8, _Protocol:8>> = <<
        Header:80
    >>,
    HeaderWithoutChecksum = <<Header:80, 0:16, SrcAddress:32, DestAddress:32>>,
    ComputedChecksum = checksum(HeaderWithoutChecksum),
    case ComputedChecksum of
        Checksum ->
            {ok, {<<SrcAddress:32>>, <<DestAddress:32>>, Payload}};
        _ ->
            {error, invalid_ipv4_checksum}
    end;
decode(_In) ->
    {error, invalid_ipv4_message}.

-spec checksum(Header :: binary()) -> <<_:16>>.
checksum(Header) ->
    % draw 16 bit chunks from the Header and sum them
    Sum = lists:sum([W || <<W:16>> <= Header]),
    Result = fold(bnot fold(Sum) band 16#FFFF),
    <<Result:16>>.

fold(N) when N > 16#FFFF ->
    fold((N band 16#FFFF) + (N bsr 16));
fold(N) ->
    N.
