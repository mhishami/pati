-module(user_controller).
-author ('Hisham Ismail <mhishami@gmail.com').

-export([handle_request/5]).
-export([before_filter/1]).

-include("pati.hrl").

-spec before_filter(binary()) -> {ok, proceed} | {redirect, binary()}.
before_filter(SessionId) ->
    %% do some checking
    Sid = session_worker:get_cookies(SessionId),
    ?DEBUG("Sid= ~p~n", [Sid]),
    case Sid of
        {error, undefined} ->
            {redirect, <<"/auth/login">>};
        _ ->
            {ok, proceed}
    end.

-spec handle_request(binary(), binary(), list(), list(), list()) -> 
    {render, binary(), list()} | 
    {redirect, binary()} |
    {redirect, binary(), {any(), any()}}.

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
                <<"password">> => web_util:hash_password(Pass2),
                <<"uuid">> => uuid:gen()
            },
            mongo_worker:save(?DB_USER, User),
            {redirect, <<"/adm/users">>}
    end;

handle_request(<<"GET">>, <<"edit">>, [UUID], Params, _) ->
    User = get_user(Params),
    {ok, Data} = mongo_worker:find_one(?DB_USER, {<<"uuid">>, UUID}),
    {ok, Name} = maps:find(<<"name">>, Data),
    {ok, Email} = maps:find(<<"email">>, Data),
    {ok, Role} = maps:find(<<"role">>, Data),

    ?INFO("Editing user data for ~p~n", [Email]),

    {render, <<"user_edit">>, [
            {user, User}, {name, Name}, {email, Email}, 
            {role, Role}, {uuid, UUID}
        ]};

handle_request(<<"POST">>, <<"update">>, _Args, Params, _) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),
    ?DEBUG("Updating user data, PostVals= ~p~n", [PostVals]),

    Name  = proplists:get_value(<<"name">>, PostVals),
    Email = proplists:get_value(<<"email">>, PostVals),
    Role = proplists:get_value(<<"role">>, PostVals),
    Pass1 = proplists:get_value(<<"password">>, PostVals),
    Pass2 = proplists:get_value(<<"password2">>, PostVals),
    UUID = proplists:get_value(<<"uuid">>, PostVals),
    ?INFO("Updating user data for ~p, uuid= ~p~n", [Email, UUID]),

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
            ?INFO("Saving user data for ~p~n", [Email]),
            {ok, User} = mongo_worker:find_one(?DB_USER, {<<"uuid">>, UUID}),
            mongo_worker:update(?DB_USER, User#{
                    <<"password">> := web_util:hash_password(Pass2),
                    <<"name">> := Name
                }),
            {redirect, <<"/adm/users">>}
    end;

handle_request(<<"GET">>, <<"delete">>, [UUID], _Args, _) ->
    % {ok, QsVals} = maps:find(<<"qs_vals">>, Params),
    % Id = proplists:get_value(<<"id">>, QsVals),
    % ?DEBUG("Deleting user ~p~n", [Id]),
    mongo_worker:delete(?DB_USER, {<<"uuid">>, UUID}),
    {redirect, <<"/adm/users">>};

handle_request(_, _, _, _, _) ->
    {redirect, <<"/">>}.

get_user(Params) ->
    case maps:find(<<"auth">>, Params) of
        {ok, User} -> User;
        _          -> undefined
    end.
