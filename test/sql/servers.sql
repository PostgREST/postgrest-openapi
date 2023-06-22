-- shows the default server
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'servers');

-- shows the custom server url specified by the user
select jsonb_pretty(get_postgrest_openapi_spec('{test}', 'https://www.example.com/api/')->'servers');