-- shows root path for the OpenAPI output
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/');

-- Tables
-- GET operation object

-- shows the table name as tag
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'get'->'tags');

-- uses a reference for the 200 HTTP code response
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'get'->'responses'->'200');

-- uses a reference for the 206 HTTP code response
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'get'->'responses'->'206');

-- uses a reference for error responses
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'get'->'responses'->'default');

-- uses references for columns as query parameters
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/products'->'get'->'parameters')
where value->>'$ref' like '#/components/parameters/rowFilter.products.%';

-- shows the first line of the comment on the table as summary
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'get'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'get'->'description');

-- uses references for common parameters
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/products'->'get'->'parameters')
where value->>'$ref' not like '#/components/parameters/rowFilter.products.%';

-- POST operation object

-- shows the table name as tag
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'post'->'tags');

-- uses a reference for the 201 HTTP code response
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'post'->'responses'->'201');

-- uses a reference for error responses
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'post'->'responses'->'default');

-- uses a reference for request body
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'post'->'requestBody'->'$ref');

-- shows the first line of the comment on the table as summary
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'post'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'post'->'description');

-- uses references for common parameters
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/products'->'post'->'parameters')
where value->>'$ref' like '#/components/parameters/%';

-- PATCH operation object

-- shows the table name as tag
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'patch'->'tags');

-- uses a reference for the 200 HTTP code response
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'patch'->'responses'->'200');

-- uses a reference for the 204 HTTP code response
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'patch'->'responses'->'204');

-- uses a reference for error responses
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'patch'->'responses'->'default');

-- uses a reference for request body
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'patch'->'requestBody'->'$ref');

-- shows the first line of the comment on the table as summary
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'patch'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'patch'->'description');

-- uses references for columns as query parameters
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/products'->'patch'->'parameters')
where value->>'$ref' like '#/components/parameters/rowFilter.products.%';

-- uses references for common parameters
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/products'->'patch'->'parameters')
where value->>'$ref' not like '#/components/parameters/rowFilter.products.%';

-- DELETE operation object

-- shows the table name as tag
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'delete'->'tags');

-- uses a reference for the 200 HTTP code response
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'delete'->'responses'->'200');

-- uses a reference for the 204 HTTP code response
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'delete'->'responses'->'204');

-- uses a reference for error responses
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'delete'->'responses'->'default');

-- shows the first line of the comment on the table as summary
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'delete'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/products'->'delete'->'description');

-- uses references for columns as query parameters
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/products'->'delete'->'parameters')
where value->>'$ref' like '#/components/parameters/rowFilter.products.%';

-- uses references for common parameters
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/products'->'delete'->'parameters')
where value->>'$ref' not like '#/components/parameters/rowFilter.products.%';

-- Views
-- GET operation object

-- shows the table name as tag
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'get'->'tags');

-- uses a reference for the 200 HTTP code response
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'get'->'responses'->'200');

-- uses a reference for the 206 HTTP code response
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'get'->'responses'->'206');

-- uses a reference for error responses
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'get'->'responses'->'default');

-- shows the first line of the comment on the table as summary
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'get'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'get'->'description');

-- uses references for columns as query parameters
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/big_products'->'get'->'parameters')
where value->>'$ref' like '#/components/parameters/rowFilter.big_products.%';

-- uses references for common parameters
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/big_products'->'get'->'parameters')
where value->>'$ref' not like '#/components/parameters/rowFilter.big_products.%';

-- shows a GET operation object for non auto-updatable views
select get_openapi_document('{test}')->'paths'->'/non_auto_updatable' ? 'get' as value;

-- POST operation object

-- shows the table name as tag
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'post'->'tags');

-- uses a reference for the 201 HTTP code response
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'post'->'responses'->'201');

-- uses a reference for error responses
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'post'->'responses'->'default');

-- uses a reference for request body
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'post'->'requestBody'->'$ref');

-- shows the first line of the comment on the table as summary
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'post'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'post'->'description');

-- uses references for common parameters
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/big_products'->'post'->'parameters')
where value->>'$ref' like '#/components/parameters/%';

-- does not show a POST operation object for non auto-updatable views
select get_openapi_document('{test}')->'paths'->'/non_auto_updatable' ? 'post' as value;

-- PATCH operation object

-- shows the table name as tag
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'patch'->'tags');

-- uses a reference for the 200 HTTP code response
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'patch'->'responses'->'200');

-- uses a reference for the 204 HTTP code response
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'patch'->'responses'->'204');

-- uses a reference for error responses
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'patch'->'responses'->'default');

-- uses a reference for request body
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'patch'->'requestBody'->'$ref');

-- shows the first line of the comment on the table as summary
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'patch'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'patch'->'description');

-- uses references for columns as query parameters
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/big_products'->'patch'->'parameters')
where value->>'$ref' like '#/components/parameters/rowFilter.big_products.%';

-- uses references for common parameters
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/big_products'->'patch'->'parameters')
where value->>'$ref' not like '#/components/parameters/rowFilter.big_products.%';

-- does not show a PATCH operation object for non auto-updatable views
select get_openapi_document('{test}')->'paths'->'/non_auto_updatable' ? 'patch' as value;

-- DELETE operation object

-- shows the table name as tag
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'delete'->'tags');

-- uses a reference for the 200 HTTP code response
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'delete'->'responses'->'200');

-- uses a reference for the 204 HTTP code response
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'delete'->'responses'->'204');

-- uses a reference for error responses
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'delete'->'responses'->'default');

-- shows the first line of the comment on the table as summary
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'delete'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/big_products'->'delete'->'description');

-- uses references for columns as query parameters
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/big_products'->'delete'->'parameters')
where value->>'$ref' like '#/components/parameters/rowFilter.big_products.%';

-- uses references for common parameters
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/big_products'->'delete'->'parameters')
where value->>'$ref' not like '#/components/parameters/rowFilter.big_products.%';

-- does not show a DELETE operation object for non auto-updatable views
select get_openapi_document('{test}')->'paths'->'/non_auto_updatable' ? 'delete' as value;

-- Functions
-- GET operation object

-- shows the function name as tag
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/rpc/get_products_by_size'->'get'->'tags');

-- uses a reference for the 200 HTTP code response
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/rpc/get_products_by_size'->'get'->'responses'->'200');

-- uses a reference for the 206 HTTP code response on `RETURNS SET OF` functions
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/rpc/get_products_by_size'->'get'->'responses'->'206');

-- uses a reference for error responses
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/rpc/get_products_by_size'->'get'->'responses'->'default');

-- shows the first line of the comment on the table as summary
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/rpc/get_products_by_size'->'get'->'summary');

-- shows the second line of the comment on the table as description
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/rpc/get_products_by_size'->'get'->'description');

-- uses references for common parameters on `RETURNS <composite type>` functions
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/rpc/get_attribute'->'get'->'parameters')
where value->>'$ref' not like '#/components/parameters/rpcParam.get_attribute.%';

-- uses references for common parameters on `RETURNS TABLE` functions
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/rpc/returns_table'->'get'->'parameters')
where value->>'$ref' not like '#/components/parameters/rpcParam.returns_table.%';

-- uses references for common parameters on functions with INOUT/OUT parameters
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/rpc/returns_inout_out'->'get'->'parameters')
where value->>'$ref' not like '#/components/parameters/rpcParam.returns_inout_out.%';

-- does not use a reference for the 206 HTTP code response on functions that do not return `SET OF`
select get_openapi_document('{test}')->'paths'->'/rpc/get_attribute'->'get'->'responses' ? '206' as value;

-- does not use a reference for common parameters (except for prefer headers) on functions that do not return composite types
select value
from jsonb_array_elements(get_openapi_document('{test}')->'paths'->'/rpc/returns_simple_type'->'get'->'parameters')
where value->>'$ref' not like '#/components/parameters/rpcParam.returns_simple_type.%';

-- shows a function with a single unnamed parameter of accepted types
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/rpc/single_unnamed_json_param'->'get'->'tags');
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/rpc/single_unnamed_jsonb_param'->'get'->'tags');
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/rpc/single_unnamed_text_param'->'get'->'tags');
select jsonb_pretty(get_openapi_document('{test}')->'paths'->'/rpc/single_unnamed_xml_param'->'get'->'tags');

-- does not show a function with a single unnamed parameter of non-accepted types
select get_openapi_document('{test}')->'paths' ? '/rpc/single_unnamed_unrecognized_param' as value;

-- does not show a function with unnamed parameters
select get_openapi_document('{test}')->'paths' ? '/rpc/unnamed_params' as value;

-- does not show a function with named and unnamed parameters
select get_openapi_document('{test}')->'paths' ? '/rpc/named_and_unnamed_params' as value;
