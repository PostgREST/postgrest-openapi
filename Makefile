EXTENSION = postgrest_openapi
EXTVERSION = 0.0.1

DATA = $(wildcard sql/*--*.sql)

all: sql/$(EXTENSION)--$(EXTVERSION).sql $(EXTENSION).control

sql/$(EXTENSION).sql:
	cat sql/*.sql > $@

sql/$(EXTENSION)--$(EXTVERSION).sql: sql/$(EXTENSION).sql
	cp $< $@

$(EXTENSION).control:
	sed "s/@EXTVERSION@/$(EXTVERSION)/g" $(EXTENSION).control.in > $(EXTENSION).control

.PHONY: fixtures
fixtures:
	createdb contrib_regression
	psql -v ON_ERROR_STOP=1 -f test/fixtures.sql -d contrib_regression

.PHONY: clean_fixtures
clean_fixtures:
	dropdb --if-exists contrib_regression

# extra dep for PostgreSQL targets in pgxs.mk
clean: clean_fixtures

# Docker stuff
DOCKER_COMPOSE_COMMAND_TESTS=docker-compose --file hosting/tests/docker-compose.yml --project-directory .
DOCKER_COMPOSE_COMMAND_FINAL=docker-compose --file hosting/final/docker-compose.yml --project-directory .
docker-build-test:
	$(DOCKER_COMPOSE_COMMAND_TESTS) build
	$(DOCKER_COMPOSE_COMMAND_TESTS) down --remove-orphans
	$(DOCKER_COMPOSE_COMMAND_TESTS) up -d
	sleep 3
	docker logs postgrest-openapi_postgrest-openapi-build_1
docker-build: docker-build-test
	$(DOCKER_COMPOSE_COMMAND_FINAL) build
	$(DOCKER_COMPOSE_COMMAND_FINAL) down --remove-orphans
	$(DOCKER_COMPOSE_COMMAND_FINAL) up -d

# Postgres stuff
TESTS = $(wildcard test/sql/*.sql)
REGRESS = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = --use-existing --inputdir=test --outputdir=output

EXTRA_CLEAN = sql/$(EXTENSION).sql sql/$(EXTENSION)--$(EXTVERSION).sql $(EXTENSION).control

PG_CONFIG = pg_config

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
