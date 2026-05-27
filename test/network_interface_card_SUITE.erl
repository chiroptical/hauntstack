-module(network_interface_card_SUITE).

-include_lib("eunit/include/eunit.hrl").

-export([
    basic/1
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
        basic
    ].

basic(_Config) ->
    {ok, WirePid} = wire:build(),
    {ok, NicOnePid} = network_interface_card:build(),
    {ok, NicTwoPid} = network_interface_card:build(),
    ok = network_interface_card:connect_to(NicOnePid, WirePid),
    ok = network_interface_card:connect_to(NicTwoPid, WirePid),
    ok = network_interface_card:send(NicOnePid, WirePid, ~"hello world"),
    {ok, OneBuffer} = network_interface_card:get_buffer(NicOnePid),
    ?assertEqual([], OneBuffer),
    {ok, TwoBuffer} = network_interface_card:get_buffer(NicTwoPid),
    ?assertEqual([~"hello world"], TwoBuffer).

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
