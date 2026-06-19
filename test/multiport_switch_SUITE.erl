-module(multiport_switch_SUITE).

-include_lib("eunit/include/eunit.hrl").

-export([
    broadcast/1,
    learning/1
]).

-export([
    all/0,
    init_per_suite/1,
    end_per_suite/1,
    init_per_testcase/2,
    end_per_testcase/2
]).

all() ->
    [
        broadcast,
        learning
    ].

-doc """
In these tests we transmit frames through async messages. We need to wait
for all messages to propogate through the network before we can evaluate the
assertions.

We require `Times` because the network may never reach a fix point.

Technically, `supervisor:start_child/2` can return `{ok, undefined}`, but if
that happens this will fail and that is fine.
""".
-spec wait_for(list(undefined | pid()), pos_integer()) ->
    ok | {error, unable_to_reach_fixed_point}.
wait_for(_Pids, 0) ->
    {error, unable_to_reach_fixed_point};
wait_for(Pids, Times) ->
    {ok, Length} = go_wait_for(Pids, 0),
    case Length of
        0 -> ok;
        _ -> wait_for(Pids, Times - 1)
    end.

go_wait_for([], Acc) ->
    {ok, Acc};
go_wait_for([Pid | Pids], Acc) ->
    {message_queue_len, Length} = erlang:process_info(Pid, message_queue_len),
    go_wait_for(Pids, Acc + Length).

broadcast(_Config) ->
    % Resources
    {ok, WireOnePid} = wire:create(),
    {ok, WireTwoPid} = wire:create(),
    {ok, WireThreePid} = wire:create(),

    {ok, SwitchPid} = multiport_switch:create(3),

    {ok, NicOnePid} = network_interface_card:create(),
    {ok, NicTwoPid} = network_interface_card:create(),
    {ok, NicThreePid} = network_interface_card:create(),

    % Topology
    %% graph LR
    %%     NicOne -->|WireOne| Switch
    %%     Switch -->|WireTwo| NicTwo
    %%     Switch -->|WireThree| NicThree
    ok = multiport_switch:connect(SwitchPid, WireOnePid),
    ok = network_interface_card:connect(NicOnePid, WireOnePid),

    ok = multiport_switch:connect(SwitchPid, WireTwoPid),
    ok = network_interface_card:connect(NicTwoPid, WireTwoPid),

    ok = multiport_switch:connect(SwitchPid, WireThreePid),
    ok = network_interface_card:connect(NicThreePid, WireThreePid),

    % Transmission
    {ok, SrcMac} = network_interface_card:get_mac(NicOnePid),
    {ok, DestMac} = network_interface_card:get_mac(NicTwoPid),
    {ok, Msg} = ethernet:encode(SrcMac, DestMac, crypto:strong_rand_bytes(46)),
    ok = network_interface_card:send(NicOnePid, WireOnePid, Msg),

    ok = wait_for(
        [
            WireOnePid, WireTwoPid, WireThreePid, SwitchPid, NicOnePid, NicTwoPid, NicThreePid
        ],
        10
    ),

    % Assertions
    {ok, OneBuffer} = network_interface_card:get_buffer(NicOnePid),
    ?assertEqual([], OneBuffer),
    {ok, TwoBuffer} = network_interface_card:get_buffer(NicTwoPid),
    ?assertEqual([Msg], TwoBuffer),
    {ok, ThreeBuffer} = network_interface_card:get_buffer(NicThreePid),
    ?assertEqual([Msg], ThreeBuffer).

learning(_Config) ->
    % Resources
    {ok, WireOnePid} = wire:create(),
    {ok, WireTwoPid} = wire:create(),
    {ok, WireThreePid} = wire:create(),

    {ok, SwitchPid} = multiport_switch:create(3),

    {ok, NicOnePid} = network_interface_card:create(),
    {ok, NicTwoPid} = network_interface_card:create(),
    {ok, NicThreePid} = network_interface_card:create(),

    % Topology
    %% graph LR
    %%     NicOne -->|WireOne| Switch
    %%     Switch -->|WireTwo| NicTwo
    %%     Switch -->|WireThree| NicThree
    ok = multiport_switch:connect(SwitchPid, WireOnePid),
    ok = network_interface_card:connect(NicOnePid, WireOnePid),

    ok = multiport_switch:connect(SwitchPid, WireTwoPid),
    ok = network_interface_card:connect(NicTwoPid, WireTwoPid),

    ok = multiport_switch:connect(SwitchPid, WireThreePid),
    ok = network_interface_card:connect(NicThreePid, WireThreePid),

    % Transmission
    {ok, SrcMac} = network_interface_card:get_mac(NicOnePid),
    {ok, DestMac} = network_interface_card:get_mac(NicTwoPid),
    {ok, MsgOne} = ethernet:encode(SrcMac, DestMac, crypto:strong_rand_bytes(46)),
    {ok, MsgTwo} = ethernet:encode(DestMac, SrcMac, crypto:strong_rand_bytes(46)),

    % Source will be saved in the CAM table and then broadcast
    ok = network_interface_card:send(NicOnePid, WireOnePid, MsgOne),
    ok = wait_for(
        [
            WireOnePid, WireTwoPid, WireThreePid, SwitchPid, NicOnePid, NicTwoPid, NicThreePid
        ],
        10
    ),

    % Known destination, no broadcast!
    ok = network_interface_card:send(NicTwoPid, WireTwoPid, MsgTwo),
    ok = wait_for(
        [
            WireOnePid, WireTwoPid, WireThreePid, SwitchPid, NicOnePid, NicTwoPid, NicThreePid
        ],
        10
    ),

    % Assertions
    %% Frame sent from NicTwo directly
    {ok, OneBuffer} = network_interface_card:get_buffer(NicOnePid),
    ?assertEqual([MsgTwo], OneBuffer),

    %% Frame sent from NicOne as broadcast
    {ok, TwoBuffer} = network_interface_card:get_buffer(NicTwoPid),
    ?assertEqual([MsgOne], TwoBuffer),

    %% Frame sent from NicOne as broadcast
    {ok, ThreeBuffer} = network_interface_card:get_buffer(NicThreePid),
    ?assertEqual([MsgOne], ThreeBuffer).

init_per_suite(Config) ->
    {ok, _} = application:ensure_all_started(hauntstack),
    Config.

end_per_suite(_Config) ->
    ok = application:stop(hauntstack),
    ok.

init_per_testcase(_TestCase, Config) ->
    Config.

end_per_testcase(_TestCase, _Config) ->
    ok.
