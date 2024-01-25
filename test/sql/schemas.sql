-- detects tables as objects
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'products'->'type');

-- detects columns with enum types as an enum property
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'products'->'properties'->'size');

-- references a composite type column from a table to a component definition
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'products'->'properties'->'attr');

-- identifies the required columns
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'products'->'required');

-- detects comments done on a table and shows it as description
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'products'->'description');

-- detects comments done on a table column and shows it as description
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'products'->'properties'->'id'->'description');

-- maps sql types to OpenAPI types correctly
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'openapi_types');

-- does not show tables outside the exposed schema
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'secret_table');

-- detects composite types as objects
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'types.attribute'->'type');

-- references a composite type column from another composite type to a component definition
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'types.attribute'->'properties'->'dim');

-- detects a composite type inside another composite type
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'types.dimension');

-- detects an array composite type inside another composite type
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'types.color');

-- does not show a composite type that is not used by an exposed table
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'types.hiddentype');

-- detects comments done on a composite type and shows it as description
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'types.attribute'->'description');

-- detects comments done on a composite type column and shows it as description
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'types.attribute'->'properties'->'other'->'description');

-- references a composite type column from an array composite type inside the items property
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'schemas'->'types.attribute'->'properties'->'colors'->'items');

-- defines all the available prefer headers
select key, jsonb_pretty(value)
from jsonb_each(get_postgrest_openapi_spec('{test}')->'components'->'schemas')
where key like 'header.prefer%';
