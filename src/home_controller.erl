-module(home_controller).
-author ('Hisham Ismail <mhishami@gmail.com').

-export ([handle_request/5]).
-export ([before_filter/1]).

-include("pati.hrl").

-spec before_filter(binary()) -> {ok, proceed} | {redirect, binary()}.
before_filter(_) ->
    {ok, proceed}.

-spec handle_request(binary(), binary(), list(), list(), list()) -> 
    {render, binary(), list()} | 
    {redirect, binary()} |
    {redirect, binary(), {any(), any()}}.

handle_request(<<"GET">>, _Action, _Args, Params, _Req) ->   
    ?DEBUG("Params= ~p~n", [Params]),
    %% / will render home.dtl
    case maps:find(<<"auth">>, Params) of
        {ok, User} -> {render, [{user, User}]};
        _          -> {render, []}
    end.
