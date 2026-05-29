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

-spec create(Ports :: pos_integer()) -> supervisor:startchild_ret().
create(Ports) ->
    Mac = crypto:strong_rand_bytes(6),
    supervisor:start_child(multiport_switch_sup, [Mac, Ports]).

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

-spec start_link(Mac :: ethernet:mac(), Ports :: pos_integer()) -> gen_server:start_ret().
start_link(Mac, Ports) ->
    gen_server:start_link(?MODULE, [Mac, Ports], []).

-nominal switch_port() :: pos_integer().

-record(state, {
    mac :: ethernet:mac(),
    down_links :: s2:set(switch_port()),
    up_links :: #{pid() => switch_port()},
    content_addressable_memory :: #{ethernet:mac() => switch_port()}
}).

init([Mac, Ports]) ->
    {ok, #state{
        mac = Mac,
        down_links = s2:from_list(lists:seq(1, Ports)),
        up_links = #{},
        content_addressable_memory = #{}
    }}.

-spec get_broadcast_wires(pid(), #{pid() => switch_port()}) -> list(pid()).
get_broadcast_wires(Wire, UpLinks) ->
    maps:fold(
        fun(Wi, _Po, Acc) ->
            case Wi of
                Wire -> Acc;
                _ -> [Wi | Acc]
            end
        end,
        [],
        UpLinks
    ).

-spec get_port_wire(#{pid() => switch_port()}, switch_port()) ->
    none | {ok, pid()}.
get_port_wire(UpLinks, Port) ->
    Iter = maps:iterator(UpLinks),
    go_get_port_wire(maps:next(Iter), Port).

go_get_port_wire(none, _) -> none;
go_get_port_wire({Pid, Port, _}, Port) -> {ok, Pid};
go_get_port_wire({_Pid, _Port, Iter}, Port) -> go_get_port_wire(maps:next(Iter), Port).

-spec broadcast(list(pid()), binary()) -> ok.
broadcast([], _Msg) ->
    ok;
broadcast([Wire | Wires], Msg) ->
    ok = wire:send({?MODULE, self()}, Wire, Msg),
    broadcast(Wires, Msg).

handle_cast(
    {on_receive, Wire, Msg}, State = #state{up_links = UpLinks, content_addressable_memory = Cam}
) ->
    case UpLinks of
        #{Wire := PortNumber} ->
            maybe
                {ok, {SrcMac, DestMac, _Payload}} ?= ethernet:decode(Msg),
                NextCam = maps:put(SrcMac, PortNumber, Cam),
                ok =
                    case maps:get(DestMac, NextCam, broadcast) of
                        broadcast ->
                            ToWires = get_broadcast_wires(Wire, UpLinks),
                            broadcast(ToWires, Msg);
                        PortNumber ->
                            % Hair-pin, nothing to broadcast
                            ok;
                        KnownPort ->
                            case get_port_wire(UpLinks, KnownPort) of
                                none ->
                                    % The CAM table should forget KnownPort
                                    ok;
                                {ok, KnownWire} ->
                                    broadcast([KnownWire], Msg)
                            end
                    end,
                {noreply, State#state{content_addressable_memory = NextCam}}
            else
                {error, _} ->
                    logging:error("Unable to parse ethernet frame"),
                    {noreply, State}
            end;
        #{} ->
            {noreply, State}
    end.

handle_info(_Msg, State) ->
    {noreply, State}.

-doc """
""".
handle_call({connect, Wire}, _From, State = #state{down_links = DownLinks, up_links = UpLinks}) ->
    case s2:to_list(DownLinks) of
        [] ->
            {reply, {error, no_available_ports}, State};
        [PortNumber | RemainingPorts] ->
            {reply, ok, State#state{
                down_links = s2:from_list(RemainingPorts), up_links = UpLinks#{Wire => PortNumber}
            }}
    end;
handle_call({disconnect, Wire}, _From, State = #state{up_links = UpLinks, down_links = DownLinks}) ->
    case UpLinks of
        #{Wire := PortNumber} ->
            {reply, ok, State#state{
                up_links = maps:remove(Wire, UpLinks), down_links = s2:insert(PortNumber, DownLinks)
            }};
        #{} ->
            {reply, {error, wire_not_connected}}
    end;
handle_call(_Msg, _From, State) ->
    {reply, ok, State}.

code_change(_OldVersion, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.
