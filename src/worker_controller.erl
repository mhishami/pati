-module(worker_controller).
-export([handle_request/5]).
-export([before_filter/1]).

-include("pati.hrl").

before_filter(SessionId) ->
    %% do some checking
    Sid = session_worker:get_cookies(SessionId),
    ?DEBUG("Sid = ~p, SessionId= ~p~n", [Sid, SessionId]),
    case Sid of
        {error, undefined} ->
            {redirect, <<"/auth/login">>};
        _ ->
            {ok, proceed}
    end.

handle_request(<<"GET">>, <<"new">>, _Args, Params, _) ->
    User = get_user(Params),
    % ?DEBUG("Params = ~p~n", [Params]),
    {ok, Cos} = mongo_worker:find(?DB_CO, {}),

    {render, <<"worker_new">>, [
        {user, User},
        {companies, web_util:maps_to_list(Cos)},
        {menu_workers, <<"active">>}
    ]};

handle_request(<<"POST">>, <<"new">>, _Args, Params, _) ->
    ?DEBUG("Saving new worker, Params= ~p~n", [Params]),
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),
    User = get_user(Params),

    %% validate forms
    Nationality = proplists:get_value(<<"nationality">>, PostVals),
    State = proplists:get_value(<<"state">>, PostVals),
    Employer = proplists:get_value(<<"employer">>, PostVals),
    Sector = proplists:get_value(<<"sector">>, PostVals),

    ?DEBUG("Nat= ~p, State= ~p, Employer= ~p~n", [Nationality, State, Employer]),
    case State =:= <<"--">> orelse 
         Nationality =:= <<"--">> orelse 
         Employer =:= <<"--">> orelse 
         Sector =:= undefined of
        true ->
            %% ok, error in forms
            {ok, Cos} = mongo_worker:find(?DB_CO, {}),
            ?DEBUG("Error in req values, Cos= ~p~n", [Cos]),
            {render, <<"worker_new">>, [
                {user, User},
                {companies, web_util:maps_to_list(Cos)},
                {error, <<"Please check values for Employer, State, Nationality, Sector">>},
                {menu_workers, <<"active">>} | PostVals
            ]};

        _ ->
            %% save the data

            %% save the worker data
            Worker = maps:from_list(PostVals),
            mongo_worker:save(?DB_WORKER, Worker#{ <<"oid">> => word_util:gen_pnr() }),

            {redirect, <<"/adm/workers">>}
    end;

handle_request(<<"GET">>, <<"edit">>, [Oid], Params, _) ->
    User = get_user(Params),
    % {ok, PostVals} = maps:find(<<"qs_vals">>, Params),
    % RegNo = proplists:get_value(<<"id">>, PostVals),

    % ?DEBUG("Co RegNo= ~p~n", [RegNo]),
    {ok, Worker} = mongo_worker:find_one(?DB_WORKER, {<<"oid">>, Oid}),
    {ok, Cos} = mongo_worker:find(?DB_CO, {}),
    W = web_util:map_to_list(Worker),

    {render, <<"worker_edit">>, [
        case proplists:get_value(<<"gender">>, W) of
            <<"male">> -> {sex_male, <<"checked">>};
            _          -> {sex_female, <<"checked">>}
        end,
        case proplists:get_value(<<"passport">>, W) of
            <<"yes">> -> {pass_yes, <<"checked">>};
            _         -> {pass_no, <<"checked">>}
        end,
        {user, User},
        {companies, web_util:maps_to_list(Cos)},        
        {menu_workers, <<"active">>} | W
    ]};

handle_request(<<"POST">>, <<"update">>, _Args, Params, _) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),
    User = get_user(Params),

    Nationality = proplists:get_value(<<"nationality">>, PostVals),
    State = proplists:get_value(<<"state">>, PostVals),
    Employer = proplists:get_value(<<"employer">>, PostVals),
    Sector = proplists:get_value(<<"sector">>, PostVals),
    Oid = proplists:get_value(<<"oid">>, PostVals),

    case State =:= <<"--">> orelse 
         Nationality =:= <<"--">> orelse 
         Employer =:= <<"--">> orelse 
         Sector =:= undefined of
        true ->
            %% ok, error in forms
            {ok, Cos} = mongo_worker:find(?DB_CO, {}),
            ?DEBUG("Error in req values, Cos= ~p~n", [Cos]),
            {render, <<"worker_new">>, [
                {user, User},
                {companies, web_util:maps_to_list(Cos)},
                {error, <<"Please check values for Employer, State, Nationality, Sector">>},
                {menu_workers, <<"active">>} | PostVals
            ]};

        _ ->
            %% save the data

            %% save the worker data
            ?DEBUG("Updating worker data, Oid =~p~n", [Oid]),
            {ok, W} = mongo_worker:find_one(?DB_WORKER, {<<"oid">>, Oid}),
            ?DEBUG("W= ~p~n", [W]),

            Worker = maps:from_list(PostVals),
            MergedWorker = maps:merge(W, Worker),
            ?DEBUG("MergedWorker= ~p~n", [MergedWorker]),
            mongo_worker:update(?DB_WORKER, MergedWorker),

            {redirect, <<"/adm/workers">>}
    end;

handle_request(<<"GET">>, <<"delete">>, [Oid], _, _) ->
    mongo_worker:delete(?DB_WORKER, {<<"oid">>, Oid}),
    {redirect, <<"/adm/workers">>};

handle_request(_, _, _, _, _) ->
    {redirect, <<"/">>}.

get_user(Params) ->
    case maps:find(<<"auth">>, Params) of
        {ok, User} -> User;
        _          -> undefined
    end.
