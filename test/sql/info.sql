-- shows the first line of the comment on the schema as title
select jsonb_pretty(postgrest_openapi_spec('{test}')->'info'->'title');

-- shows the second line of the comment on the schema as description
select jsonb_pretty(postgrest_openapi_spec('{test}')->'info'->'description');

-- TODO: tests for versions
