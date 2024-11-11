-- shows common query parameters
select *
from jsonb_each(get_openapi_document('{test}')->'components'->'parameters')
where key in ('select', 'order', 'limit', 'offset', 'on_conflict', 'columns', 'or', 'and', 'not.or', 'not.and');

-- shows common headers
select key, jsonb_pretty(value)
from jsonb_each(get_openapi_document('{test}')->'components'->'parameters')
where key in ('preferGet', 'preferPost', 'preferPut', 'preferPatch', 'preferDelete', 'preferPostRpc', 'range');

-- shows table columns as parameters
select key, jsonb_pretty(value)
from jsonb_each(get_openapi_document('{test}')->'components'->'parameters')
where key like 'rowFilter.products.%';

-- shows view columns as parameters
select key, jsonb_pretty(value)
from jsonb_each(get_openapi_document('{test}')->'components'->'parameters')
where key like 'rowFilter.big_products.%';

-- shows composite type columns as parameters on `RETURNS <composite type>` functions
select key, jsonb_pretty(value)
from jsonb_each(get_openapi_document('{test}')->'components'->'parameters')
where key like 'rowFilter.types.attribute_ret.%';

-- shows table arguments as parameters on `RETURNS TABLE` functions
select key, jsonb_pretty(value)
from jsonb_each(get_openapi_document('{test}')->'components'->'parameters')
where key like 'rowFilter.rpc.returns_table.%';

-- shows inout/out arguments as parameters on functions with INOUT/OUT parameters
select key, jsonb_pretty(value)
from jsonb_each(get_openapi_document('{test}')->'components'->'parameters')
where key like 'rowFilter.rpc.returns_inout_out.%';

-- shows `IN` function arguments as RPC parameters
select key, jsonb_pretty(value)
from jsonb_each(get_openapi_document('{test}')->'components'->'parameters')
where key like 'rpcParam.has_in_parameters.%';

-- shows `INOUT` function arguments as RPC parameters
select key, jsonb_pretty(value)
from jsonb_each(get_openapi_document('{test}')->'components'->'parameters')
where key like 'rpcParam.has_inout_parameters.%';

-- shows `VARIADIC` function arguments as RPC parameters
select key, jsonb_pretty(value)
from jsonb_each(get_openapi_document('{test}')->'components'->'parameters')
where key like 'rpcParam.has_variadic_parameter.%';
