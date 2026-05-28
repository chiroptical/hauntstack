-module(network_interface_card).
-moduledoc """
""".

-behavior(gen_server).
-behavior(network_endpoint).

%% public exports
-export([
    create/0,
    get_buffer/1
]).

%% network_endpoint exports
-export([
    connect/2,
    disconnect/2,
    send/3,
    on_connect/2,
    on_disconnect/2,
    on_receive/3
]).

%% gen_server exports
-export([
    start_link/1,
    handle_cast/2,
    handle_info/2,
    handle_call/3,
    init/1,
    code_change/3,
    terminate/2
]).

create() ->
    Mac = crypto:strong_rand_bytes(6),
    supervisor:start_child(network_interface_card_sup, [Mac]).

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

get_buffer(Endpoint) ->
    gen_server:call(Endpoint, get_buffer).

-spec start_link(Id :: binary()) -> gen_server:start_ret().
start_link(Id) ->
    gen_server:start_link(?MODULE, [Id], []).

-type link_status() :: down | {up, Wire :: pid()}.

-type message_buffer() :: list(binary()).

-record(state, {
    mac :: binary(),
    link :: link_status(),
    buffer :: message_buffer()
}).

init([Mac]) ->
    {ok, #state{mac = Mac, link = down, buffer = []}}.

handle_cast({on_receive, Wire, Msg}, State = #state{link = {up, Wire}}) ->
    {noreply, State#state{buffer = [Msg | State#state.buffer]}};
handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Msg, State) ->
    {noreply, State}.

handle_call(get_buffer, _From, State = #state{buffer = Buffer}) ->
    {reply, {ok, Buffer}, State};
handle_call({disconnect, Wire}, _From, State = #state{link = Link}) ->
    case Link of
        {up, Wire} ->
            {reply, ok, State#state{link = down}};
        _ ->
            {reply, {error, wire_disconnect_failed}, State}
    end;
handle_call({connect, Wire}, _From, State = #state{link = Link}) ->
    case Link of
        down ->
            {reply, ok, State#state{link = {up, Wire}}};
        {up, _} ->
            {reply, {error, wire_connect_failed}, State}
    end.

code_change(_OldVersion, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.
