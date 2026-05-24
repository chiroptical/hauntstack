-module(ethernet_tests).

-include_lib("eunit/include/eunit.hrl").

roundtrip_test() ->
    SrcNicMac = ~"000001",
    DestNicMac = ~"000002",
    Payload = ~"Lorem ipsum dolor sit amet consectetur adipiscing elit quisque faucibus",
    {ok, Frame} = ethernet:encode(SrcNicMac, DestNicMac, Payload),
    Result = ethernet:decode(Frame),
    ?assertEqual(Result, {ok, {SrcNicMac, DestNicMac, Payload}}).
