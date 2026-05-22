-module(server_wire).
-moduledoc """
A wire represents a connection between two network interface cards.

The connection has a `left` and `right` side, each can be `unplugged` or
`{plugged, Into}`. The sides of the wire are only needed to figure out where
to forward messages to.

All networking messages should use `server_wire:send/1` to relay information.
These are asynchronous messages and only do anything if both sides are plugged
in and the caller `pid()` matches one of the sides.

A wire's connection status is managed by a NIC. There is no public interface to
a wire to plug or unplug it. See `server_nic:plug_in/2` for more details.

TODO: move to server_nic()
```erlang
{ok, WirePid} = supervisor_wire:build(),
{ok, NicOnePid} = supervisor_nic:build(),
{ok, NicTwoPid} = supervisor_nic:build(),
ok = server_nic:plug_in(NicOnePid, WirePid),
ok = server_nic:plug_in(NicTwoPid, WirePid),
...
```
""".

-behavior(gen_server).

-export([
    start_link/1,
    plug_in/2
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

%% TODO: MOVE TO `server_nic`
-spec plug_in(Child :: pid(), To :: pid()) -> Reply :: term().
plug_in(Child, To) ->
    gen_server:call(Child, {plug_in, To}).

-type status() :: unplugged | {plugged, Into :: binary()}.

-record(state, {id :: binary(), left :: status(), right :: status()}).

init([Id]) ->
    {ok, #state{id = Id, left = unplugged, right = unplugged}}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Msg, State) ->
    {noreply, State}.

handle_call({plug_in, To}, _From, State = #state{left = Left, right = Right}) ->
    case {Left, Right} of
        {unplugged, Right} ->
            {reply, ok, State#state{left = To}};
        {Left, unplugged} ->
            {reply, ok, State#state{right = To}};
        {Left, Right} ->
            {reply, {error, wire_has_no_open_ends}, State}
    end.

code_change(_OldVersion, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.
