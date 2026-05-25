-module(wire).
-moduledoc """
A wire represents a connection between two network interface cards (NIC).

The connection has a `left` and `right` side, each can be `down` or `up`. The
sides of the wire are only needed to manage connecting and disconnecting network
endpoints.

All networking messages should use `wire:send/3` to relay information.
These are asynchronous messages and only do anything if both sides are plugged
in and the caller `pid()` matches one of the sides.

A wire can be connected to anything that implements the `network_endpoint` behavior.
""".

-behavior(gen_server).

%% Public exports
-export([
    build/0,
    connect/2,
    disconnect/2,
    send/3
]).

%% 'gen_server' exports
-export([
    start_link/1,
    handle_cast/2,
    handle_info/2,
    handle_call/3,
    init/1,
    code_change/3,
    terminate/2
]).

build() ->
    Mac = crypto:strong_rand_bytes(6),
    supervisor:start_child(wire_sup, [Mac]).

-spec start_link(Id :: binary()) -> gen_server:start_ret().
start_link(Id) ->
    gen_server:start_link(?MODULE, [Id], []).

-spec connect({Module :: atom(), Endpoint :: pid()}, Wire :: pid()) -> Reply :: term().
connect({Module, Endpoint}, Wire) ->
    gen_server:call(Wire, {connect, {Module, Endpoint}}).

-spec disconnect({Module :: atom(), Endpoint :: pid()}, Wire :: pid()) -> Reply :: term().
disconnect({Module, Endpoint}, Wire) ->
    gen_server:call(Wire, {disconnect, {Module, Endpoint}}).

-spec send({Module :: atom(), Endpoint :: pid()}, Wire :: pid(), Msg :: binary()) -> ok.
send({Module, Endpoint}, Wire, Msg) ->
    gen_server:cast(Wire, {send, {Module, Endpoint}, Msg}).

-record(link, {
    network_endpoint :: {Module :: atom(), Endpoint :: pid()}
}).

-type link_status() :: down | {up, #link{}}.

-record(state, {id :: binary(), left :: link_status(), right :: link_status()}).

init([Id]) ->
    {ok, #state{id = Id, left = down, right = down}}.

handle_info(_Msg, State) ->
    {noreply, State}.

handle_cast({send, {Module, Endpoint}, Msg}, State = #state{left = Left, right = Right}) ->
    maybe
        {ok, _Mac} ?= Module:mac_address(Endpoint),
        case {Left, Right} of
            {
                {up, #link{network_endpoint = {Module, Endpoint}}},
                {up, #link{network_endpoint = {OtherModule, OtherEndpoint}}}
            } ->
                ok = OtherModule:recieve(OtherEndpoint, Msg),
                {noreply, State};
            {
                {up, #link{network_endpoint = {OtherModule, OtherEndpoint}}},
                {up, #link{network_endpoint = {Module, Endpoint}}}
            } ->
                ok = OtherModule:recieve(OtherEndpoint, Msg),
                {noreply, State};
            {_, _} ->
                {noreply, State}
        end
    else
        _Err ->
            {noreply, State}
    end.

handle_call({connect, {Module, Endpoint}}, _From, State = #state{left = Left, right = Right}) ->
    case {Left, Right} of
        {down, _} ->
            maybe
                ok ?= Module:connect(Endpoint, self()),
                {reply, ok, State#state{left = {up, #link{network_endpoint = {Module, Endpoint}}}}}
            else
                _Err ->
                    {reply, {error, unable_to_connect_wire}, State}
            end;
        {_, down} ->
            maybe
                ok ?= Module:connect(Endpoint, self()),
                {reply, ok, State#state{right = {up, #link{network_endpoint = {Module, Endpoint}}}}}
            else
                _Err ->
                    {reply, {error, unable_to_connect_wire}, State}
            end;
        {{up, _}, {up, _}} ->
            {reply, {error, wire_fully_connected}, State}
    end;
handle_call({disconnect, {Module, Endpoint}}, _From, State = #state{left = Left, right = Right}) ->
    case {Left, Right} of
        {{up, #link{network_endpoint = {Module, Endpoint}}}, _} ->
            maybe
                ok ?= Module:disconnect(Endpoint, self()),
                {reply, ok, State#state{left = down}}
            else
                _Err ->
                    {reply, {error, unable_to_disconnect_wire}, State}
            end;
        {_, {up, #link{network_endpoint = {Module, Endpoint}}}} ->
            maybe
                ok ?= Module:disconnect(Endpoint, self()),
                {reply, ok, State#state{right = down}}
            else
                _Err ->
                    {reply, {error, unable_to_disconnect_wire}, State}
            end;
        {_, _} ->
            {reply, {error, wire_not_connected}, State}
    end.

code_change(_OldVersion, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.
