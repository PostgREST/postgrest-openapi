-- shows the default server
DELETE FROM servers WHERE slug = 'default' and priority = 20;
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'servers');

-- Loads the config -- only needed because we're not using actual PostgREST in the tests
SELECT postgrest.pre_config();
-- Sets the config; would be called if we called callable_root() (in main)
CALL set_server_from_configuration();

-- shows the custom server url specified in the configuration
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'servers');


-- shows the overriding custom server url specified by the user
INSERT INTO servers (url, description, priority) VALUES ('https://www.example.com/api/', 'Overriding URL', 30);
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'servers');

-- shows the additional custom server url specified by the user
INSERT INTO servers (url, description, priority, slug, variables)
	VALUES ('https://www.example.com/otherapi/?s={s}&browser={browser}', 'Additional URL', 30, 'additional', '{"s": "worms", "browser": "none"}');
select jsonb_pretty(get_postgrest_openapi_spec('{test}')->'servers');

-- Shows the configuration table
SELECT * from servers;
