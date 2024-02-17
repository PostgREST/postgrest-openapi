-- shows root path for the OpenAPI output
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/');

-- Tables
-- GET operation object

-- shows the table name as tag
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'get'->'tags');

-- uses a reference for the 200 HTTP code response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'get'->'responses'->'200');

-- uses a reference for the 206 HTTP code response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'get'->'responses'->'206');

-- uses a reference for error responses
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'get'->'responses'->'default');

-- uses references for columns as query parameters
select value
from jsonb_array_elements(postgrest_openapi_spec('{test}')->'paths'->'/products'->'get'->'parameters')
where value->>'$ref' like '#/components/parameters/rowFilter.products.%';

-- shows the first line of the comment on the table as summary
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'get'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'get'->'description');

-- uses references for common parameters
select value
from jsonb_array_elements(postgrest_openapi_spec('{test}')->'paths'->'/products'->'get'->'parameters')
where value->>'$ref' not like '#/components/parameters/rowFilter.products.%';

-- POST operation object

-- shows the table name as tag
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'post'->'tags');

-- uses a reference for the 201 HTTP code response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'post'->'responses'->'201');

-- uses a reference for error responses
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'post'->'responses'->'default');

-- uses a reference for request body
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'post'->'requestBody'->'$ref');

-- shows the first line of the comment on the table as summary
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'post'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'post'->'description');

-- uses references for common parameters
select value
from jsonb_array_elements(postgrest_openapi_spec('{test}')->'paths'->'/products'->'post'->'parameters')
where value->>'$ref' like '#/components/parameters/%';

-- PATCH operation object

-- shows the table name as tag
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'patch'->'tags');

-- uses a reference for the 200 HTTP code response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'patch'->'responses'->'200');

-- uses a reference for the 204 HTTP code response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'patch'->'responses'->'204');

-- uses a reference for error responses
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'patch'->'responses'->'default');

-- uses a reference for request body
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'patch'->'requestBody'->'$ref');

-- shows the first line of the comment on the table as summary
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'patch'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'patch'->'description');

-- uses references for columns as query parameters
select value
from jsonb_array_elements(postgrest_openapi_spec('{test}')->'paths'->'/products'->'patch'->'parameters')
where value->>'$ref' like '#/components/parameters/rowFilter.products.%';

-- uses references for common parameters
select value
from jsonb_array_elements(postgrest_openapi_spec('{test}')->'paths'->'/products'->'patch'->'parameters')
where value->>'$ref' not like '#/components/parameters/rowFilter.products.%';

-- DELETE operation object

-- shows the table name as tag
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'delete'->'tags');

-- uses a reference for the 200 HTTP code response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'delete'->'responses'->'200');

-- uses a reference for the 204 HTTP code response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'delete'->'responses'->'204');

-- uses a reference for error responses
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'delete'->'responses'->'default');

-- shows the first line of the comment on the table as summary
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'delete'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/products'->'delete'->'description');

-- uses references for columns as query parameters
select value
from jsonb_array_elements(postgrest_openapi_spec('{test}')->'paths'->'/products'->'delete'->'parameters')
where value->>'$ref' like '#/components/parameters/rowFilter.products.%';

-- uses references for common parameters
select value
from jsonb_array_elements(postgrest_openapi_spec('{test}')->'paths'->'/products'->'delete'->'parameters')
where value->>'$ref' not like '#/components/parameters/rowFilter.products.%';

-- Views
-- GET operation object

-- shows the table name as tag
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'get'->'tags');

-- uses a reference for the 200 HTTP code response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'get'->'responses'->'200');

-- uses a reference for the 206 HTTP code response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'get'->'responses'->'206');

-- uses a reference for error responses
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'get'->'responses'->'default');

-- shows the first line of the comment on the table as summary
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'get'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'get'->'description');

-- uses references for columns as query parameters
select value
from jsonb_array_elements(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'get'->'parameters')
where value->>'$ref' like '#/components/parameters/rowFilter.big_products.%';

-- uses references for common parameters
select value
from jsonb_array_elements(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'get'->'parameters')
where value->>'$ref' not like '#/components/parameters/rowFilter.big_products.%';

-- shows a GET operation object for non auto-updatable views
select postgrest_openapi_spec('{test}')->'paths'->'/non_auto_updatable' ? 'get' as value;

-- POST operation object

-- shows the table name as tag
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'post'->'tags');

-- uses a reference for the 201 HTTP code response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'post'->'responses'->'201');

-- uses a reference for error responses
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'post'->'responses'->'default');

-- uses a reference for request body
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'post'->'requestBody'->'$ref');

-- shows the first line of the comment on the table as summary
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'post'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'post'->'description');

-- uses references for common parameters
select value
from jsonb_array_elements(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'post'->'parameters')
where value->>'$ref' like '#/components/parameters/%';

-- does not show a POST operation object for non auto-updatable views
select postgrest_openapi_spec('{test}')->'paths'->'/non_auto_updatable' ? 'post' as value;

-- PATCH operation object

-- shows the table name as tag
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'patch'->'tags');

-- uses a reference for the 200 HTTP code response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'patch'->'responses'->'200');

-- uses a reference for the 204 HTTP code response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'patch'->'responses'->'204');

-- uses a reference for error responses
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'patch'->'responses'->'default');

-- uses a reference for request body
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'patch'->'requestBody'->'$ref');

-- shows the first line of the comment on the table as summary
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'patch'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'patch'->'description');

-- uses references for columns as query parameters
select value
from jsonb_array_elements(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'patch'->'parameters')
where value->>'$ref' like '#/components/parameters/rowFilter.big_products.%';

-- uses references for common parameters
select value
from jsonb_array_elements(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'patch'->'parameters')
where value->>'$ref' not like '#/components/parameters/rowFilter.big_products.%';

-- does not show a PATCH operation object for non auto-updatable views
select postgrest_openapi_spec('{test}')->'paths'->'/non_auto_updatable' ? 'patch' as value;

-- DELETE operation object

-- shows the table name as tag
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'delete'->'tags');

-- uses a reference for the 200 HTTP code response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'delete'->'responses'->'200');

-- uses a reference for the 204 HTTP code response
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'delete'->'responses'->'204');

-- uses a reference for error responses
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'delete'->'responses'->'default');

-- shows the first line of the comment on the table as summary
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'delete'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'delete'->'description');

-- uses references for columns as query parameters
select value
from jsonb_array_elements(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'delete'->'parameters')
where value->>'$ref' like '#/components/parameters/rowFilter.big_products.%';

-- uses references for common parameters
select value
from jsonb_array_elements(postgrest_openapi_spec('{test}')->'paths'->'/big_products'->'delete'->'parameters')
where value->>'$ref' not like '#/components/parameters/rowFilter.big_products.%';

-- does not show a DELETE operation object for non auto-updatable views
select postgrest_openapi_spec('{test}')->'paths'->'/non_auto_updatable' ? 'delete' as value;
