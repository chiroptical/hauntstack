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
    {ok, WirePid} = wire:create(),
    {ok, NicOnePid} = network_interface_card:create(),
    {ok, NicTwoPid} = network_interface_card:create(),
    ok = network_interface_card:connect(NicOnePid, WirePid),
    ok = network_interface_card:connect(NicTwoPid, WirePid),
    ok = network_interface_card:send(NicOnePid, WirePid, ~"hello world"),
    {ok, OneBuffer} = network_interface_card:get_buffer(NicOnePid),
    ?assertEqual([], OneBuffer),
    {ok, TwoBuffer} = network_interface_card:get_buffer(NicTwoPid),
    ?assertEqual([~"hello world"], TwoBuffer).

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
