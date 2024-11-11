-- Tables

-- defines an application/json request body
select jsonb_pretty(get_openapi_document('{test}')->'components'->'requestBodies'->'products'->'content'->'application/json');

-- defines an application/x-www-form-urlencoded request body
select jsonb_pretty(get_openapi_document('{test}')->'components'->'requestBodies'->'products'->'content'->'application/x-www-form-urlencoded');

-- defines a text/csv request body
select jsonb_pretty(get_openapi_document('{test}')->'components'->'requestBodies'->'products'->'content'->'text/csv');

-- Views

-- defines an application/json request body
select jsonb_pretty(get_openapi_document('{test}')->'components'->'requestBodies'->'big_products'->'content'->'application/json');

-- defines an application/x-www-form-urlencoded request body
select jsonb_pretty(get_openapi_document('{test}')->'components'->'requestBodies'->'big_products'->'content'->'application/x-www-form-urlencoded');

-- defines a text/csv request body
select jsonb_pretty(get_openapi_document('{test}')->'components'->'requestBodies'->'big_products'->'content'->'text/csv');

-- does not define a request body for non auto-updatable views
select get_openapi_document('{test}')->'components'->'requestBodies' ? 'non_auto_updatable' as value;

-- Functions

-- defines an application/json request body
select jsonb_pretty(get_openapi_document('{test}')->'components'->'requestBodies'->'rpc.get_products_by_size'->'content'->'application/json');

-- defines an application/x-www-form-urlencoded request body
select jsonb_pretty(get_openapi_document('{test}')->'components'->'requestBodies'->'rpc.get_products_by_size'->'content'->'application/x-www-form-urlencoded');

-- defines a text/csv request body
select jsonb_pretty(get_openapi_document('{test}')->'components'->'requestBodies'->'rpc.get_products_by_size'->'content'->'text/csv');

-- defines only one application/json request body for a single unnamed json/jsonb parameter
select jsonb_pretty(get_openapi_document('{test}')->'components'->'requestBodies'->'rpc.single_unnamed_json_param'->'content');
select jsonb_pretty(get_openapi_document('{test}')->'components'->'requestBodies'->'rpc.single_unnamed_jsonb_param'->'content');

-- defines only one text/pain request body for a single unnamed text parameter
select jsonb_pretty(get_openapi_document('{test}')->'components'->'requestBodies'->'rpc.single_unnamed_text_param'->'content');

-- defines only one text/xml request body for a single unnamed xml parameter
select jsonb_pretty(get_openapi_document('{test}')->'components'->'requestBodies'->'rpc.single_unnamed_xml_param'->'content');

-- defines only one application/octect-stream request body for a single unnamed bytea parameter
select jsonb_pretty(get_openapi_document('{test}')->'components'->'requestBodies'->'rpc.single_unnamed_bytea_param'->'content');

-- the request body is not required when all the parameters have default values
select get_openapi_document('{test}')->'components'->'requestBodies'->'rpc.has_all_default_parameters'->'required' as value;

-- the request body is required when at least one of the parameters has a default value
select get_openapi_document('{test}')->'components'->'requestBodies'->'rpc.has_one_default_parameter'->'required' as value;

-- does not define a request body for functions without parameters
select get_openapi_document('{test}')->'components'->'requestBodies' ? 'rps.has_no_parameters' as value;
