
PROJECT = pati
DEPS = tuah gen_smtp eunit_formatters

dep_tuah = git https://github.com/mhishami/tuah master
dep_gen_smtp = git https://github.com/Vagabond/gen_smtp.git master

ERLC_OPTS ?= -Werror +debug_info +warn_export_all +warn_export_vars \
    +warn_shadow_vars +warn_obsolete_guard +warn_missing_spec

include erlang.mk
