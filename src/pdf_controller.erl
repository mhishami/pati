-module(pdf_controller).
-author ('Hisham Ismail <mhishami@gmail.com').

-export([handle_request/5]).
-export([before_filter/1]).

-include("pati.hrl").

before_filter(_) ->
    %% do some checking
    {ok, proceed}.

handle_request(<<"GET">>, <<"worker">>, Args, Params, _Req) ->   
    ?DEBUG("Args= ~p, Params= ~p~n", [Args, Params]),
    {ok, QsVals} = maps:find(<<"qs_vals">>, Params),
    Uuid = proplists:get_value(<<"uuid">>, QsVals),

    {ok, Data} = mongo_worker:find_one(?DB_WORKER, {<<"uuid">>, Uuid}),
    % User = get_user(Params),
    {render, <<"pdf_worker">>, web_util:map_to_list(Data)};

handle_request(_, _, _, _, _) ->
    {redirect, <<"/">>}.

