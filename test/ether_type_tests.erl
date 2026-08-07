-module(ether_type_tests).

-include_lib("eunit/include/eunit.hrl").

roundtrip_test() ->
    Enc = ether_type:encode(ipv4),
    ?assertEqual({ok, ipv4}, ether_type:decode(Enc)).
