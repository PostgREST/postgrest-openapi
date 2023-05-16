-- Default PostgREST OpenAPI Specification

create or replace function get_postgrest_openapi_spec()
returns jsonb language sql as
$$
select openapi_object(
  openapi := '3.1.0',
  info := openapi_info_object(
    title := 'PostgREST API',
    version := '11.0.1 (4197d2f)'
  ),
  paths := '{}',
  components := openapi_components_object(
    schemas := postgrest_tables_to_openapi_schema_components('{api}')
  )
);
$$;
