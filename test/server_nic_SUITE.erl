-module(server_nic_SUITE).

-include_lib("eunit/include/eunit.hrl").

-export([
    plug_in_and_unplug_two_nics/1,
    unplug_error_not_plugged/1,
    plug_in_plug_in_error_already_connected/1
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
        plug_in_and_unplug_two_nics,
        unplug_error_not_plugged,
        plug_in_plug_in_error_already_connected
    ].

plug_in_plug_in_error_already_connected(_Config) ->
    {ok, WirePid} = supervisor_wire:build(),
    {ok, NicPid} = supervisor_nic:build(),
    ok = server_nic:plug_in(NicPid, WirePid),
    Result = server_nic:plug_in(NicPid, WirePid),
    ?assertEqual(Result, {error, nic_already_connected}).

unplug_error_not_plugged(_Config) ->
    {ok, NicPid} = supervisor_nic:build(),
    Result = server_nic:unplug(NicPid),
    ?assertEqual(Result, {error, nic_unplugged}).

plug_in_and_unplug_two_nics(_Config) ->
    {ok, WirePid} = supervisor_wire:build(),
    {ok, NicOnePid} = supervisor_nic:build(),
    {ok, NicTwoPid} = supervisor_nic:build(),
    ok = server_nic:plug_in(NicOnePid, WirePid),
    ok = server_nic:plug_in(NicTwoPid, WirePid),
    ok = server_nic:unplug(NicOnePid),
    ok = server_nic:unplug(NicTwoPid),
    One = server_wire:unsafe_unplug(WirePid, NicOnePid),
    ?assertEqual(One, {error, wire_not_connected}),
    Two = server_wire:unsafe_unplug(WirePid, NicTwoPid),
    ?assertEqual(Two, {error, wire_not_connected}).

init_per_suite(Config) ->
    Config.

end_per_suite(_Config) ->
    ok.

init_per_testcase(_TestCase, Config) ->
    {ok, _} = supervisor_wire:start_link(),
    {ok, _} = supervisor_nic:start_link(),
    Config.

end_per_testcase(_TestCase, _Config) ->
    ok.
