-module(server_nic).
-moduledoc """
A Network Interface Card (NIC) represents a connection between a switch and a wire.

The connection can be `unplugged` or `{plugged, WirePid}`

All networking messages should use `server_nic:send/2` to relay information.
These are asynchronous messages and only do anything if the NIC is connected to a wire.

A wire's connection status is effetively managed by the NIC. This is the public
interface to plug (`server_nic:plug_in/2`) or unplug (`server_nic:unplug/2`)
a wire.

```erlang
{ok, WirePid} = supervisor_wire:build(),
{ok, NicOnePid} = supervisor_nic:build(),
{ok, NicTwoPid} = supervisor_nic:build(),
ok = server_nic:plug_in(NicOnePid, WirePid),
ok = server_nic:plug_in(NicTwoPid, WirePid),
ok = server_nic:send(NicOnePid, EthernetFrame),
ok = server_nic:unplug(NicOnePid),
{error, unplugged} = server_nic:send(NicOnePid, EthernetFrame),
...
```
""".

-behavior(gen_server).

-export([
    start_link/1,
    plug_in/2,
    unplug/1
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

-spec plug_in(Nic :: pid(), Wire :: pid()) -> Reply :: term().
plug_in(Nic, Wire) ->
    gen_server:call(Nic, {plug_in, Wire}).

-spec unplug(Nic :: pid()) -> Reply :: term().
unplug(Nic) ->
    gen_server:call(Nic, unplug).

-type status() :: unplugged | {plugged, Wire :: binary()}.

-record(state, {id :: binary(), status :: status()}).

init([Id]) ->
    {ok, #state{id = Id, status = unplugged}}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Msg, State) ->
    {noreply, State}.

handle_call({plug_in, Wire}, _From, State = #state{status = Status}) ->
    case Status of
        unplugged ->
            case server_wire:unsafe_plug_in(Wire, self()) of
                ok ->
                    {reply, ok, State#state{status = {plugged, Wire}}};
                {error, wire_fully_plugged_in} ->
                    {reply, {error, unable_to_connect_wire}, State}
            end;
        {plugged, _Pid} ->
            {reply, {error, nic_already_connected}, State}
    end;
handle_call(unplug, _From, State = #state{status = Status}) ->
    case Status of
        unplugged ->
            {reply, {error, nic_unplugged}, State};
        {plugged, Pid} ->
            % safe because the NIC manages the connectedness of a wire
            ok = server_wire:unsafe_unplug(Pid, self()),
            {reply, ok, State#state{status = unplugged}}
    end.

code_change(_OldVersion, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.
