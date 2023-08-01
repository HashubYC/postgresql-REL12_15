EXTENSION = my_arraymath
MODULE_big = $(EXTENSION)
OBJS = my_arraymath.o
REGRESS = my_arraymath
EXTRA_CLEAN =

DATA = my_arraymath--0.0.1.sql 


PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

