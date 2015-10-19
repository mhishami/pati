-module(co_controller).
-author ('Hisham Ismail <mhishami@gmail.com').

-export ([handle_request/5]).
-export ([before_filter/1]).

-include("pati.hrl").

-spec before_filter(binary()) -> {ok, proceed} | {redirect, binary()}.
before_filter(SessionId) ->
    %% do some checking
    Sid = session_worker:get_cookies(SessionId),
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
    {render, <<"co_new">>, [
        {user, User}
    ]};

handle_request(<<"POST">>, <<"new">>, _Args, Params, _) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),

    Company = maps:from_list(PostVals),
    mongo_worker:save(?DB_CO, Company#{ <<"uuid">> => uuid:gen() }),
    {redirect, <<"/adm/cos">>};

handle_request(<<"GET">>, <<"edit">>, [UUID], Params, _) ->
    User = get_user(Params),
    % {ok, PostVals} = maps:find(<<"qs_vals">>, Params),
    % RegNo = proplists:get_value(<<"id">>, PostVals),

    % ?DEBUG("Co RegNo= ~p~n", [RegNo]),
    {ok, Company} = mongo_worker:find_one(?DB_CO, {<<"uuid">>, UUID}),
    {render, <<"co_edit">>, [
        {user, User} | web_util:map_to_list(Company)
    ]};

handle_request(<<"POST">>, <<"update">>, _Args, Params, _) ->
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
            {render, <<"co_edit">>, [
                {user, User},
                {error, <<"Please select state">>},
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

handle_request(<<"GET">>, <<"delete">>, [UUID], _, _) ->
    % {ok, PostVals} = maps:find(<<"qs_vals">>, Params),
    % Id = proplists:get_value(<<"id">>, PostVals),

    % ?DEBUG("Deleting Company ~p~n", [Id]),
    mongo_worker:delete(?DB_CO, {<<"uuid">>, UUID}),
    {redirect, <<"/adm/cos">>};

handle_request(_, _, _, _, _) ->
    {redirect, <<"/">>}.

get_user(Params) ->
    case maps:find(<<"auth">>, Params) of
        {ok, User} -> User;
        _          -> undefined
    end.
