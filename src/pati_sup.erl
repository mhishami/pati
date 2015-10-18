-module(pati_sup).
-author ('Hisham Ismail <mhishami@gmail.com').

-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

-spec start_link() -> any().
start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

-spec init(list()) -> any().
init([]) ->
	Procs = [],
	{ok, {{one_for_one, 1, 5}, Procs}}.
