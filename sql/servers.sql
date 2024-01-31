/*
File: servers.sql
Purpose: Builds/manages the `servers` section of the OpenAPI document

Other doco/notes:
-  Things to search for in this file: TODO, MVP

*/

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION openapi" to load this file. \quit

---------- General Configuration (excluding servers) ----------
-- Should probably be removed when we have config stuff working properly
CREATE TABLE configuration (
  name TEXT,
  value TEXT,
  PRIMARY KEY (name)
);
-- Would've liked to have copied from STDIN, but that doesn't seem to be available in extensions
INSERT INTO configuration (name, value) VALUES ('mode', 'follow-privileges');
INSERT INTO configuration (name, value) VALUES ('security-active', 'false');
INSERT INTO configuration (name, value) VALUES ('api-name', '');
INSERT INTO configuration (name, value) VALUES ('api-version', '');
INSERT INTO configuration (name, value) VALUES ('api-description', '');
SELECT pg_catalog.pg_extension_config_dump('configuration', '');
-- openapi-server-proxy-uri has been replaced with the Servers configuration below

-- TODO: (MVP) Can we store the above stuff in the postgres set_config -type setup?  The set_config function only applies for the current session



---------- Servers Configuration and Fetching ----------
/*
Specification: https://spec.openapis.org/oas/v3.0.1#server-object

Has a few additions to support server overriding:
-  Each server can be overridden
-  Servers with the same slug override each other; servers with different slugs are completely unrelated
-  Overriding is controlled by the priority; the higher the number, the higher the priority
-  Priority 10 is reserved for default values
-  Priority 20 is reserved for values copied from configuration
*/
-- Configuration table, including defaults
CREATE TABLE servers (
  slug TEXT NOT NULL DEFAULT 'default',        -- A slug that says what category of URL we're looking at
  url TEXT NOT NULL,                          -- URL as per OpenAPI 3.0.1
    -- TODO: would like to convert to https://github.com/petere/pguri but not sure what the team will think -- see question at https://github.com/PostgREST/postgrest/issues/1698
  description TEXT,
  variables JSONB,
  priority INTEGER NOT NULL,
  PRIMARY KEY (slug, priority)
);
INSERT INTO servers (url, description, priority) VALUES ('http://0.0.0.0:3000/', 'Default URL', 10);
-- That second one will be replaced with the value from the configuration
SELECT pg_catalog.pg_extension_config_dump('servers', '');

-- Get servers, with the priorities, etc, already sorted out
CREATE OR REPLACE FUNCTION oas_build_servers()
RETURNS JSONB AS $$
DECLARE
  json_result jsonb;
BEGIN
  -- cf. https://stackoverflow.com/questions/61874745/postgresql-get-first-non-null-value-per-group
  WITH
    tservers AS (
      SELECT slug, url, description, variables FROM servers ORDER BY priority DESC
    ),
    jq AS (SELECT
      (ARRAY_AGG(url        ) FILTER (WHERE url         IS NOT NULL))[1] AS url,
      (ARRAY_AGG(description) FILTER (WHERE description IS NOT NULL))[1] AS description,
      (ARRAY_AGG(variables  ) FILTER (WHERE variables   IS NOT NULL))[1] AS variables  -- URL variables
      FROM tservers
      GROUP BY slug
      ORDER BY slug
  )
  SELECT json_agg(jq) FROM jq INTO json_result;

  RETURN json_result;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE PROCEDURE set_server_from_configuration()
AS $$
DECLARE
  scheme text;
  host text;
  port int;

  url_string text;
  description_string text;
BEGIN
  port:= COALESCE(NULLIF(REGEXP_REPLACE(current_setting('pgrst.server_port', TRUE), '[^0-9]', '', 'g'), '')::bigint, 443);
  scheme := CASE
    WHEN port = 80 THEN 'http'
    ELSE 'https'
  END;
  host := CASE
    WHEN current_setting('pgrst.server_host', TRUE) ~ '^(\*[46]?|\![46])$' THEN '0.0.0.0'
    ELSE current_setting('pgrst.server_host', TRUE)
  END;

  IF LENGTH(host) > 0 AND port > 0 AND LENGTH(scheme) > 0 THEN
    url_string := FORMAT('%s://%s:%s/', scheme, host, port);
    description_string := 'URL from configuration';
    INSERT INTO servers (url, description, slug, priority)
    VALUES (url_string, description_string, 'default', 20)
    ON CONFLICT (slug, priority) DO
      UPDATE SET
        url = url_string,
        description = description_string;
  ELSE
    DELETE FROM servers WHERE
      slug = 'default'
      AND priority = 20;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Calls this config on startup
-- TODO: (MVP) How do we run this on config change?  
CALL set_server_from_configuration();
