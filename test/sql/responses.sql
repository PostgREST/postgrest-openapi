-- defines a default error response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'defaultError');

-- Tables
-- GET operation object

-- defines an application/json response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'get.products'->'content'->'application/json');

-- defines an application/vnd.pgrst.object+json response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'get.products'->'content'->'application/vnd.pgrst.object+json');

-- defines an application/vnd.pgrst.object+json;nulls=stripped response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'get.products'->'content'->'application/vnd.pgrst.object+json;nulls=stripped');

-- defines a text/csv response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'get.products'->'content'->'text/csv');

-- POST operation object

-- defines an application/json response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'post.products'->'content'->'application/json');

-- defines an application/vnd.pgrst.object+json response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'post.products'->'content'->'application/vnd.pgrst.object+json');

-- defines an application/vnd.pgrst.object+json;nulls=stripped response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'post.products'->'content'->'application/vnd.pgrst.object+json;nulls=stripped');

-- defines a text/csv response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'post.products'->'content'->'text/csv');

-- Views
-- GET operation object

select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'get.big_products'->'content'->'application/json');

-- defines an application/vnd.pgrst.object+json response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'get.big_products'->'content'->'application/vnd.pgrst.object+json');

-- defines an application/vnd.pgrst.object+json;nulls=stripped response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'get.big_products'->'content'->'application/vnd.pgrst.object+json;nulls=stripped');

-- defines a text/csv response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'get.big_products'->'content'->'text/csv');

-- defines a GET operation object for non auto-updatable views
select postgrest_openapi_spec('{test}')->'components'->'responses' ? 'get.non_auto_updatable' as value;

-- POST operation object

-- defines an application/json response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'post.big_products'->'content'->'application/json');

-- defines an application/vnd.pgrst.object+json response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'post.big_products'->'content'->'application/vnd.pgrst.object+json');

-- defines an application/vnd.pgrst.object+json;nulls=stripped response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'post.big_products'->'content'->'application/vnd.pgrst.object+json;nulls=stripped');

-- defines a text/csv response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'responses'->'post.big_products'->'content'->'text/csv');

-- does not define a POST operation object for non auto-updatable views
select postgrest_openapi_spec('{test}')->'components'->'responses' ? 'post.non_auto_updatable' as value;
