-- Loads the config -- only needed because we're not using actual PostgREST in the tests
SELECT postgrest.pre_config();
-- Sets the config; would be called if we called callable_root() (in main)
CALL set_server_from_configuration();


-- Ensures the config is loaded
SELECT current_setting('pgrst.db_schemas', TRUE);
SELECT string_to_array(current_setting('pgrst.db_schemas', TRUE), ',');

-- Tests postgrest_openapi_spec with parameters
SELECT count(postgrest_openapi_spec(
  schemas := string_to_array(current_setting('pgrst.db_schemas', TRUE), ','),
  postgrest_version := current_setting('pgrst.version', TRUE),
  proa_version := '0.1'::text, -- TODO: needs to be updated; put into config, and have Makefile update
  document_version := 'unset'::text
));


-- shows the default server
SELECT count(jsonb_pretty(callable_root()));
