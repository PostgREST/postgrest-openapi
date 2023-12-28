-- Functions to build the Components Object of the OAS document

create or replace function oas_build_components(schemas text[])
returns jsonb language sql as
$$
select oas_components_object(
  schemas := oas_build_component_schemas(schemas),
  parameters := oas_build_component_parameters(),
  securitySchemes := oas_build_component_security_schemes()
)
$$;

-- Schemas

create or replace function oas_build_component_schemas(schemas text[])
returns jsonb language sql as
$$
  select oas_build_component_schemas_from_tables(schemas) ||
         oas_build_component_schemas_from_composite_types(schemas)
$$;

create or replace function oas_build_component_schemas_from_tables(schemas text[])
returns jsonb language sql as
$$
select jsonb_object_agg(x.table_name, x.oas_schema)
from (
  select table_name,
    oas_schema_object(
      description := table_description,
      properties := columns,
      required := required_cols,
      type := 'object'
    ) as oas_schema
  from postgrest_get_all_tables(schemas)
  where table_schema = any(schemas)
) x;
$$;

create or replace function oas_build_component_schemas_from_composite_types(schemas text[])
returns jsonb language sql as
$$
SELECT coalesce(jsonb_object_agg(x.ct_name, x.oas_schema), '{}')
FROM (
  SELECT comptype_schema || '.' || comptype_name as ct_name,
         oas_schema_object(
           description := comptype_description,
           properties := columns,
           type := 'object'
         ) AS oas_schema
  FROM postgrest_get_all_composite_types(schemas)
) x;
$$;

-- Parameters

create or replace function oas_build_component_parameters()
returns jsonb language sql as
$$
  select oas_build_component_parameters_query_params() ||
         oas_build_component_parameters_headers();
$$;

create or replace function oas_build_component_parameters_query_params()
returns jsonb language sql as
$$
select jsonb_object_agg(name, param_object) from unnest(
  array['select','order', 'limit', 'offset', 'on_conflict', 'columns', 'or', 'and', 'not.or', 'not.and'],
  array[
    oas_parameter_object(
      name := 'select',
      "in" := 'query',
      description := 'Vertical filtering of columns',
      explode := false,
      schema := oas_schema_object(
        type := 'array',
        items := oas_schema_object(type := 'string')
      )
    ),
    oas_parameter_object(
      name := 'order',
      "in" := 'query',
      description := 'Ordering by column',
      explode := false,
      schema := oas_schema_object(
        type := 'array',
        items := oas_schema_object(type := 'string')
      )
    ),
    oas_parameter_object(
      name := 'limit',
      "in" := 'query',
      description := 'Limit the number of rows returned',
      explode := false,
      schema := oas_schema_object(
        type := 'integer'
      )
    ),
    oas_parameter_object(
      name := 'offset',
      "in" := 'query',
      description := 'Skip a certain number of rows',
      explode := false,
      schema := oas_schema_object(
        type := 'integer'
      )
    ),
    oas_parameter_object(
      name := 'on_conflict',
      "in" := 'query',
      description := 'Columns that resolve the upsert conflict',
      explode := false,
      schema := oas_schema_object(
        type := 'string'
      )
    ),
    oas_parameter_object(
      name := 'columns',
      "in" := 'query',
      description := 'Specify which keys from the payload will be inserted',
      explode := false,
      schema := oas_schema_object(
        type := 'string'
      )
    ),
    oas_parameter_object(
      name := 'or',
      "in" := 'query',
      description := 'Logical operator to combine filters using OR',
      explode := false,
      schema := oas_schema_object(
        type := 'string'
      )
    ),
    oas_parameter_object(
      name := 'and',
      "in" := 'query',
      description := 'Logical operator to combine filters using AND (the default for query params)',
      explode := false,
      schema := oas_schema_object(
        type := 'string'
      )
    ),
    oas_parameter_object(
      name := 'not.or',
      "in" := 'query',
      description := 'Negate the logical operator to combine filters using OR',
      explode := false,
      schema := oas_schema_object(
        type := 'string'
      )
    ),
    oas_parameter_object(
      name := 'not.and',
      "in" := 'query',
      description := 'Negate the logical operator to combine filters using AND',
      explode := false,
      schema := oas_schema_object(
        type := 'string'
      )
    )
  ]
) as _(name, param_object);
$$;

create or replace function oas_build_component_parameters_headers ()
returns jsonb language sql as
$$
select jsonb_object_agg(name, param_object) from unnest(
  array['preferParams', 'preferReturn', 'preferCount', 'preferResolution', 'preferTransaction', 'preferMissing', 'preferHandling', 'preferTimezone', 'preferMaxAffected', 'range'],
  array[
    oas_parameter_object(
      name := 'Prefer',
      "in" := 'header',
      description := 'Send JSON as a single parameter',
      schema := oas_schema_object(
        type := 'string',
        "enum" := jsonb_build_array(
          'params=single-object'
        )
      )
    ),
    oas_parameter_object(
      name := 'Prefer',
      "in" := 'header',
      description := 'Return information of the affected resource',
      schema := oas_schema_object(
        type := 'string',
        "enum" := jsonb_build_array(
          'return=minimal',
          'return=headers-only',
          'return=representation'
        )
      )
    ),
    oas_parameter_object(
      name := 'Prefer',
      "in" := 'header',
      description := 'Get the total size of the table',
      schema := oas_schema_object(
        type := 'string',
        "enum" := jsonb_build_array(
          'count=exact',
          'count=planned',
          'count=estimated'
        )
      )
    ),
    oas_parameter_object(
      name := 'Prefer',
      "in" := 'header',
      description := 'Handle duplicates in an upsert',
      schema := oas_schema_object(
        type := 'string',
        "enum" := jsonb_build_array(
          'resolution=merge-duplicates',
          'resolution=ignore-duplicates'
        )
      )
    ),
    oas_parameter_object(
      name := 'Prefer',
      "in" := 'header',
      description := 'Specify how to end a transaction',
      schema := oas_schema_object(
        type := 'string',
        "enum" := jsonb_build_array(
          'tx=commit',
          'tx=rollback'
        )
      )
    ),
    oas_parameter_object(
      name := 'Prefer',
      "in" := 'header',
      description := 'Handle null values in bulk inserts',
      schema := oas_schema_object(
        type := 'string',
        "enum" := jsonb_build_array(
          'missing=default',
          'missing=null'
        )
      )
    ),
    oas_parameter_object(
      name := 'Prefer',
      "in" := 'header',
      description := 'Handle invalid preferences',
      schema := oas_schema_object(
        type := 'string',
        "enum" := jsonb_build_array(
          'handling=strict',
          'handling=lenient'
        )
      )
    ),
    oas_parameter_object(
      name := 'Prefer',
      "in" := 'header',
      description := 'Specify the time zone',
      example := '"timezone=UTC"',
      schema := oas_schema_object(
        -- The time zones can be queried, but there are ~500 of them. It could slow down the UIs (unverified).
        type := 'string'
      )
    ),
    oas_parameter_object(
      name := 'Prefer',
      "in" := 'header',
      description := 'Limit the number of affected resources',
      example := '"max-affected=5"',
      schema := oas_schema_object(
        type := 'string'
      )
    ),
    oas_parameter_object(
      name := 'Range',
      "in" := 'header',
      description := 'For limits and pagination',
      example := '"5-10"',
      schema := oas_schema_object(
        type := 'string'
      )
    )
  ]
) as _(name, param_object);
$$;

-- Security Schemes

create or replace function oas_build_component_security_schemes ()
returns jsonb language sql as
$$
  select jsonb_build_object(
    'JWT', oas_security_scheme_object(
      type := 'http',
      description := 'Adds the JSON Web Token to the `Authorization: Bearer <JWT>` header.',
      scheme := 'bearer',
      bearerFormat := 'JWT'
    )
  );
$$;
