-module(co_controller).
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

handle_request(<<"GET">>, <<"new">>, _Args, Params, _) ->
    User = get_user(Params),
    {render, <<"co_new">>, [
        {user, User},
        {menu_cos, <<"active">>}
    ]};

handle_request(<<"POST">>, <<"new">>, _Args, Params, _) ->
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
    mongo_worker:save(?DB_CO, Company#{ <<"oid">> => word_util:gen_pnr() }),
    {redirect, <<"/adm/cos">>};

handle_request(<<"GET">>, <<"edit">>, [Oid], Params, _) ->
    User = get_user(Params),
    % {ok, PostVals} = maps:find(<<"qs_vals">>, Params),
    % RegNo = proplists:get_value(<<"id">>, PostVals),

    % ?DEBUG("Co RegNo= ~p~n", [RegNo]),
    {ok, Company} = mongo_worker:find_one(?DB_CO, {<<"oid">>, Oid}),
    {ok, Type} = maps:find(<<"type">>, Company),
    {render, <<"co_edit">>, [
        {user, User},
        case Type of
            <<"bhd">> -> {check_bhd, <<"checked">>};
            <<"sdn bhd">> -> {check_sdnbhd, <<"checked">>};
            <<"enterprise">> -> {check_ent, <<"checked">>}
        end,                
        {menu_cos, <<"active">>}|
        web_util:map_to_list(Company)
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

handle_request(<<"GET">>, <<"delete">>, [Oid], _, _) ->
    % {ok, PostVals} = maps:find(<<"qs_vals">>, Params),
    % Id = proplists:get_value(<<"id">>, PostVals),

    % ?DEBUG("Deleting Company ~p~n", [Id]),
    mongo_worker:delete(?DB_CO, {<<"oid">>, Oid}),
    {redirect, <<"/adm/cos">>};

handle_request(_, _, _, _, _) ->
    {redirect, <<"/">>}.

get_user(Params) ->
    case maps:find(<<"auth">>, Params) of
        {ok, User} -> User;
        _          -> undefined
    end.
