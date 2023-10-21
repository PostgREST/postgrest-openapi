-- Functions to build the the OpenAPI output

create or replace function openapi_object(
  openapi text,
  info jsonb,
  paths jsonb,
  jsonSchemaDialect text default null,
  servers jsonb default null,
  webhooks jsonb default null,
  components jsonb default null,
  security jsonb default null,
  tags jsonb default null,
  externalDocs jsonb default null
)
  returns jsonb language sql as
$$
select jsonb_strip_nulls(
    jsonb_build_object(
         'openapi', openapi,
         'info', info,
         'paths', paths,
         'jsonSchemaDialect', jsonSchemaDialect,
         'servers', servers,
         'webhooks', webhooks,
         'components', components,
         'security', security,
         'tags', tags,
         'externalDocs', externalDocs
       )
  );
$$;

create or replace function openapi_server_object(
  url text,
  description text default null,
  variables jsonb default null
)
returns jsonb language sql as
$$
select jsonb_build_object(
  'url', url,
  'description', description,
  'variables', variables
)
$$;

create or replace function openapi_info_object(
  title text,
  version text,
  summary text default null,
  description text default null,
  termsOfService text default null,
  contact jsonb default null,
  license jsonb default null
)
  returns jsonb language sql as
$$
select jsonb_build_object(
    'title', title,
    'version', version,
    'summary', summary,
    'description', description,
    'termsOfService', termsOfService,
    'contact', contact,
    'license', license
  );
$$;

create or replace function openapi_components_object(
  schemas jsonb default null,
  responses jsonb default null,
  parameters jsonb default null,
  examples jsonb default null,
  requestBodies jsonb default null,
  headers jsonb default null,
  securitySchemes jsonb default null,
  links jsonb default null,
  callbacks jsonb default null,
  pathItems jsonb default null
)
  returns jsonb language sql as
$$
select json_build_object(
 'schemas', schemas,
 'responses', responses,
 'parameters', parameters,
 'examples', examples,
 'requestBodies', requestBodies,
 'headers', headers,
 'securitySchemes', securitySchemes,
 'links', links,
 'callbacks', callbacks,
 'pathItems', pathItems
);
$$;

create or replace function openapi_schema_object(
  title text default null,
  description text default null,
  enum jsonb default null,
  "default" text default null,
  format text default null,
  type text default null,
  items jsonb default null,
  maxItems integer default null,
  minItems integer default null,
  uniqueItems boolean default null,
  pattern text default null,
  maxLength integer default null,
  minLength integer default null,
  maximum numeric default null,
  exclusiveMaximum boolean default null,
  minimum numeric default null,
  exclusiveMinimum boolean default null,
  multipleOf numeric default null,
  required text[] default null,
  properties jsonb default null,
  additionalProperties jsonb default null,
  maxProperties integer default null,
  minProperties integer default null,
  allOf jsonb default null,
  oneOf jsonb default null,
  anyOf jsonb default null,
  "not" jsonb default null,
  discriminator jsonb default null,
  readOnly boolean default null,
  writeOnly boolean default null,
  xml jsonb default null,
  externalDocs jsonb default null,
  example jsonb default null,
  deprecated boolean default null
)
returns jsonb language sql as
$$
  -- TODO: build the JSON object according to the type
  select jsonb_build_object(
    'title', title,
    'description', description,
    'enum', enum,
    'default', "default",
    'format', format,
    'type', type,
    'items', items,
    'maxItems', maxItems,
    'minItems', minItems,
    'uniqueItems', uniqueItems,
    'pattern', pattern,
    'maxLength', maxLength,
    'minLength', minLength,
    'maximum', maximum,
    'exclusiveMaximum', exclusiveMaximum,
    'minimum', minimum,
    'exclusiveMinimum', exclusiveMinimum,
    'multipleOf', multipleOf,
    'required' , required,
    'properties', properties,
    'additionalProperties', additionalProperties,
    'maxProperties', maxProperties,
    'minProperties', minProperties,
    'allOf', allOf,
    'oneOf', oneOf,
    'anyOf', anyOf,
    'not', "not",
    'discriminator', discriminator,
    'readOnly', readOnly,
    'writeOnly', writeOnly,
    'xml', xml,
    'externalDocs', externalDocs,
    'example', example,
    'deprecated', deprecated
  )
$$;

create or replace function openapi_build_ref(ref text)
returns jsonb language sql as
$$
select json_build_object(
  '$ref', '#/components/schemas/' || ref
);
$$;
