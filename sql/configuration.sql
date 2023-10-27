/*
File: configuration.sql
Purpose: Contains the Configuration setup and helper functions

Other doco/notes:
-	First line of description (COMMENT) is used as summary; following lines are used as description
-	Things to search for in this file: FIX, FIXMVP, QUESTION

*/

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
-- \echo Use "CREATE EXTENSION openapi" to load this file. \quit

---------- General Configuration (excluding servers) ----------
CREATE TABLE configuration (
	name	TEXT,
	value	TEXT,
	PRIMARY KEY (name)
);
-- Would've liked to have copied from STDIN, but that doesn't seem to be available in extensions
INSERT INTO configuration (name, value) VALUES ('mode', 'follow-privileges');
INSERT INTO configuration (name, value) VALUES ('security-active', 'false');
INSERT INTO configuration (name, value) VALUES ('api-name', '');
INSERT INTO configuration (name, value) VALUES ('api-description', '');
/*
COPY configuration (name, value) FROM STDIN;
mode	follow-privileges
security-active	false
api-name	
api-description	
\.
*/
SELECT pg_catalog.pg_extension_config_dump('configuration', '');
-- openapi-server-proxy-uri has been replaced with the Servers configuration below

-- FIXMVP: Can we store the above stuff in the postgres set_config -type setup?  The set_config function only applies for the current session



---------- Servers Configuration and Fetching ----------
/*
Specification: https://spec.openapis.org/oas/v3.0.1#server-object

Has a few additions to support server overriding:
-	Each server can be overridden
-	Servers with the same slug override each other; servers with different slugs are completely unrelated
-	Overriding is controlled by the priority; the higher the number, the higher the priority
-	Priority 10 is reserved for default values
-	Priority 20 is reserved for values copied from configuration
*/
-- Configuration table, including defaults
CREATE TABLE servers (
	slug		TEXT NOT NULL DEFAULT 'default',        -- A slug that says what category of URL we're looking at
	url		TEXT NOT NULL,                          -- URL as per OpenAPI 3.0.1
		-- FIX: would like to convert to https://github.com/petere/pguri but not sure what the team will think -- see ques>
	description	TEXT,
	variables	JSONB,
	priority	INTEGER NOT NULL,
	PRIMARY KEY (slug, priority)
);
INSERT INTO servers (url, description, priority) VALUES ('http://0.0.0.0:80/', 'Default URL', 10);
INSERT INTO servers (url, description, priority) VALUES ('http://0.0.0.0:80/', 'Default URL', 20);
/*
COPY servers (url, description, priority) FROM stdin;
http://0.0.0.0:80/	Default URL	10
http://0.0.0.0:80/	Default URL	20
\.
*/
-- That second one will be replaced with the value from the configuration
SELECT pg_catalog.pg_extension_config_dump('servers', '');

-- Get servers, with the priorities, etc, already sorted out
CREATE OR REPLACE FUNCTION openapi_server_objects()
RETURNS JSONB AS $$
DECLARE
	json_result	jsonb;
BEGIN
	-- cf. https://stackoverflow.com/questions/61874745/postgresql-get-first-non-null-value-per-group
	WITH
		tservers AS (
			SELECT slug, url, description, variables FROM servers ORDER BY priority DESC
		),
		jq AS (SELECT
			(ARRAY_AGG(url		) FILTER (WHERE url		IS NOT NULL))[1] AS url,
			(ARRAY_AGG(description	) FILTER (WHERE description	IS NOT NULL))[1] AS description,
			(ARRAY_AGG(variables	) FILTER (WHERE variables	IS NOT NULL))[1] AS variables  -- URL variables
			FROM tservers
			GROUP BY slug
		)
	SELECT json_agg(jq) FROM jq INTO json_result;

	RETURN json_result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE setServerFromConfig()
AS $$
DECLARE
	port	int;
	scheme	text;
	host	text;
BEGIN
	port := current_setting('pgrst.server_port', TRUE);
	scheme := CASE
		WHEN port = 80 THEN 'http'
		ELSE 'https'
	END;
	host := CASE
		WHEN current_setting('pgrst.server_host', TRUE) ~ '^(\*[46]?|\![46])$' THEN '0.0.0.0'
		ELSE current_setting('pgrst.server_host', TRUE)
	END;

	IF LENGTH(host) > 0 AND port > 0 AND LENGTH(scheme) > 0 THEN
		UPDATE servers
		SET
			url = FORMAT('%s://%s:%s/', scheme, host, port),
			description = 'URL from configuration'
		WHERE
			slug = 'default'
			AND priority = 20;
	ELSE
		DELETE FROM servers WHERE
			slug = 'default'
			AND priority = 20;
	END IF;
END;
$$ LANGUAGE plpgsql;

-- Calls this config on startup
-- FIXMVP: How do we run this on config change?  
CALL setServerFromConfig();
