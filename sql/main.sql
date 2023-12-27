-- Default PostgREST OpenAPI Specification

-- This is the one we should be calling
create or replace function callable_root() returns jsonb as $$
  -- Calling this every time is inefficient, but it's the best we can do until PostgREST calls it when it updates the server config
  CALL set_server_from_configuration();
  SELECT get_postgrest_openapi_spec(
    schemas := string_to_array(current_setting('pgrst.db_schemas', TRUE), ','),
    postgrest_version := current_setting('pgrst.version', TRUE),
    proa_version := '0.1'::text, -- TODO: needs to be updated; put into config, and have Makefile update
    document_version := 'unset'::text
  );
$$ language sql;

-- This one returns the OpenAPI JSON; instead of calling it directly, call "callable_root", below
create or replace function get_postgrest_openapi_spec(
  schemas text[],
  postgrest_version text default null,
  proa_version text default null,
  document_version text default null
)
returns jsonb language sql as
$$
select openapi_object(
  openapi := '3.1.0',
  info := openapi_info_object(
    title := coalesce(sd.title, 'PostgREST API'),
    description := coalesce(sd.description, 'This is a dynamic API generated by PostgREST'),
    -- The document version
    version := coalesce(document_version, 'undefined')
  ),
  xsoftware := jsonb_build_array(
    -- The version of the OpenAPI extension
    openapi_x_software_object(
      name := 'OpenAPI',
      version := proa_version,
      description := 'Automatically/dynamically generate an OpenAPI schema for the API generated by PostgREST'
    ),
    -- The version of PostgREST
    openapi_x_software_object(
      name := 'PostgREST API',
      version := postgrest_version,
      description := 'Automatically/dynamically turns a PostgreSQL database directly into a RESTful API'
    )
  ),
  servers := openapi_server_objects(),
  paths := '{}',
  components := openapi_components_object(
    schemas := postgrest_tables_to_openapi_schema_components(schemas) || postgrest_composite_types_to_openapi_schema_components(schemas),
    parameters := postgrest_get_query_params() || postgrest_get_headers(),
    securitySchemes := postgrest_get_security_schemes()
  ),
  security := '[{"JWT": []}]'
)
from postgrest_get_schema_description(schemas[1]) sd;
$$;
