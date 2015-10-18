

-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

-define(DEBUG(Text, Args), lager:log(debug, ?MODULE, "~p:~p: " ++ Text, [?MODULE, ?LINE | Args])).
-define(INFO(Text, Args), lager:log(info, ?MODULE, "~p:~p: " ++ Text, [?MODULE, ?LINE | Args])).
-define(ERROR(Text, Args), lager:log(error, ?MODULE, "~p:~p: " ++ Text, [?MODULE, ?LINE | Args])).

-define(SALT, <<"02f40807f3abd51aefb1f77d9d1535cc4e6a12e0">>).
-define(SIZE, 5).

-define(DB_USER, <<"pati_user">>).
-define(DB_CO, <<"pati_co">>).
-define(DB_WORKER, <<"pati_worker">>).

-define(EMAIL, "pati.noreply@gmail.com>").
-define(EPASS, "Lupapul4k!").
