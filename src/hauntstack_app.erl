%%%-------------------------------------------------------------------
%% @doc hauntstack public API
%% @end
%%%-------------------------------------------------------------------

-module(hauntstack_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    hauntstack_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
