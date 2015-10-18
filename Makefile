PROJECT = pati
DEPS = tuah gen_smtp

dep_tuah = git https://github.com/mhishami/tuah master
dep_gen_smtp = git https://github.com/Vagabond/gen_smtp.git master

include erlang.mk
