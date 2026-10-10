-module(address_resolution_tests).

-include_lib("eunit/include/eunit.hrl").

roundtrip_test() ->
    SrcNicMac = crypto:strong_rand_bytes(6),
    SrcIpAddr = crypto:strong_rand_bytes(4),
    DestNicMac = crypto:strong_rand_bytes(6),
    DestIpAddr = crypto:strong_rand_bytes(4),
    {ok, Encoded} = address_resolution:encode(
        SrcNicMac, SrcIpAddr, DestNicMac, DestIpAddr, send
    ),
    Result = address_resolution:decode(Encoded),
    ?assertEqual(Result, {ok, {send, SrcNicMac, SrcIpAddr, DestNicMac, DestIpAddr}}).
