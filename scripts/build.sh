POSTGREST_OPENAPI_VERSION="0.1";

cat \
    src/utils.sql \
    src/openapi.sql \
    src/postgrest.sql \
    src/main.sql \
    > sql/postgrest_openapi--$POSTGREST_OPENAPI_VERSION.sql;
