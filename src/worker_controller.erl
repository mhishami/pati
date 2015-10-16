-module(worker_controller).
-export([handle_request/5]).
-export([before_filter/1]).

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
    User = get_user(Params),
    {render, [{user, User}]};

handle_request(_, _, _, _, _) ->
    {redirect, <<"/">>}.

get_user(Params) ->
    case maps:find(<<"auth">>, Params) of
        {ok, User} -> User;
        _          -> undefined
    end.
