-- Tables

-- detects tables as objects
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'products'->'type');

-- detects columns with enum types as an enum property
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'products'->'properties'->'size');

-- references a composite type column from a table to a component definition
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'products'->'properties'->'attr');

-- identifies the required columns
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'products'->'required');

-- detects comments done on a table and shows it as description
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'products'->'description');

-- detects comments done on a table column and shows it as description
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'products'->'properties'->'id'->'description');

-- maps sql types to OpenAPI types correctly
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'openapi_types');

-- does not show tables outside the exposed schema
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'secret_table');

-- detects composite types as objects
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.attribute'->'type');

-- references a composite type column from another composite type to a component definition
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.attribute'->'properties'->'dim');

-- detects a composite type inside another composite type
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.dimension');

-- detects an array composite type inside another composite type
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.color');

-- does not show a composite type that is not used by an exposed table
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.hiddentype');

-- detects comments done on a composite type and shows it as description
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.attribute'->'description');

-- detects comments done on a composite type column and shows it as description
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.attribute'->'properties'->'other'->'description');

-- references a composite type column from an array composite type inside the items property
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.attribute'->'properties'->'colors'->'items');

-- Functions

-- Composite types inside arguments

-- detects composite types as objects
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.attribute_arg'->'type');

-- references a composite type column from another composite type to a component definition
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.attribute_arg'->'properties'->'dim');

-- detects a composite type inside another composite type
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.dimension_arg');

-- detects an array composite type inside another composite type
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.color_arg');

-- references a composite type column from an array composite type inside the items property
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.attribute_arg'->'properties'->'colors'->'items');

-- Composite types inside returning values

-- detects composite types as objects
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.attribute_ret'->'type');

-- references a composite type column from another composite type to a component definition
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.attribute_ret'->'properties'->'dim');

-- detects a composite type inside another composite type
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.dimension_ret');

-- detects an array composite type inside another composite type
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.color_ret');

-- references a composite type column from an array composite type inside the items property
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'types.attribute_ret'->'properties'->'colors'->'items');

-- Non-composite return values

-- detects a function that returns a simple type
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.returns_simple_type');

-- detects a function that returns a simple array type
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.returns_simple_type_arr');

-- detects a function that returns table
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.returns_table');

-- detects a function that returns table with array columns
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.returns_table_arr');

-- detects a function that returns a record with inout arguments
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.returns_inout');

-- detects a function that returns a record with inout array arguments
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.returns_inout_arr');

-- detects a function that returns a record with out arguments
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.returns_out');

-- detects a function that returns a record with out array arguments
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.returns_out_arr');

-- detects a function that returns a record with inout and out arguments
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.returns_inout_out');

-- detects a function that returns a record with inout and out array arguments
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.returns_inout_out_arr');

-- detects a function that returns an unknown record as a free-form object
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.returns_unknown_record');

-- detects a function with a single unnamed json parameter
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.single_unnamed_json_param');

-- detects a function with a single unnamed jsonb parameter
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.single_unnamed_jsonb_param');

-- detects a function with a single unnamed text parameter
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.single_unnamed_text_param');

-- detects a function with a single unnamed xml parameter
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.single_unnamed_xml_param');

-- ignores a function with a single unnamed unrecognized parameter
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.single_unnamed_unrecognized_param');

-- ignores a function with unnamed parameters
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.single_unnamed_unrecognized_param');

-- ignores a function with named and unnamed parameters
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.single_unnamed_unrecognized_param');

-- ignores a function outside of the exposed schemas
select jsonb_pretty(get_openapi_document('{test}')->'components'->'schemas'->'rpc.private.secret_function');

-- Common

-- defines all the available prefer headers
select key, jsonb_pretty(value)
from jsonb_each(get_openapi_document('{test}')->'components'->'schemas')
where key like 'header.prefer%';
