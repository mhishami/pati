-module(co_controller).
-export ([handle_request/5]).
-export ([before_filter/1]).

-include("pati.hrl").

before_filter(SessionId) ->
    %% do some checking
    Sid = session_worker:get_cookies(SessionId),
    case Sid of
        {error, undefined} ->
            {redirect, <<"/auth/login">>};
        _ ->
            {ok, proceed}
    end.

handle_request(<<"GET">>, _Action, _Args, Params, _Req) ->   
    ?DEBUG("Params= ~p~n", [Params]),
    %% / will render home.dtl
    case maps:find(<<"auth">>, Params) of
        {ok, User} -> {render, [{user, User}]};
        _          -> {render, []}
    end.
