-- shows common query parameters
select *
from jsonb_each(postgrest_openapi_spec('{test}')->'components'->'parameters')
where key in ('select', 'order', 'limit', 'offset', 'on_conflict', 'columns', 'or', 'and', 'not.or', 'not.and');

-- shows common headers
select key, jsonb_pretty(value)
from jsonb_each(postgrest_openapi_spec('{test}')->'components'->'parameters')
where key in ('preferGet', 'preferPost', 'preferPut', 'preferPatch', 'preferDelete', 'preferPostRpc', 'range');

-- shows table columns as parameters
select key, jsonb_pretty(value)
from jsonb_each(postgrest_openapi_spec('{test}')->'components'->'parameters')
where key like 'rowFilter.products.%';

-- shows view columns as parameters
select key, jsonb_pretty(value)
from jsonb_each(postgrest_openapi_spec('{test}')->'components'->'parameters')
where key like 'rowFilter.big_products.%';

-- shows `IN` function arguments as RPC parameters
select key, jsonb_pretty(value)
from jsonb_each(postgrest_openapi_spec('{test}')->'components'->'parameters')
where key like 'rpcParam.has_in_parameters.%';

-- shows `INOUT` function arguments as RPC parameters
select key, jsonb_pretty(value)
from jsonb_each(postgrest_openapi_spec('{test}')->'components'->'parameters')
where key like 'rpcParam.has_inout_parameters.%';

-- shows `VARIADIC` function arguments as RPC parameters
select key, jsonb_pretty(value)
from jsonb_each(postgrest_openapi_spec('{test}')->'components'->'parameters')
where key like 'rpcParam.has_variadic_parameter.%';
