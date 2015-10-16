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

handle_request(<<"GET">>, <<"new">>, _Args, Params, _) ->
    User = get_user(Params),
    ?DEBUG("Params = ~p~n", [Params]),
    {ok, Cos} = mongo_worker:find(?DB_CO, {}),

    {render, <<"worker_new">>, [
        {user, User},
        {companies, web_util:maps_to_list(Cos)},
        {menu_workers, <<"active">>}
    ]};

handle_request(_, _, _, _, _) ->
    {redirect, <<"/">>}.

get_user(Params) ->
    case maps:find(<<"auth">>, Params) of
        {ok, User} -> User;
        _          -> undefined
    end.
