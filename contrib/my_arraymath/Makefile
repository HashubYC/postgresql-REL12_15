EXTENSION = my_arraymath
MODULE_big = $(EXTENSION)
OBJS = my_arraymath.o
REGRESS = my_arraymath

# $(wildcard *--*.sql)
DATA = $(wildcard *--*.sql)



PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

