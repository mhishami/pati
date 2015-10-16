-module(pdf_controller).
-author ('Hisham Ismail <mhishami@gmail.com').

-export([handle_request/5]).
-export([before_filter/1]).

-include("pati.hrl").

before_filter(_) ->
    %% do some checking
    {ok, proceed}.

handle_request(<<"GET">>, <<"user">>, Args, Params, _Req) ->   
    ?DEBUG("Args= ~p, Params= ~p~n", [Args, Params]),
    {ok, QsVals} = maps:find(<<"qs_vals">>, Params),
    Uuid = proplists:get_value(<<"id">>, QsVals),

    {ok, Data} = mongo_worker:find_one(?DB_USER, {<<"email">>, Uuid}),
    % User = get_user(Params),
    {render, <<"pdf_user">>, [
        {nationality, <<"Malaysian">>},
        {sex_female, <<"X">>},
        {dob_dd, <<"22">>}, {dob_mm, <<"05">>}, {dob_yy, <<"1973">>},
        {phone, <<"0192933165">>}
    |web_util:map_to_list(Data)]};

handle_request(<<"GET">>, <<"gen">>, [<<"user">>], Params, _Req) ->   
    {ok, QsVals} = maps:find(<<"qs_vals">>, Params),
    E = proplists:get_value(<<"id">>, QsVals),
    Email = erlang:binary_to_list(E),
    F = web_util:hash_password(E),
    Filename = erlang:binary_to_list(F),
    ?DEBUG("Email= ~p, Filename= ~p~n", [Email, Filename]),

    Cmd = "wkhtmltopdf http://localhost:8080/pdf/user?id=" ++ Email 
            ++ " lib/pati-0.1/priv/static/pdfs/" ++ Filename ++ ".pdf",

    ?DEBUG("Command= ~p~n", [Cmd]),
    os:cmd(Cmd),
    {redirect, << <<"/static/pdfs/">>/binary, F/binary, <<".pdf">>/binary >>};

handle_request(<<"GET">>, <<"worker">>, Args, Params, _Req) ->   
    ?DEBUG("Args= ~p, Params= ~p~n", [Args, Params]),
    {ok, QsVals} = maps:find(<<"qs_vals">>, Params),
    Uuid = proplists:get_value(<<"uuid">>, QsVals),

    {ok, Data} = mongo_worker:find_one(?DB_WORKER, {<<"uuid">>, Uuid}),
    % User = get_user(Params),
    {render, <<"pdf_worker">>, web_util:map_to_list(Data)};

handle_request(_, _, _, _, _) ->
    {redirect, <<"/">>}.

