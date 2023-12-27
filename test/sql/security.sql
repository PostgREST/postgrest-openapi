-- shows the JWT security scheme
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'securitySchemes'->'JWT');

-- lists the JWT scheme as a security requirement object 
select get_postgrest_openapi_spec('{public}')->'security' <@ '[{"JWT": []}]'::jsonb as has_jwt;
