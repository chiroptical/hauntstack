-module(wire_SUITE).

-include_lib("eunit/include/eunit.hrl").

-export([
    disconnect/1,
    connect_disconnect/1,
    connect_connect/1
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
        disconnect,
        connect_disconnect,
        connect_connect
    ].

disconnect(_Config) ->
    {ok, WirePid} = wire:build(),
    {ok, NicPid} = network_interface_card:build(),
    Result = wire:disconnect({network_interface_card, NicPid}, WirePid),
    ?assertEqual({error, wire_not_connected}, Result).

connect_disconnect(_Config) ->
    {ok, WirePid} = wire:build(),
    {ok, NicPid} = network_interface_card:build(),
    Connect = wire:connect({network_interface_card, NicPid}, WirePid),
    ?assertEqual(ok, Connect),
    Disconnect = wire:disconnect({network_interface_card, NicPid}, WirePid),
    ?assertEqual(ok, Disconnect).

connect_connect(_Config) ->
    {ok, WirePid} = wire:build(),
    {ok, NicPid} = network_interface_card:build(),
    One = wire:connect({network_interface_card, NicPid}, WirePid),
    ?assertEqual(ok, One),
    Two = wire:connect({network_interface_card, NicPid}, WirePid),
    ?assertEqual({error, unable_to_connect_wire}, Two).

init_per_suite(Config) ->
    Config.

end_per_suite(_Config) ->
    ok.

init_per_testcase(_TestCase, Config) ->
    {ok, _} = wire_sup:start_link(),
    {ok, _} = network_interface_card_sup:start_link(),
    Config.

end_per_testcase(_TestCase, _Config) ->
    ok.
