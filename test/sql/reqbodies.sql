-- Tables

-- defines an application/json request body
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'requestBodies'->'products'->'content'->'application/json');

-- defines an application/x-www-form-urlencoded request body
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'requestBodies'->'products'->'content'->'application/x-www-form-urlencoded');

-- defines a text/csv request body
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'requestBodies'->'products'->'content'->'text/csv');

-- Views

-- defines an application/json request body
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'requestBodies'->'big_products'->'content'->'application/json');

-- defines an application/x-www-form-urlencoded request body
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'requestBodies'->'big_products'->'content'->'application/x-www-form-urlencoded');

-- defines a text/csv request body
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'components'->'requestBodies'->'big_products'->'content'->'text/csv');

-- does not define a request body for non auto-updatable views
select get_postgrest_openapi_spec('{test}')->'components'->'requestBodies' ? 'non_auto_updatable' as value;
