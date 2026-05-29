-module(multiport_switch).
-moduledoc """
    
""".

-behavior(gen_server).
-behavior(network_endpoint).

-export([
    create/1
]).

-export([
    connect/2,
    disconnect/2,
    send/3,
    on_connect/2,
    on_disconnect/2,
    on_receive/3
]).

-export([
    start_link/2,
    handle_cast/2,
    handle_info/2,
    handle_call/3,
    init/1,
    code_change/3,
    terminate/2
]).

%% Strictly speaking a switch does not have a MAC address
-spec create(Ports :: non_neg_integer()) -> supervisor:startchild_ret().
create(Ports) ->
    Id = crypto:strong_rand_bytes(6),
    supervisor:start_child(multiport_switch_sup, [Id, Ports]).

connect(Endpoint, Wire) ->
    wire:connect({?MODULE, Endpoint}, Wire).

disconnect(Endpoint, Wire) ->
    wire:disconnect({?MODULE, Endpoint}, Wire).

send(Endpoint, Wire, Msg) ->
    wire:send({?MODULE, Endpoint}, Wire, Msg).

on_connect(Endpoint, Wire) ->
    gen_server:call(Endpoint, {connect, Wire}).

on_disconnect(Endpoint, Wire) ->
    gen_server:call(Endpoint, {disconnect, Wire}).

on_receive(Endpoint, Wire, Msg) ->
    gen_server:cast(Endpoint, {on_receive, Wire, Msg}).

-spec start_link(Id :: binary(), Ports :: non_neg_integer()) -> gen_server:start_ret().
start_link(Id, Ports) ->
    gen_server:start_link(?MODULE, [Id, Ports], []).

-record(state, {
    id :: binary(),
    links :: #{pos_integer() => wire:link_status()}
}).

-spec initialize_links(Ports :: pos_integer()) -> #{pos_integer() => wire:link_status()}.
initialize_links(Ports) when Ports > 0 ->
    maps:from_keys(lists:seq(1, Ports), down).

init([Id, Ports]) ->
    {ok, #state{id = Id, links = initialize_links(Ports)}}.

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
