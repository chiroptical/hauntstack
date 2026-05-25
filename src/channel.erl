-module(channel).
-moduledoc """
A channel transmits binary data in one direction, it's PID is used by network
endpoints which implement the `network_endpoint` behavior and stored on the
wire.
""".

-behavior(gen_server).

-export([
    start_link/1
]).

-export([
    handle_cast/2,
    handle_info/2,
    handle_call/3,
    init/1,
    code_change/3,
    terminate/2
]).

-spec start_link(Id :: binary()) -> gen_server:start_ret().
start_link(Id) ->
    gen_server:start_link(?MODULE, [Id], []).

-record(state, {
    id :: binary()
}).

init([Id]) ->
    {ok, #state{id = Id}}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Msg, State) ->
    {noreply, State}.

handle_call(_Msg, _From, State) ->
    {reply, ok, State}.

code_change(_OldVersion, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.
