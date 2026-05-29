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
    timer:sleep(50),

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
    % Known destination, no broadcast!
    ok = network_interface_card:send(NicTwoPid, WireTwoPid, MsgTwo),
    timer:sleep(50),

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
