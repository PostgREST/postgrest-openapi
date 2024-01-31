-- defines a default error response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'defaultError');

-- defines an empty response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'empty');

-- Tables
-- Non-empty response body

-- defines an application/json response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'notEmpty.products'->'content'->'application/json');

-- defines an application/vnd.pgrst.object+json response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'notEmpty.products'->'content'->'application/vnd.pgrst.object+json');

-- defines an application/vnd.pgrst.object+json;nulls=stripped response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'notEmpty.products'->'content'->'application/vnd.pgrst.object+json;nulls=stripped');

-- defines a text/csv response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'notEmpty.products'->'content'->'text/csv');

-- Empty or non-empty response body

-- defines an application/json response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'mayBeEmpty.products'->'content'->'application/json');

-- defines an application/vnd.pgrst.object+json response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'mayBeEmpty.products'->'content'->'application/vnd.pgrst.object+json');

-- defines an application/vnd.pgrst.object+json;nulls=stripped response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'mayBeEmpty.products'->'content'->'application/vnd.pgrst.object+json;nulls=stripped');

-- defines a text/csv response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'mayBeEmpty.products'->'content'->'text/csv');

-- Views
-- Non-empty response body

select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'notEmpty.big_products'->'content'->'application/json');

-- defines an application/vnd.pgrst.object+json response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'notEmpty.big_products'->'content'->'application/vnd.pgrst.object+json');

-- defines an application/vnd.pgrst.object+json;nulls=stripped response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'notEmpty.big_products'->'content'->'application/vnd.pgrst.object+json;nulls=stripped');

-- defines a text/csv response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'notEmpty.big_products'->'content'->'text/csv');

-- defines a non-empty response body for non auto-updatable views
select postgrest_openapi_spec('{test}')->'components'->'responses' ? 'notEmpty.non_auto_updatable' as value;

-- Empty or non-empty response body

-- defines an application/json response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'mayBeEmpty.big_products'->'content'->'application/json');

-- defines an application/vnd.pgrst.object+json response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'mayBeEmpty.big_products'->'content'->'application/vnd.pgrst.object+json');

-- defines an application/vnd.pgrst.object+json;nulls=stripped response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'mayBeEmpty.big_products'->'content'->'application/vnd.pgrst.object+json;nulls=stripped');

-- defines a text/csv response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'mayBeEmpty.big_products'->'content'->'text/csv');

-- does not define an empty or non-empty response body for non auto-updatable views
select postgrest_openapi_spec('{test}')->'components'->'responses' ? 'mayBeEmpty.non_auto_updatable' as value;
