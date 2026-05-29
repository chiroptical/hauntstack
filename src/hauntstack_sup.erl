-module(hauntstack_sup).
-moduledoc """
hauntstack top level supervisor
""".

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional
init([]) ->
    SupFlags = #{
        strategy => one_for_all,
        intensity => 0,
        period => 1
    },
    ChildSpecs = [
        %% You need 'wire:create()' to connect network devices
        #{
            id => wire_supervisor,
            start => {wire_sup, start_link, []}
        },
        %% network_interface_card:create() allows you to generate a NIC
        #{
            id => network_interface_card_supervisor,
            start => {network_interface_card_sup, start_link, []}
        },
        %% multiport_switch:create() allows you to generate a switch
        #{
            id => multiport_switch_supervisor,
            start => {multiport_switch_sup, start_link, []}
        }
    ],
    {ok, {SupFlags, ChildSpecs}}.

%% internal functions
