-module(channel_sup).
-moduledoc """
    
""".

-behavior(supervisor).

-export([
    build/0
]).

-export([
    start_link/0,
    init/1
]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    {ok,
        {{simple_one_for_one, 3, 30}, [
            {server_channel,
                {
                    server_channel, start_link, []
                },
                temporary, 2000, worker, []}
        ]}}.

build() ->
    Id = crypto:strong_rand_bytes(6),
    supervisor:start_child(?MODULE, [Id]).
