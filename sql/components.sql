-- Functions to build the Components Object of the OAS document

create or replace function oas_build_components(schemas text[])
returns jsonb language sql stable as
$$
select oas_components_object(
  schemas := oas_build_component_schemas(schemas),
  parameters := oas_build_component_parameters(schemas),
  requestBodies := oas_build_request_bodies(schemas),
  responses := oas_build_response_objects(schemas),
  securitySchemes := oas_build_component_security_schemes()
)
$$;

-- Schemas

create or replace function oas_build_component_schemas(schemas text[])
returns jsonb language sql stable as
$$
  select oas_build_component_schemas_from_tables(schemas) ||
         oas_build_component_schemas_from_composite_types(schemas) ||
         oas_build_component_schemas_headers()
$$;

create or replace function oas_build_component_schemas_from_tables(schemas text[])
returns jsonb language sql stable as
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
returns jsonb language sql stable as
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

create or replace function oas_build_component_schemas_headers()
returns jsonb language sql stable as
$$
select jsonb_build_object(
  'header.preferParams',
  oas_schema_object(
    type := 'object',
    properties := jsonb_build_object(
      'params',
      oas_schema_object(
        description := 'Send JSON as a single parameter',
        type := 'string',
        "enum" := '["single-object"]',
        deprecated := true
      )
    )
  ),
  'header.preferReturn',
  oas_schema_object(
    type:= 'object',
    properties := jsonb_build_object(
      'return',
      oas_schema_object(
        description := 'Return information of the affected resource',
        type := 'string',
        "enum" := '["minimal", "headers-only", "representation"]',
        "default" := 'minimal'
      )
    )
  ),
  'header.preferCount',
  oas_schema_object(
    type:= 'object',
    properties := jsonb_build_object(
      'count',
      oas_schema_object(
        description := 'Get the total size of the table',
        type := 'string',
        "enum" := '["exact", "planned", "estimated"]'
      )
    )
  ),
  'header.preferResolution',
  oas_schema_object(
    type:= 'object',
    properties := jsonb_build_object(
      'resolution',
      oas_schema_object(
        description := 'Handle duplicates in an upsert',
        type := 'string',
        "enum" := '["merge-duplicates", "ignore-duplicates"]'
      )
    )
  ),
  'header.preferTx',
  oas_schema_object(
    type:= 'object',
    properties := jsonb_build_object(
      'tx',
      oas_schema_object(
        description := 'Specify how to end a transaction',
        type := 'string',
        "enum" := '["commit", "rollback"]'
      )
    )
  ),
  'header.preferMissing',
  oas_schema_object(
    type:= 'object',
    properties := jsonb_build_object(
      'missing',
      oas_schema_object(
        description := 'Handle null values in bulk inserts',
        type := 'string',
        "enum" := '["default", "null"]',
        "default" := 'null'
      )
    )
  ),
  'header.preferHandling',
  oas_schema_object(
    type:= 'object',
    properties := jsonb_build_object(
      'handling',
      oas_schema_object(
        description := 'How to handle invalid preferences',
        type := 'string',
        "enum" := '["strict", "lenient"]',
        "default" := 'lenient'
      )
    )
  ),
  'header.preferTimezone',
  oas_schema_object(
    type:= 'object',
    properties := jsonb_build_object(
      'timezone',
      oas_schema_object(
        description := 'Specify the time zone',
        type := 'string'
      )
    )
  ),
  'header.preferMaxAffected',
  oas_schema_object(
    type:= 'object',
    properties := jsonb_build_object(
      'max-affected',
      oas_schema_object(
        description := 'Specify the amount of resources affected',
        type := 'integer'
      )
    )
  )
)
$$;

-- Parameters

create or replace function oas_build_component_parameters(schemas text[])
returns jsonb language sql stable as
$$
  select oas_build_component_parameters_query_params_from_tables(schemas) ||
         oas_build_component_parameters_query_params_common() ||
         oas_build_component_parameters_headers_common();
$$;

create or replace function oas_build_component_parameters_query_params_from_tables(schemas text[])
returns jsonb language sql stable as
$$
select jsonb_object_agg(x.param_name, x.param_schema)
from (
  select format('rowFilter.%1$s.%2$s', table_name, column_name) as param_name,
    oas_parameter_object(
      name := column_name,
      "in" := 'query',
      schema := oas_schema_object(
        type := 'string'
      )
    ) as param_schema
  from (
     select table_schema, table_name, unnest(all_cols) as column_name
     from postgrest_get_all_tables(schemas)
  ) _
  where table_schema = any(schemas)
) x;
$$;

create or replace function oas_build_component_parameters_query_params_common()
returns jsonb language sql stable as
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

create or replace function oas_build_component_parameters_headers_common ()
returns jsonb language sql stable as
$$
select jsonb_build_object(
  'preferGet',
  oas_parameter_object(
    name := 'Prefer',
    "in" := 'header',
    explode := true,
    description := 'Specify a required or optional behavior for the request',
    "schema" := oas_schema_object(
      allOf := jsonb_build_array(
        oas_build_reference_to_schemas('header.preferHandling'),
        oas_build_reference_to_schemas('header.preferTimezone'),
        oas_build_reference_to_schemas('header.preferCount')
      )
    ),
    examples := jsonb_build_object(
      'nothing',
      oas_example_object(
        summary := 'No preferences'
      ),
      'all',
      oas_example_object(
        summary := 'All default preferences',
        value := '{
          "handling":"lenient",
          "timezone": "",
          "count": ""
        }'
      )
    )
  ),
  'preferPost',
  oas_parameter_object(
    name := 'Prefer',
    "in" := 'header',
    explode := true,
    description := 'Specify a required or optional behavior for the request',
    "schema" := oas_schema_object(
      allOf := jsonb_build_array(
        oas_build_reference_to_schemas('header.preferHandling'),
        oas_build_reference_to_schemas('header.preferTimezone'),
        oas_build_reference_to_schemas('header.preferReturn'),
        oas_build_reference_to_schemas('header.preferCount'),
        oas_build_reference_to_schemas('header.preferResolution'),
        oas_build_reference_to_schemas('header.preferMissing'),
        oas_build_reference_to_schemas('header.preferTx')
      )
    ),
    examples := jsonb_build_object(
      'nothing',
      oas_example_object(
        summary := 'No preferences'
      ),
      'all',
      oas_example_object(
        summary := 'All default preferences',
        value := '{
          "handling": "lenient",
          "timezone": "",
          "return": "minimal",
          "count": "",
          "resolution": "",
          "missing": "null",
          "tx": "commit"
        }'
      )
    )
  ),
  'preferPatch',
  oas_parameter_object(
    name := 'Prefer',
    "in" := 'header',
    explode := true,
    description := 'Specify a required or optional behavior for the request',
    "schema" := oas_schema_object(
      allOf := jsonb_build_array(
        oas_build_reference_to_schemas('header.preferHandling'),
        oas_build_reference_to_schemas('header.preferTimezone'),
        oas_build_reference_to_schemas('header.preferReturn'),
        oas_build_reference_to_schemas('header.preferCount'),
        oas_build_reference_to_schemas('header.preferTx'),
        oas_build_reference_to_schemas('header.preferMaxAffected')
      )
    ),
    examples := jsonb_build_object(
      'nothing',
      oas_example_object(
        summary := 'No preferences'
      ),
      'all',
      oas_example_object(
        summary := 'All default preferences',
        value := '{
          "handling": "lenient",
          "timezone": "",
          "return": "minimal",
          "count": "",
          "max-affected": "",
          "tx": "commit"
        }'
      )
    )
  ),
  'preferPut',
  oas_parameter_object(
    name := 'Prefer',
    "in" := 'header',
    explode := true,
    description := 'Specify a required or optional behavior for the request',
    "schema" := oas_schema_object(
      allOf := jsonb_build_array(
        oas_build_reference_to_schemas('header.preferHandling'),
        oas_build_reference_to_schemas('header.preferTimezone'),
        oas_build_reference_to_schemas('header.preferReturn'),
        oas_build_reference_to_schemas('header.preferCount'),
        oas_build_reference_to_schemas('header.preferTx')
      )
    ),
    examples := jsonb_build_object(
      'nothing',
      oas_example_object(
        summary := 'No preferences'
      ),
      'all',
      oas_example_object(
        summary := 'All default preferences',
        value := '{
          "handling": "lenient",
          "timezone": "",
          "return": "minimal",
          "count": "",
          "tx": "commit"
        }'
      )
    )
  ),
  'preferDelete',
  oas_parameter_object(
    name := 'Prefer',
    "in" := 'header',
    explode := true,
    description := 'Specify a required or optional behavior for the request',
    "schema" := oas_schema_object(
      allOf := jsonb_build_array(
        oas_build_reference_to_schemas('header.preferHandling'),
        oas_build_reference_to_schemas('header.preferTimezone'),
        oas_build_reference_to_schemas('header.preferReturn'),
        oas_build_reference_to_schemas('header.preferCount'),
        oas_build_reference_to_schemas('header.preferTx'),
        oas_build_reference_to_schemas('header.preferMaxAffected')
      )
    ),
    examples := jsonb_build_object(
      'nothing',
      oas_example_object(
        summary := 'No preferences'
      ),
      'all',
      oas_example_object(
        summary := 'All default preferences',
        value := '{
          "handling": "lenient",
          "timezone": "",
          "return": "minimal",
          "count": "",
          "max-affected": "",
          "tx": "commit"
        }'
      )
    )
  ),
  'preferPostRpc',
  oas_parameter_object(
    name := 'Prefer',
    "in" := 'header',
    explode := true,
    description := 'Specify a required or optional behavior for the request',
    "schema" := oas_schema_object(
      allOf := jsonb_build_array(
        oas_build_reference_to_schemas('header.preferHandling'),
        oas_build_reference_to_schemas('header.preferTimezone'),
        oas_build_reference_to_schemas('header.preferCount'),
        oas_build_reference_to_schemas('header.preferTx'),
        oas_build_reference_to_schemas('header.preferParams')
      )
    ),
    examples := jsonb_build_object(
      'nothing',
      oas_example_object(
        summary := 'No preferences'
      ),
      'all',
      oas_example_object(
        summary := 'All default preferences',
        value := '{
          "handling": "lenient",
          "timezone": "",
          "count": "",
          "tx": "commit",
          "params": ""
        }'
      )
    )
  ),
  'range',
  oas_parameter_object(
    name := 'Range',
    "in" := 'header',
    description := 'For limits and pagination',
    example := '"0-4"',
    "schema" := oas_schema_object(
      type := 'string'
    )
  )
);
$$;

-- Responses

create or replace function oas_build_response_objects(schemas text[])
returns jsonb language sql stable as
$$
select oas_build_response_objects_from_tables(schemas) ||
       oas_build_response_objects_common();
$$;

create or replace function oas_build_response_objects_from_tables(schemas text[])
returns jsonb language sql stable as
$$
select jsonb_object_agg(x.not_empty, x.not_empty_response) ||
       jsonb_object_agg(x.may_be_empty, x.may_be_empty_response)
from (
  select 'notEmpty.' || table_name as not_empty,
    oas_response_object(
      description := 'Media types when response body is not empty for ' || table_name,
      content := jsonb_build_object(
        'application/json',
        oas_media_type_object(
          schema := oas_schema_object(
            type := 'array',
            items := oas_build_reference_to_schemas(table_name)
          )
        ),
        'application/vnd.pgrst.object+json',
        oas_media_type_object(
          schema := oas_build_reference_to_schemas(table_name)
        ),
        'application/vnd.pgrst.object+json;nulls=stripped',
        oas_media_type_object(
          schema := oas_build_reference_to_schemas(table_name)
        ),
        'text/csv',
        oas_media_type_object(
          schema := oas_schema_object(
            type := 'string',
            format := 'csv'
          )
        )
      )
    ) as not_empty_response,
    'mayBeEmpty.' || table_name as may_be_empty,
    case when insertable then
      oas_response_object(
        description := 'Media types when response body could be empty or not for ' || table_name,
        content := jsonb_build_object(
          'application/json',
          oas_media_type_object(
            schema := oas_schema_object(
              oneof := jsonb_build_array(
                oas_schema_object(
                  type := 'array',
                  items := oas_build_reference_to_schemas(table_name)
                ),
                oas_schema_object(
                  type := 'string'
                )
              )
            )
          ),
          'application/vnd.pgrst.object+json',
          oas_media_type_object(
            schema := oas_schema_object(
              oneOf := jsonb_build_array(
                oas_build_reference_to_schemas(table_name),
                oas_schema_object(
                    type := 'string'
                  )
              )
            )
          ),
          'application/vnd.pgrst.object+json;nulls=stripped',
          oas_media_type_object(
            schema := oas_schema_object(
              oneOf := jsonb_build_array(
                oas_build_reference_to_schemas(table_name),
                oas_schema_object(
                    type := 'string'
                  )
              )
            )
          ),
          'text/csv',
          oas_media_type_object(
            schema := oas_schema_object(
              type := 'string',
              format := 'csv'
            )
          )
        )
      )
    end as may_be_empty_response
  from postgrest_get_all_tables(schemas)
  where table_schema = any(schemas)
) as x
$$;

create or replace function oas_build_response_objects_common()
returns jsonb language sql stable as
$$
select jsonb_build_object(
  'defaultError',
  oas_response_object(
    description := 'Default error reponse',
    content := jsonb_build_object(
      'application/json',
      oas_media_type_object(
        schema := oas_schema_object(
          type := 'object',
          properties := jsonb_build_object(
            'code', oas_schema_object(type := 'string'),
            'details', oas_schema_object(type := 'string'),
            'hint', oas_schema_object(type := 'string'),
            'message', oas_schema_object(type := 'string')
          )
        )
      )
    )
  ),
  'empty',
  oas_response_object(
    description := 'No media types when response body is empty'
    -- Does not specify a "content": https://swagger.io/docs/specification/describing-responses/#empty
  )
);
$$;

-- Request bodies

create or replace function oas_build_request_bodies(schemas text[])
returns jsonb language sql stable as
$$
select oas_build_request_bodies_from_tables(schemas);
$$;

create or replace function oas_build_request_bodies_from_tables(schemas text[])
returns jsonb language sql stable as
$$
select jsonb_object_agg(x.table_name, x.oas_req_body)
from (
  select
    table_name,
    oas_request_body_object(
      description := table_name,
      content := jsonb_build_object(
        'application/json',
        oas_media_type_object(
          "schema" := oas_schema_object(
            oneOf := jsonb_build_array(
              oas_build_reference_to_schemas(table_name),
              oas_schema_object(
                type := 'array',
                items := oas_build_reference_to_schemas(table_name)
              )
            )
          )
        ),
        'application/x-www-form-urlencoded',
        oas_media_type_object(
          "schema" := oas_build_reference_to_schemas(table_name)
        ),
        'text/csv',
        oas_media_type_object(
          "schema" := oas_schema_object(
            type := 'string',
            format := 'csv'
          )
        )
      )
    ) as oas_req_body
  from postgrest_get_all_tables(schemas)
  where table_schema = any(schemas)
    and insertable
) as x;
$$;

-- Security Schemes

create or replace function oas_build_component_security_schemes ()
returns jsonb language sql stable as
$$
select jsonb_build_object(
  'JWT',
  oas_security_scheme_object(
    type := 'http',
    description := 'Adds the JSON Web Token to the `Authorization: Bearer <JWT>` header.',
    scheme := 'bearer',
    bearerFormat := 'JWT'
  )
);
$$;
