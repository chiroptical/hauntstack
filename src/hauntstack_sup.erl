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
        %% supervisor_wire:build() allows you to generate a wire
        #{
            id => server_wire_supervisor,
            start => {supervisor_wire, start_link, []}
        },
        %% supervisor_nic:build() allows you to generate a NIC
        #{
            id => server_nic_supervisor,
            start => {supervisor_nic, start_link, []}
        }
    ],
    {ok, {SupFlags, ChildSpecs}}.

%% internal functions
