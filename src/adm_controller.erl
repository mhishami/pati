%% adm_controller.erl
-module (adm_controller).
-author ('Hisham Ismail <mhishami@gmail.com').

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

handle_request(<<"GET">>, <<>>, _, Params, _) ->
    User = get_user(Params),
    {render, <<"adm">>, [
        {user, User},
        {menu_users, <<"active">>}
    ]};

handle_request(<<"GET">>, <<"index">>, _, Params, _) ->
    User = get_user(Params),
    {render, <<"adm">>, [
        {user, User},
        {menu_over, <<"active">>}
    ]};

handle_request(<<"GET">>, <<"users">>, _, Params, _) ->
    User = get_user(Params),
    {ok, Users} = mongo_worker:find(?DB_USER, {}, [], 10),
    {render, <<"adm_users">>, [
            {user, User},
            {users, web_util:maps_to_list(Users)},
            {menu_users, <<"active">>}
        ]};

handle_request(<<"GET">>, <<"cos">>, _, Params, _) ->
    User = get_user(Params),
    {ok, Cos} = mongo_worker:find(?DB_CO, {}),
    {render, <<"adm_cos">>, [
            {user, User},
            {companies, web_util:maps_to_list(Cos)},
            {menu_cos, <<"active">>}
        ]};

handle_request(<<"GET">>, <<"workers">>, _, Params, _) ->
    User = get_user(Params),
    {ok, Cos} = mongo_worker:find(?DB_WORKER, {}, [], 10),
    {render, <<"adm_workers">>, [
            {user, User},
            {users, web_util:maps_to_list(Cos)},
            {menu_workers, <<"active">>}
        ]};

handle_request(<<"GET">>, <<"worker">>, [<<"new">>], Params, _) ->
    User = get_user(Params),
    ?DEBUG("Params = ~p~n", [Params]),
    {render, <<"adm_worker_new">>, [
        {user, User},
        {menu_workers, <<"active">>}
    ]};

handle_request(_Method, _Action, _Args, _Params, _Req) ->    
    %% redirect to /
    {redirect, <<"/">>}.

get_user(Params) ->
    case maps:find(<<"auth">>, Params) of
        {ok, User} -> User;
        _          -> undefined
    end.
