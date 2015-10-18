-module(pdf_controller).
-author ('Hisham Ismail <mhishami@gmail.com').

-export([handle_request/5]).
-export([before_filter/1]).

-include("pati.hrl").

-spec before_filter(binary()) -> {ok, proceed} | {redirect, binary()}.
before_filter(_) ->
    %% do some checking
    {ok, proceed}.

-spec handle_request(binary(), binary(), list(), list(), list()) -> 
    {render, binary(), list()} | 
    {redirect, binary()} |
    {redirect, binary(), {any(), any()}}.

handle_request(<<"GET">>, <<"user">>, [Oid], _, _Req) ->   
    % ?DEBUG("Args= ~p, Params= ~p~n", [Args, Params]),
    % {ok, QsVals} = maps:find(<<"qs_vals">>, Params),
    % Uuid = proplists:get_value(<<"id">>, QsVals),

    {ok, Data} = mongo_worker:find_one(?DB_USER, {<<"oid">>, Oid}),
    % User = get_user(Params),
    {render, <<"pdf_user">>, [
        {nationality, <<"Malaysian">>},
        {sex_female, <<"X">>},
        {dob_dd, <<"22">>}, {dob_mm, <<"05">>}, {dob_yy, <<"1973">>},
        {phone, <<"0192933165">>}
    |web_util:map_to_list(Data)]};

handle_request(<<"GET">>, <<"gen">>, [<<"user">>, Oid], _, _Req) ->   
    % {ok, QsVals} = maps:find(<<"qs_vals">>, Params),
    % E = proplists:get_value(<<"id">>, QsVals),
    % Email = erlang:binary_to_list(E),
    % F = web_util:hash_password(E),
    Filename = erlang:binary_to_list(Oid),

    Cmd = "wkhtmltopdf http://localhost:8080/pdf/user/" ++ erlang:binary_to_list(Oid) ++ " "
            ++ code:priv_dir(pati) ++ "/static/pdfs/" ++ Filename ++ ".pdf",

    ?DEBUG("Command= ~p~n", [Cmd]),
    os:cmd(Cmd),
    {redirect, << <<"/static/pdfs/">>/binary, Oid/binary, <<".pdf">>/binary >>};

handle_request(<<"GET">>, <<"worker">>, [Oid], _, _Req) ->   

    {ok, Data} = mongo_worker:find_one(?DB_WORKER, {<<"oid">>, Oid}),
    % User = get_user(Params),
    Worker = web_util:map_to_list(Data),
    BD = proplists:get_value(<<"birthdate">>, Worker),
    [DD, MM, YY] = string:tokens(erlang:binary_to_list(BD), "/"),

    %% find co
    {ok, Co} = mongo_worker:find_one(?DB_CO, 
        {<<"oid">>, proplists:get_value(<<"employer">>, Worker)}),
    Company = web_util:map_to_list(Co),

    % {ok,[#{<<"_id">> => {<<86,34,111,194,234,83,216,103,99,0,0,2>>},
    %        <<"address">> => <<"Jalan Cheras">>,
    %        <<"dir1name">> => <<"Cheng Hong Koo">>,
    %        <<"dir1phone">> => <<"0196622165">>,
    %        <<"dir2name">> => <<>>,
    %        <<"dir2phone">> => <<>>,
    %        <<"email">> => <<"mhishami@gmail.com">>,
    %        <<"name">> => <<"Tenco Industries">>,
    %        <<"oid">> => <<"J76nEZ">>,
    %        <<"phone">> => <<"03 9200 9010">>,
    %        <<"postcode">> => <<"55200">>,
    %        <<"regno">> => <<"758867-V">>,
    %        <<"state">> => <<"WP Kuala Lumpur">>,
    %        <<"type">> => <<"sdn bhd">>}]}
    % (pati@127.0.0.1)5> 

    {render, <<"pdf_worker">>, [
        case proplists:get_value(<<"gender">>, Worker) of
            <<"male">> -> {sex_male, <<"checked">>};
            _          -> {sex_female, <<"checked">>}
        end,
        case proplists:get_value(<<"passport">>, Worker) of
            <<"yes">>  -> {pass_yes, <<"checked">>};
            _          -> {pass_no, <<"checked">>}
        end,
        case proplists:get_value(<<"sector">>, Worker) of
            <<"Manufacturing">> -> {sect_mfg, <<"checked">>};
            <<"Agriculture">> -> {sect_agr, <<"checked">>};
            <<"Services">> -> {sect_svc, <<"checked">>};
            <<"Construction">> -> {sect_con, <<"checked">>};
            <<"Plantation">> -> {sect_plt, <<"checked">>};
            _  -> {dunno, <<"X">>}
        end,
        case proplists:get_value(<<"type">>, Company) of
            <<"sdn bhd">>    -> {co_sdn, <<"checked">>};
            <<"bhd">>        -> {co_bhd, <<"checked">>};
            <<"enterprise">> -> {co_ent, <<"checked">>}
        end,
        {co_name, proplists:get_value(<<"name">>, Company)},
        {co_regno, proplists:get_value(<<"regno">>, Company)},
        {co_address, proplists:get_value(<<"address">>, Company)},
        {co_state, proplists:get_value(<<"state">>, Company)},
        {co_postcode, proplists:get_value(<<"postcode">>, Company)},

        {dir1_name, proplists:get_value(<<"dir1name">>, Company)},
        {dir1_phone, proplists:get_value(<<"dir1phone">>, Company)},
        {dir2_name, proplists:get_value(<<"dir2name">>, Company)},
        {dir2_phone, proplists:get_value(<<"dir2phone">>, Company)},

        {co_phone, proplists:get_value(<<"phone">>, Company)},
        {co_email, proplists:get_value(<<"email">>, Company)},

        { dob_dd, DD}, {dob_mm, MM}, {dob_yy, YY}
    | Worker]};

handle_request(<<"GET">>, <<"gen">>, [<<"worker">>, Oid], _, _Req) ->   
    % {ok, QsVals} = maps:find(<<"qs_vals">>, Params),
    % E = proplists:get_value(<<"id">>, QsVals),
    % Email = erlang:binary_to_list(E),
    % F = web_util:hash_password(E),
    Filename = erlang:binary_to_list(Oid),

    Cmd = "wkhtmltopdf http://localhost:8080/pdf/worker/" ++ erlang:binary_to_list(Oid) ++ " "
            ++ code:priv_dir(pati) ++ "/static/pdfs/" ++ Filename ++ ".pdf",

    ?DEBUG("Command= ~p~n", [Cmd]),
    os:cmd(Cmd),
    {redirect, << <<"/static/pdfs/">>/binary, Oid/binary, <<".pdf">>/binary >>};

handle_request(_, _, _, _, _) ->
    {redirect, <<"/">>}.

