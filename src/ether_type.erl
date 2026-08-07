-module(ether_type).
-moduledoc """
https://en.wikipedia.org/wiki/EtherType#Values
""".

-export([
    encode/1,
    decode/1
]).

-export_type([
    ether_type/0
]).

-type ether_type() :: ipv4 | address_resolution_protocol.

-spec encode(ether_type()) -> <<_:16>>.
encode(ipv4) ->
    <<16#08, 16#00>>;
encode(address_resolution_protocol) ->
    <<16#08, 16#06>>.

-type decode_error() :: unknown_ether_type.

-spec decode(<<_:16>>) -> {ok, ether_type()} | {error, decode_error()}.
decode(<<16#08, 16#00>>) ->
    {ok, ipv4};
decode(<<16#08, 16#06>>) ->
    {ok, address_resolution_protocol};
decode(_) ->
    {error, unknown_ether_type}.
