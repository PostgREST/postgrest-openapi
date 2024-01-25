-- defines a default error response
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'responses'->'defaultError');

-- Tables
-- GET operation object

-- defines an application/json response
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'responses'->'get.products'->'content'->'application/json');

-- defines an application/vnd.pgrst.object+json response
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'responses'->'get.products'->'content'->'application/vnd.pgrst.object+json');

-- defines an application/vnd.pgrst.object+json;nulls=stripped response
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'responses'->'get.products'->'content'->'application/vnd.pgrst.object+json;nulls=stripped');

-- defines a text/csv response
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'responses'->'get.products'->'content'->'text/csv');

-- Views
-- GET operation object

select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'responses'->'get.big_products'->'content'->'application/json');

-- defines an application/vnd.pgrst.object+json response
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'responses'->'get.big_products'->'content'->'application/vnd.pgrst.object+json');

-- defines an application/vnd.pgrst.object+json;nulls=stripped response
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'responses'->'get.big_products'->'content'->'application/vnd.pgrst.object+json;nulls=stripped');

-- defines a text/csv response
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'responses'->'get.big_products'->'content'->'text/csv');
