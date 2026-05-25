-module(network_endpoint).
-moduledoc """
A network endpoint is connected to one end of a wire via a channel.
The channel controls the flow of data and it owned by the wire.

These callbacks require `{Module, Endpoint}` to function because they have to
call into the `gen_server` behavior to store any information.

The wire connection will fire a synchronous callback which returns a Channel
`pid()` for the network device to send subsequent binary messages.

The wire disconnect will fire a callback which allows the endpoint to clean up
its' internal state related to the connection.

The wire send will fire a callback which allows the endpoint to do any state
management it would like e.g. saving the most recent frame.
""".

-doc """
The network endpoint can call,

```erlang
wire:connect({Module :: atom(), Endpoint :: pid()}, Wire :: pid())
```

if it succeeds we'll get back a channel to store in the network endpoint
internal state and subsequently call
```erlang
wire:send(Channel :: pid(), Msg :: binary())
```
""".
-callback connected({Mod :: atom(), Endpoint :: pid()}, Channel :: pid()) -> ok.

-doc """
The network endpoint can call,

```erlang
wire:disconnect({Module :: atom(), Endpoint :: pid()}, Wire :: pid(), Channel :: pid())
```

if it succeeds we'll just get back the pair to cleanup the network endpoint
internal state.
""".
-callback disconnected({Mod :: atom(), Endpoint :: pid()}) -> ok.

-doc """
The network endpoint can call

```erlang
channel:send(
    {Module :: atom(), Endpoint :: pid()},
    Channel :: pid(),
    Msg :: binary()
)
```
if it succeeds, we'll back back the successful message
e.g. if we want to store it in the network endpoint internal state.
""".
-callback sent({Mod :: atom(), Endpoint :: pid()}, Msg :: binary()) -> ok.
