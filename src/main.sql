-- Default PostgREST OpenAPI Specification

create or replace function get_postgrest_openapi_spec(
  schemas text[],
  server_proxy_uri text default 'http://0.0.0.0:3000'
)
returns jsonb language sql as
$$
select openapi_object(
  openapi := '3.1.0',
  info := openapi_info_object(
    title := 'PostgREST API',
    version := '11.0.1 (4197d2f)'
  ),
  servers := jsonb_build_array(
    openapi_server_object(
      url := server_proxy_uri
    )
  ),
  paths := '{}',
  components := openapi_components_object(
    schemas := postgrest_tables_to_openapi_schema_components(schemas) || postgrest_composite_types_to_openapi_schema_components(schemas)
  )
);
$$;
