-module(network_interface_card_sup).
-moduledoc """
    
""".

-behavior(supervisor).

-export([
    start_link/0,
    init/1
]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    {ok,
        {{simple_one_for_one, 3, 30}, [
            {server_nic,
                {
                    server_nic, start_link, []
                },
                temporary, 2000, worker, []}
        ]}}.
