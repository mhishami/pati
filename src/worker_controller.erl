-module(worker_controller).
-export([handle_request/5]).
-export([before_filter/1]).

-include("pati.hrl").

-spec before_filter(binary()) -> {ok, proceed} | {redirect, binary()}.
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

-spec handle_request(binary(), binary(), list(), list(), Req::cowboy_req:req()) -> 
    {render, binary(), list()} | 
    {redirect, binary()} |
    {redirect, binary(), {any(), any()}}.

handle_request(<<"GET">>, <<"new">>, _Args, Params, _) ->
    User = get_user(Params),
    % ?DEBUG("Params = ~p~n", [Params]),
    {ok, Cos} = mongo_worker:find(?DB_CO, {}),

    {render, <<"worker_new">>, [
        {user, User},
        {companies, web_util:maps_to_list(Cos)}
    ]};

handle_request(<<"POST">>, <<"new">>, _Args, Params, _Req) ->
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
                {error, <<"Please check values for Employer, State, Nationality, Sector">>} |
                PostVals
            ]};

        _ ->
            %% save the data

            %% save the worker data
            Worker = maps:from_list(PostVals),
            mongo_worker:save(?DB_WORKER, Worker#{ <<"uuid">> => uuid:gen() }),

            {redirect, <<"/adm/workers">>}
    end;

handle_request(<<"GET">>, <<"edit">>, [UUID], Params, _) ->
    User = get_user(Params),
    % {ok, PostVals} = maps:find(<<"qs_vals">>, Params),
    % RegNo = proplists:get_value(<<"id">>, PostVals),

    % ?DEBUG("Co RegNo= ~p~n", [RegNo]),
    {ok, Worker} = mongo_worker:find_one(?DB_WORKER, {<<"uuid">>, UUID}),
    ?DEBUG("Editing worker, data= ~p~n", [Worker]),
    {ok, Cos} = mongo_worker:find(?DB_CO, {}),
    W = web_util:map_to_list(Worker),

    {render, <<"worker_edit">>, [
        {user, User},
        {companies, web_util:maps_to_list(Cos)},        
        {menu_workers, <<"active">>} | W
    ]};

handle_request(<<"POST">>, <<"update">>, _Args, Params, _Req) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),
    User = get_user(Params),
    ?DEBUG("Worker update, PostVals= ~p~n", [PostVals]),

    Nationality = proplists:get_value(<<"nationality">>, PostVals),
    State = proplists:get_value(<<"state">>, PostVals),
    Employer = proplists:get_value(<<"employer">>, PostVals),
    Sector = proplists:get_value(<<"sector">>, PostVals),
    UUID = proplists:get_value(<<"uuid">>, PostVals),

    %% save the photo if any
    % ?DEBUG("Preparing for saving photos, Req= ~p~n", [Req]),
    % {ok, Headers, Req2} = cowboy_req:part(Req),
    % {ok, Data, _Req3} = cowboy_req:part_body(Req2),
    % {file, <<"photo">>, Filename, ContentType, _TE}
    %     = cow_multipart:form_data(Headers),
    % ?INFO("Received file ~p of content-type ~p as follow:~n~p~n~n",
    %     [Filename, ContentType, Data]),

    case State =:= <<"--">> orelse 
         Nationality =:= <<"--">> orelse 
         Employer =:= <<"--">> orelse 
         Sector =:= undefined of
        true ->
            %% ok, error in forms
            {ok, Cos} = mongo_worker:find(?DB_CO, {}),
            ?DEBUG("Error in req values, Cos= ~p~n", [Cos]),
            {render, <<"worker_edit">>, [
                {user, User},
                {companies, web_util:maps_to_list(Cos)},
                {error, <<"Please check values for Employer, State, Nationality, Sector">>},
                {menu_workers, <<"active">>} | PostVals
            ]};

        _ ->
            %% save the data

            %% save the worker data
            {ok, W} = mongo_worker:find_one(?DB_WORKER, {<<"uuid">>, UUID}),
            ?DEBUG("W= ~p~n", [W]),

            Worker = maps:from_list(PostVals),
            MergedWorker = maps:merge(W, Worker),
            ?DEBUG("MergedWorker= ~p~n", [MergedWorker]),
            mongo_worker:update(?DB_WORKER, MergedWorker),

            {redirect, <<"/adm/workers">>}
    end;

handle_request(<<"GET">>, <<"delete">>, [UUID], _, _) ->
    mongo_worker:delete(?DB_WORKER, {<<"uuid">>, UUID}),
    {redirect, <<"/adm/workers">>};

handle_request(<<"GET">>, <<"upload">>, [Oid], Params, _) ->
    User = get_user(Params),
    {render, <<"upload">>, [
        {user, User}, {oid, Oid}
    ]};

handle_request(<<"POST">>, <<"upload">>, [<<"do">>, UUID], Params, _Req) ->  
    ?DEBUG("Processing photo upload...~n", []),  
    {ok, [Upload]} = maps:find(<<"files">>, Params),

    {ok, Type} = maps:find(<<"content-type">>, Upload),
    {ok, Data} = maps:find(<<"data">>, Upload),

    %% save the file
    % os:cmd("mkdir -p " ++ code:priv_dir(pati) ++ "/static/photos"),
    Filename =  case Type of
                    <<"image/jpeg">> -> 
                        << UUID/binary, <<".jpg">>/binary >>;
                    <<"image/png">> -> 
                        << UUID/binary, <<".png">>/binary >>
                end,

    file:write_file(code:priv_dir(pati) ++ "/static/photos/" ++ 
        erlang:binary_to_list(Filename), Data),

    %% update user data
    {ok, Worker} = mongo_worker:find_one(?DB_WORKER, {<<"uuid">>, UUID}),
    mongo_worker:update(?DB_WORKER, Worker#{ <<"photo">> => Filename}),

    ?DEBUG("Photo= ~p, Type= ~p~n", [Filename, Type]),
    {redirect, <<"/adm/workers">>};

handle_request(_, _, _, _, _) ->
    {redirect, <<"/">>}.

get_user(Params) ->
    case maps:find(<<"auth">>, Params) of
        {ok, User} -> User;
        _          -> undefined
    end.

% multipart(Req) ->
%     case cowboy_req:part(Req) of
%         {ok, _Headers, Req2} ->
%             {ok, _Body, Req3} = cowboy_req:part_body(Req2),
%             multipart(Req3);
%         {done, Req2} ->
%             Req2
%     end.
