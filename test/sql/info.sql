-- shows the first line of the comment on the schema as title
select jsonb_pretty(postgrest_openapi_spec('{test}')->'info'->'title');

-- shows the second line of the comment on the schema as summary
select jsonb_pretty(postgrest_openapi_spec('{test}')->'info'->'summary');

-- shows the third line of the comment on the schema as description
select jsonb_pretty(postgrest_openapi_spec('{test}')->'info'->'description');

-- shows default title when there is no comment on the schema
select jsonb_pretty(postgrest_openapi_spec('{types}')->'info'->'title');

-- shows no summary when there is no comment on the schema
select postgrest_openapi_spec('{types}')->'info' ? 'summary';
  
-- shows default description when there is no comment on the schema
select jsonb_pretty(postgrest_openapi_spec('{types}')->'info'->'description');

-- TODO: tests for versions
