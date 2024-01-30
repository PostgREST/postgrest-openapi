-- shows the JWT security scheme
select jsonb_pretty(postgrest_openapi_spec('{test}')->'components'->'securitySchemes'->'JWT');

-- lists the JWT scheme as a security requirement object 
select postgrest_openapi_spec('{test}')->'security' <@ '[{"JWT": []}]'::jsonb as has_jwt;
