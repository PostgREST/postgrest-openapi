-- shows the JWT security scheme
select jsonb_pretty(get_openapi_document('{test}')->'components'->'securitySchemes'->'JWT');

-- lists the JWT scheme as a security requirement object 
select get_openapi_document('{test}')->'security' <@ '[{"JWT": []}]'::jsonb as has_jwt;
