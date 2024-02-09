-- Functions that help in building the OpenAPI spec inside PostgreSQL

create or replace function pgtype_to_oastype(type text)
returns text language sql immutable as
$$
select case when type like any(array['character', 'character varying', 'text']) then 'string'
            when type like any(array['double precision', 'numeric', 'real']) then 'number'
            when type like any(array['bigint', 'integer', 'smallint']) then 'integer'
            when type like 'boolean' then 'boolean'
            when type like '%[]' then 'array'
            when type like 'json' then 'object'
            when type like 'jsonb' then 'object'
            else 'string' end;
$$;

create or replace function oas_build_reference_to_schemas("schema" text)
returns jsonb language sql immutable as
$$
  select oas_reference_object(
    '#/components/schemas/' || "schema"
  );
$$;

create or replace function oas_build_reference_to_parameters(parameter text)
returns jsonb language sql immutable as
$$
  select oas_reference_object(
    '#/components/parameters/' || parameter
  );
$$;

create or replace function oas_build_reference_to_request_bodies(req_body text)
returns jsonb language sql immutable as
$$
  select oas_reference_object(
    ref := '#/components/requestBodies/' || req_body
  );
$$;

create or replace function oas_build_reference_to_responses(response text, descrip text default null)
returns jsonb language sql immutable as
$$
  select oas_reference_object(
    ref := '#/components/responses/' || response,
    description := descrip
  );
$$;
