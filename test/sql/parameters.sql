-- shows common query parameters
select *
from jsonb_each(get_postgrest_openapi_spec('{public}')->'components'->'parameters')
where key in ('select', 'order', 'limit', 'offset', 'on_conflict', 'columns', 'or', 'and', 'not.or', 'not.and');

-- shows common headers
select key, jsonb_pretty(value)
from jsonb_each(get_postgrest_openapi_spec('{public}')->'components'->'parameters')
where key in ('preferGet', 'preferPost', 'preferPut', 'preferPatch', 'preferDelete', 'preferPostRpc', 'range');
