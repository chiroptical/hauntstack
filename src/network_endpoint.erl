-module(network_endpoint).
-moduledoc """
A network endpoint is connected to one end of a wire via a channel.
The channel controls the flow of data and it owned by the wire.

# Future considerations

May want to narrow the return type for the synchronous calls. It will simplify
handling `wire.erl` when these callbacks fail, e.g. if it is already connected
to another wire.
""".

-doc """
A synchronous callback for a network endpoint to store the Wire's process id.
The endpoint can call `wire:send/3` to transmit data over the connected wire.
""".
-callback connect(Endpoint :: pid(), Wire :: pid()) -> Reply :: term().

-doc """
A synchronous callback for a network endpoint to forget it is connected to
a wire.
""".
-callback disconnect(Endpoint :: pid(), Wire :: pid()) -> Reply :: term().

-doc """
An asynchronous callback to handle a message transmitted over a wire.
""".
-callback recieve(Endpoint :: pid(), Wire :: pid(), Msg :: binary()) -> ok.
