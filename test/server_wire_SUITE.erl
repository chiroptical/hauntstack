-module(server_wire_SUITE).

-include_lib("eunit/include/eunit.hrl").

-export([
    unsafe_plug_in_unplug/1,
    unsafe_unplug_without_plug_in/1,
    unsafe_plug_in_plug_in/1
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
        unsafe_plug_in_unplug,
        unsafe_unplug_without_plug_in,
        unsafe_plug_in_plug_in
    ].

unsafe_unplug_without_plug_in(_Config) ->
    {ok, WirePid} = supervisor_wire:build(),
    {ok, NicPid} = supervisor_nic:build(),
    Unplug = server_wire:unsafe_unplug(WirePid, NicPid),
    ?assertEqual(Unplug, {error, wire_not_connected}).

unsafe_plug_in_unplug(_Config) ->
    {ok, WirePid} = supervisor_wire:build(),
    {ok, NicPid} = supervisor_nic:build(),
    PlugIn = server_wire:unsafe_plug_in(WirePid, NicPid),
    ?assertEqual(PlugIn, ok),
    Unplug = server_wire:unsafe_unplug(WirePid, NicPid),
    ?assertEqual(Unplug, ok).

unsafe_plug_in_plug_in(_Config) ->
    {ok, WirePid} = supervisor_wire:build(),
    {ok, NicPid} = supervisor_nic:build(),
    One = server_wire:unsafe_plug_in(WirePid, NicPid),
    ?assertEqual(One, ok),
    Two = server_wire:unsafe_plug_in(WirePid, NicPid),
    ?assertEqual(Two, {error, refuse_wire_to_self}).

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
