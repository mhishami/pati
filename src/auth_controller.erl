-module(auth_controller).
-author ('Hisham Ismail <mhishami@gmail.com').

-export ([handle_request/5]).
-export ([before_filter/1]).

-export ([send_email/2]).

-include("pati.hrl").

before_filter(_) ->
    {ok, proceed}.

handle_request(<<"GET">>, <<"login">>, _, _, _) ->
    {render, <<"auth_login">>, []};

handle_request(<<"POST">>, <<"login">>, _, Params, _) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),
    Email = proplists:get_value(<<"email">>, PostVals, <<"">>),
    Password = proplists:get_value(<<"password">>, PostVals, <<"">>),
    ?DEBUG("Email= ~p, Password= ~p~n", [Email, Password]),

    %% get session id
    {ok, Sid} = maps:find(<<"sid">>, Params),

    Res = mongo_worker:find_one(?DB_USER, {<<"email">>, Email}),
    ?DEBUG("Db Result = ~p~n", [Res]),
    case Res of
        {error, not_found} ->
            %% redirect to registration
            {redirect, <<"/">>};
        {ok, Data} ->
            %% validate user
            case authenticate(Password, Data) of
                ok ->
                    %% set session, and cookies etc.
                    {ok, success} = session_worker:set_cookies(Sid, Email),
                    ?DEBUG("Session data: Sid=~p, Email= ~p, SessionWorker= ~p~n", 
                        [Sid, Email, session_worker:get_cookies(Sid)]),
                    {redirect, <<"/adm">>, {cookie, <<"auth">>, Email}};
                error ->
                    {render, <<"auth_login">>, [
                            {error, "Username, or password is invalid"},
                            {email, Email}
                    ]}
            end
    end;

handle_request(<<"GET">>, <<"logout">>, _, Params, _) ->
    {ok, Sid} = maps:find(<<"sid">>, Params),
    session_worker:del_cookies(Sid),
    {redirect, <<"/">>};

handle_request(<<"GET">>, <<"forgot">>, _Args, _Params, _Req) ->
    {render, <<"auth_forgot">>, []};
  
handle_request(<<"POST">>, <<"forgot">>, _Args, Params, _Req) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),
    Email = proplists:get_value(<<"email">>, PostVals),

    %% set new password
    case mongo_worker:find_one(?DB_USER, {<<"email">>, Email}) of
        {ok, User} ->
            %% reset the password
            P1 = word_util:gen_pnr(),
            ?DEBUG("New Password= ~p~n", [P1]),

            Pass = web_util:hash_password(P1),
            mongo_worker:update(?DB_USER, User#{ <<"password">> := Pass }),

            %% send email
            send_email(Email, P1),

            {render, <<"auth_login">>, [
                {error, "Please check your email for your new password"},
                {email, Email}
            ]};
        _ ->
            {render, <<"auth_forgot">>, [
                {error, "Sorry, no user by such email."}
            ]}
    end;

handle_request(<<"POST">>, <<"register">>, _Args, Params, _Req) ->
    {ok, PostVals} = maps:find(<<"qs_body">>, Params),

    Name = proplists:get_value(<<"name">>, PostVals),
    Email = proplists:get_value(<<"email">>, PostVals),
    Password = proplists:get_value(<<"password">>, PostVals),
    Password2 = proplists:get_value(<<"password2">>, PostVals),
    Page = <<"auth_register">>,

    case Password =/= Password2 orelse
         size(Password) =:= 0 orelse
         size(Name) =:= 0 orelse
         size(Email) =:= 0 of
        true ->
            %% passwords are not the same
            {render, Page, [
                {name, Name},
                {email, Email},
                {error, "Opps! All fields are required. Also, make sure all passwords are the same"}
            ]};
        _ ->
            %% save the user
            User = #{<<"name">> => Name, 
                     <<"email">> => Email, 
                     <<"password">> => web_util:hash_password(Password)},
            ?DEBUG("Page= ~p, User = ~p~n", [Page, User]),
            case mongo_worker:save(?DB_USER, User) of
                {ok, _} ->
                    {redirect, <<"/adm/users">>};
                _ ->
                    {render, Page, [
                        {name, Name},
                        {email, Email},
                        {error, "Cannot save user data. Pls come again!"}
                    ]}
            end

    end;

handle_request(_Method, _Action, _Args, _Params, _Req) ->    
    %% / will render home.dtl
    {redirect, <<"/">>}.

%% ----------------------------------------------------------------------------
%% Private funs
%%
authenticate(Password, Data) ->
    HashPass = web_util:hash_password(Password),
    Pass = maps:get(<<"password">>, Data),
    ?DEBUG("Pass= ~p, HashPass= ~p~n", [Pass, HashPass]),
    case HashPass =:= Pass of
        true -> ok;
        _    -> error
    end.

send_email(E, Password) ->
    Email = erlang:binary_to_list(E),
    ?DEBUG("Sending email to ~p~n", [Email]),


    gen_smtp_client:send({Email, [Email], 
        unicode:characters_to_binary(
            "Subject: Forgot Password\r\n" ++
            "From: PATI Noreply <pati.noreply@gmail.com> \r\n" ++
            "To: " ++ Email ++ " \r\n\r\n" ++
            "Bummer! No worries, your new password: " ++ erlang:binary_to_list(Password)
        )}, 
        [{relay, "smtp.gmail.com"}, 
         {ssl, true}, 
         {username, "pati.noreply@gmail.com"}, 
         {password, "Lupapul4k!"}]).


