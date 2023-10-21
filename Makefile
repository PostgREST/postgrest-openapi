EXTENSION = postgrest_openapi
EXTVERSION = 0.0.1

DATA = $(wildcard sql/*--*.sql)

TESTS = $(wildcard test/sql/*.sql)
REGRESS = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = --use-existing --inputdir=test

all: sql/$(EXTENSION)--$(EXTVERSION).sql $(EXTENSION).control

sql/$(EXTENSION).sql:
	cat sql/*.sql > $@

sql/$(EXTENSION)--$(EXTVERSION).sql: sql/$(EXTENSION).sql
	cp $< $@

$(EXTENSION).control:
	sed "s/@EXTVERSION@/$(EXTVERSION)/g" $(EXTENSION).control.in > $(EXTENSION).control

EXTRA_CLEAN = sql/$(EXTENSION).sql sql/$(EXTENSION)--$(EXTVERSION).sql $(EXTENSION).control

PG_CONFIG = pg_config

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
