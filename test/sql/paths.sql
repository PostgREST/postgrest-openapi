-- shows root path for the OpenAPI output
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'paths'->'/');

-- Tables
-- GET operation object

-- shows the table name as tag
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'paths'->'/products'->'get'->'tags');
  
-- uses a reference for the 200 HTTP code response
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'paths'->'/products'->'get'->'responses'->'200');

-- uses a reference for the 206 HTTP code response
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'paths'->'/products'->'get'->'responses'->'206');

-- uses a reference for error responses
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'paths'->'/products'->'get'->'responses'->'default');

-- uses references for columns as query parameters
select value 
from jsonb_array_elements(get_postgrest_openapi_spec('{test}')->'paths'->'/products'->'get'->'parameters')
where value->>'$ref' like '#/components/parameters/rowFilter.products.%';

-- uses references for common parameters
select value
from jsonb_array_elements(get_postgrest_openapi_spec('{test}')->'paths'->'/products'->'get'->'parameters')
where value->>'$ref' not like '#/components/parameters/rowFilter.products.%';

-- Views
-- GET operation object

-- shows the table name as tag
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'get'->'tags');
  
-- uses a reference for the 200 HTTP code response
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'get'->'responses'->'200');

-- uses a reference for the 206 HTTP code response
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'get'->'responses'->'206');

-- uses a reference for error responses
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'get'->'responses'->'default');

-- uses references for columns as query parameters
select value 
from jsonb_array_elements(get_postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'get'->'parameters')
where value->>'$ref' like '#/components/parameters/rowFilter.big_products.%';

-- uses references for common parameters
select value
from jsonb_array_elements(get_postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'get'->'parameters')
where value->>'$ref' not like '#/components/parameters/rowFilter.big_products.%';
