-module(user_controller).
-author ('Hisham Ismail <mhishami@gmail.com').

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
    {render, <<"user_new">>, [
        {user, User},
        {menu_users, <<"active">>}
    ]};

handle_request(<<"POST">>, <<"new">>, _Args, Params, _) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),
    Name  = proplists:get_value(<<"name">>, PostVals),
    Email = proplists:get_value(<<"email">>, PostVals),
    Role = proplists:get_value(<<"role">>, PostVals),
    Pass1 = proplists:get_value(<<"password">>, PostVals),
    Pass2 = proplists:get_value(<<"password2">>, PostVals),

    case Pass1 =/= Pass2 orelse Pass1 =:= <<>> orelse Pass2 =:= <<>> of
        true ->
            %% show error
            {render, <<"user_new">>, [
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

handle_request(<<"GET">>, <<"edit">>, _Args, Params, _) ->
    {ok, QsVals} = maps:find(<<"qs_vals">>, Params),
    Id = proplists:get_value(<<"id">>, QsVals),

    User = get_user(Params),
    {ok, Data} = mongo_worker:find_one(?DB_USER, {<<"email">>, Id}),
    {ok, Name} = maps:find(<<"name">>, Data),
    {ok, Email} = maps:find(<<"email">>, Data),
    ?DEBUG("Data= ~p~n", [Data]),
    {render, <<"user_edit">>, [
            {user, User}, {name, Name}, {email, Email}, {role, <<"user">>},
            {menu_users, <<"active">>}
        ]};

handle_request(<<"GET">>, <<"delete">>, _Args, Params, _) ->
    {ok, QsVals} = maps:find(<<"qs_vals">>, Params),
    Id = proplists:get_value(<<"id">>, QsVals),

    ?DEBUG("Deleting user ~p~n", [Id]),
    mongo_worker:delete(?DB_USER, {<<"email">>, Id}),
    {redirect, <<"/adm/users">>};

handle_request(<<"POST">>, <<"update">>, _Args, Params, _) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),
    Name  = proplists:get_value(<<"name">>, PostVals),
    Email = proplists:get_value(<<"email">>, PostVals),
    Role = proplists:get_value(<<"role">>, PostVals),
    Pass1 = proplists:get_value(<<"password">>, PostVals),
    Pass2 = proplists:get_value(<<"password2">>, PostVals),

    case Pass1 =/= Pass2 orelse Pass1 =:= <<>> orelse Pass2 =:= <<>> of
        true ->
            %% show error
            {render, <<"user_edit">>, [
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

handle_request(_, _, _, _, _) ->
    {redirect, <<"/">>}.

get_user(Params) ->
    case maps:find(<<"auth">>, Params) of
        {ok, User} -> User;
        _          -> undefined
    end.
