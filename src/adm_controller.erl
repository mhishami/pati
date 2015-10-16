%% adm_controller.erl
-module (adm_controller).
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

handle_request(<<"GET">>, <<"user">>, [<<"new">>], Params, _) ->
    User = get_user(Params),
    {render, <<"adm_user_new">>, [
        {user, User},
        {menu_users, <<"active">>}
    ]};

handle_request(<<"POST">>, <<"user">>, [<<"new">>], Params, _) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),
    Name  = proplists:get_value(<<"name">>, PostVals),
    Email = proplists:get_value(<<"email">>, PostVals),
    Role = proplists:get_value(<<"role">>, PostVals),
    Pass1 = proplists:get_value(<<"password">>, PostVals),
    Pass2 = proplists:get_value(<<"password2">>, PostVals),

    case Pass1 =/= Pass2 orelse Pass1 =:= <<>> orelse Pass2 =:= <<>> of
        true ->
            %% show error
            {render, <<"adm_user_new">>, [
                    {user, Email},
                    {name, Name},
                    {email, Email},
                    {role, Role},
                    {error, <<"Bad password!">>},
                    {menu_users, <<"active">>}
                ]};
        false ->
            %% save user
            User = #{
                <<"name">> => Name,
                <<"email">> => Email,
                <<"role">> => Role,
                <<"password">> => web_util:hash_password(Pass2)
            },
            mongo_worker:save(?DB_USER, User),
            {redirect, <<"/adm/users">>}
    end;

handle_request(<<"POST">>, <<"user">>, [<<"edit">>], Params, _) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),
    Id = proplists:get_value(<<"id">>, PostVals),

    User = get_user(Params),
    {ok, Data} = mongo_worker:find_one(?DB_USER, {<<"email">>, Id}),
    {ok, Name} = maps:find(<<"name">>, Data),
    {ok, Email} = maps:find(<<"email">>, Data),
    ?DEBUG("Data= ~p~n", [Data]),
    {render, <<"adm_user_edit">>, [
            {user, User}, {name, Name}, {email, Email}, {role, <<"user">>},
            {menu_users, <<"active">>}
        ]};

handle_request(<<"POST">>, <<"user">>, [<<"delete">>], Params, _) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),
    Id = proplists:get_value(<<"id">>, PostVals),

    ?DEBUG("Deleting user ~p~n", [Id]),
    mongo_worker:delete(?DB_USER, {<<"email">>, Id}),
    {redirect, <<"/adm/users">>};

handle_request(<<"POST">>, <<"user">>, [<<"update">>], Params, _) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),
    Name  = proplists:get_value(<<"name">>, PostVals),
    Email = proplists:get_value(<<"email">>, PostVals),
    Role = proplists:get_value(<<"role">>, PostVals),
    Pass1 = proplists:get_value(<<"password">>, PostVals),
    Pass2 = proplists:get_value(<<"password2">>, PostVals),

    case Pass1 =/= Pass2 orelse Pass1 =:= <<>> orelse Pass2 =:= <<>> of
        true ->
            %% show error
            {render, <<"adm_user_edit">>, [
                    {user, Email},
                    {name, Name},
                    {email, Email},
                    {role, Role},
                    {error, <<"Bad password!">>},
                    {menu_users, <<"active">>}
                ]};
        false ->
            %% update password
            {ok, User} = mongo_worker:find_one(?DB_USER, {<<"email">>, Email}),
            User2 = User#{
                    <<"password">> := web_util:hash_password(Pass2),
                    <<"name">> := Name
                },
            mongo_worker:update(?DB_USER, User2),
            {redirect, <<"/adm/users">>}
    end;

handle_request(<<"GET">>, <<"cos">>, _, Params, _) ->
    User = get_user(Params),
    {ok, Cos} = mongo_worker:find(?DB_CO, {}),
    {render, <<"adm_cos">>, [
            {user, User},
            {companies, web_util:maps_to_list(Cos)},
            {menu_cos, <<"active">>}
        ]};

handle_request(<<"GET">>, <<"co">>, [<<"new">>], Params, _) ->
    User = get_user(Params),
    {render, <<"adm_co_new">>, [
        {user, User},
        {menu_cos, <<"active">>}
    ]};

handle_request(<<"POST">>, <<"co">>, [<<"new">>], Params, _) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),

    % Type = proplists:get_value(<<"type">>, PostVals),
    % Name = proplists:get_value(<<"name">>, PostVals),
    % RegNo = proplists:get_value(<<"regno">>, PostVals),
    % Address = proplists:get_value(<<"address">>, PostVals),
    % Postcode = proplists:get_value(<<"postcode">>, PostVals),
    % State = proplists:get_value(<<"state">>, PostVals),
    % Phone = proplists:get_value(<<"phone">>, PostVals),
    % Email = proplists:get_value(<<"email">>, PostVals),

    Company = maps:from_list(PostVals),
    mongo_worker:save(?DB_CO, Company),
    {redirect, <<"/adm/cos">>};

handle_request(<<"POST">>, <<"co">>, [<<"edit">>], Params, _) ->
    User = get_user(Params),
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),
    RegNo = proplists:get_value(<<"id">>, PostVals),

    ?DEBUG("Co RegNo= ~p~n", [RegNo]),
    {ok, Company} = mongo_worker:find_one(?DB_CO, {<<"regno">>, RegNo}),
    {ok, Type} = maps:find(<<"type">>, Company),
    {render, <<"adm_co_edit">>, [
        {user, User},
        case Type of
            <<"bhd">> -> {check_bhd, <<"checked">>};
            <<"sdn bhd">> -> {check_sdnbhd, <<"checked">>};
            <<"enterprise">> -> {check_ent, <<"checked">>}
        end,                
        {menu_cos, <<"active">>}|
        web_util:map_to_list(Company)
    ]};

handle_request(<<"POST">>, <<"co">>, [<<"update">>], Params, _) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),
    Type = proplists:get_value(<<"type">>, PostVals),
    Name = proplists:get_value(<<"name">>, PostVals),
    RegNo = proplists:get_value(<<"regno">>, PostVals),
    Address = proplists:get_value(<<"address">>, PostVals),
    Postcode = proplists:get_value(<<"postcode">>, PostVals),
    State = proplists:get_value(<<"state">>, PostVals),
    Phone = proplists:get_value(<<"phone">>, PostVals),
    Email = proplists:get_value(<<"email">>, PostVals),
    Dir1Name = proplists:get_value(<<"dir1name">>, PostVals),
    Dir1Phone = proplists:get_value(<<"dir1phone">>, PostVals),
    Dir2Name = proplists:get_value(<<"dir2name">>, PostVals),
    Dir2Phone = proplists:get_value(<<"dir2phone">>, PostVals),
    
    {ok, Company} = mongo_worker:find_one(?DB_CO, {<<"regno">>, RegNo}),

    case State =:= <<"--">> of
        true ->
            %% select state
            User = get_user(Params),
            {render, <<"adm_co_edit">>, [
                {user, User},
                {error, <<"Please select state">>},
                case Type of
                    <<"bhd">> -> {check_bhd, <<"checked">>};
                    <<"sdn bhd">> -> {check_sdnbhd, <<"checked">>};
                    <<"enterprise">> -> {check_ent, <<"checked">>}
                end,                
                {menu_cos, <<"active">>}|
                web_util:map_to_list(Company)
            ]};
        _ ->
            C2 = Company#{
                <<"type">> := Type,
                <<"name">> := Name,
                <<"regno">> := RegNo,
                <<"address">> := Address,
                <<"postcode">> := Postcode,
                <<"state">> := State,
                <<"phone">> := Phone,
                <<"email">> := Email,
                <<"dir1name">> := Dir1Name,
                <<"dir1phone">> := Dir1Phone,
                <<"dir2name">> := Dir2Name,
                <<"dir2phone">> := Dir2Phone
            },
            mongo_worker:update(?DB_CO, C2),
            {redirect, <<"/adm/cos">>}
    end;

handle_request(<<"POST">>, <<"co">>, [<<"delete">>], Params, _) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),
    Id = proplists:get_value(<<"id">>, PostVals),

    ?DEBUG("Deleting Company ~p~n", [Id]),
    mongo_worker:delete(?DB_CO, {<<"regno">>, Id}),
    {redirect, <<"/adm/cos">>};

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



