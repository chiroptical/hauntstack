-module(network_endpoint).
-moduledoc """
A network endpoint is a behavior to unify the interface for building network
topology and sending messages over connected endpoints. All endpoints are
connected by wires which control the flow of information in the network.

The module `network_interface_card` implements this behavior which allows us to
write code like,

```erlang
{ok, Wire} = wire:create(),
{ok, Nic} = network_interface_card:create(),
ok = network_interface_card:connect(Nic, Wire),
ok = network_interface_card:send(Nic, Wire, ~"hello world"),
...
```

# Future considerations

May want to narrow the return type for the synchronous calls. It will simplify
handling `wire.erl` when these callbacks fail, e.g. if it is already connected
to another wire.
""".

-doc """
A synchronous call to `wire:connect/2`, most implementations of this callback
will be,

```erlang
connect(Endpoint, Wire) ->
    wire:connect({?MODULE, Endpoint}, Wire).
```
""".
-callback connect(Endpoint :: pid(), Wire :: pid()) -> Reply :: term().

-doc """
A synchronous call to `wire:disconnect/2`, most implementations of this callback
will be,

```erlang
disconnect(Endpoint, Wire) ->
    wire:disconnect({?MODULE, Endpoint}, Wire).
```
""".
-callback disconnect(Endpoint :: pid(), Wire :: pid()) -> Reply :: term().

-doc """
A synchronous callback for a network endpoint to determine how it wants to store
the wire's process identifier.
""".
-callback on_connect(Endpoint :: pid(), Wire :: pid()) -> Reply :: term().

-doc """
A synchronous callback for a network endpoint to drop its' knowledge of a
previously connected wire.
""".
-callback on_disconnect(Endpoint :: pid(), Wire :: pid()) -> Reply :: term().

-doc """
An asynchronous call to `wire:send/3`, most implementations of this callback
will be,

```erlang
send(Endpoint, Wire, Msg) ->
    wire:send({?MODULE, Endpoint}, Wire, Msg).
```
""".
-callback send(Endpoint :: pid(), Wire :: pid(), Msg :: binary()) -> ok.

-doc """
An asynchronous callback to handle a message transmitted over a wire.
""".
-callback on_receive(Endpoint :: pid(), Wire :: pid(), Msg :: binary()) -> ok.
