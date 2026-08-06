-module(ipv4_tests).

-include_lib("eunit/include/eunit.hrl").

% https://en.wikipedia.org/wiki/Internet_checksum#Examples
checksum_test() ->
    Header =
        <<16#45, 16#00, 16#00, 16#73, 16#00, 16#00, 16#40, 16#00, 16#40, 16#11, 16#00, 16#00, 16#c0,
            16#a8, 16#00, 16#01, 16#c0, 16#a8, 16#00, 16#c7>>,
    Checksum = ipv4:checksum(Header),
    ?assertEqual(<<16#b8, 16#61>>, Checksum).

roundtrip_test() ->
    SrcAddress = <<0:32>>,
    DestAddress = <<1:32>>,
    Payload = ~"roundtrip?",
    {ok, Packet} = ipv4:encode(SrcAddress, DestAddress, Payload),
    ?assertEqual(ipv4:decode(Packet), {ok, {SrcAddress, DestAddress, Payload}}).
