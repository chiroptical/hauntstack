-module(server_wire).
-moduledoc """
A wire represents a connection between two network interface cards (NIC).

The connection has a `left` and `right` side, each can be `unplugged` or
`{plugged, Into}`. The sides of the wire are only needed to figure out where
to forward messages to.

All networking messages should use `server_wire:send/2` to relay information.
These are asynchronous messages and only do anything if both sides are plugged
in and the caller `pid()` matches one of the sides.

A wire's connection status is managed by a NIC. There is no public interface to
a wire to plug or unplug it. See `server_nic:plug_in/2` for more details. You
are free to call `unsafe_plug_in/2` or `unsafe_unplug/2` but unintended haunting
will occur.
""".

-behavior(gen_server).

-export([
    start_link/1,
    unsafe_plug_in/2,
    unsafe_unplug/2
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

-spec unsafe_plug_in(Wire :: pid(), Nic :: pid()) -> Reply :: term().
-doc """
    
""".
unsafe_plug_in(Wire, Nic) ->
    gen_server:call(Wire, {plug_in, Nic}).

-spec unsafe_unplug(Wire :: pid(), Nic :: pid()) -> Reply :: term().
-doc """
    
""".
unsafe_unplug(Wire, Nic) ->
    gen_server:call(Wire, {unplug, Nic}).

-type status() :: unplugged | {plugged, Nic :: binary()}.

-record(state, {id :: binary(), left :: status(), right :: status()}).

init([Id]) ->
    {ok, #state{id = Id, left = unplugged, right = unplugged}}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Msg, State) ->
    {noreply, State}.

handle_call({plug_in, Nic}, _From, State = #state{left = Left, right = Right}) ->
    case {Left, Right} of
        {unplugged, _} ->
            {reply, ok, State#state{left = {plugged, Nic}}};
        {{plugged, L}, unplugged} when L =:= Nic ->
            {reply, {error, refuse_wire_to_self}, State};
        {_, unplugged} ->
            {reply, ok, State#state{right = {plugged, Nic}}};
        _ ->
            {reply, {error, wire_fully_plugged_in}, State}
    end;
handle_call({unplug, Nic}, _From, State = #state{left = Left, right = Right}) ->
    case {Left, Right} of
        {{plugged, Nic}, _} -> {reply, ok, State#state{left = unplugged}};
        {_, {plugged, Nic}} -> {reply, ok, State#state{right = unplugged}};
        _ -> {reply, {error, wire_not_connected}, State}
    end.

code_change(_OldVersion, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.
