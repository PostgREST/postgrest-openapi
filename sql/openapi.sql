-- Functions and types to build the the OpenAPI output

-- TODO: create enum for openapi type e.g. string, number, etc.
create type oas_parameter_in as enum ('query', 'header', 'path', 'cookie');
create type oas_parameter_style as enum ('simple', 'form');
create type oas_security_scheme_in as enum ('query', 'header', 'cookie');
create type oas_security_scheme_type as enum ('apiKey', 'http', 'mutualTLS', 'oauth2', 'openIdConnect');

create or replace function oas_openapi_object(
  openapi text,
  info jsonb,
  xsoftware jsonb,
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
         'x-software', xsoftware,
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

create or replace function oas_info_object(
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

create or replace function oas_x_software_object(
  name text,
  version text,
  description text
)
  returns jsonb language sql as
$$
select json_build_object(
  'x-name', name,
  'x-version', version,
  'x-description', description
);
$$;

create or replace function oas_components_object(
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

create or replace function oas_schema_object(
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

create or replace function oas_reference_object(
  ref text,
  summary text default null,
  description text default null
)
returns jsonb language sql as
$$
select json_build_object(
  '$ref', ref,
  'summary', summary,
  'description', description
);
$$;

create or replace function oas_parameter_object(
  name text,
  "in" oas_parameter_in,
  description text default null,
  required boolean default null,
  deprecated boolean default null,
  allowEmptyValue boolean default null,
  style oas_parameter_style default null,
  explode boolean default null,
  "schema" jsonb default null,
  example jsonb default null,
  examples jsonb default null
)
returns jsonb language sql as
$$
  -- TODO: Add missing logic between fields (e.g. example and examples are mutually exclusive)
  select jsonb_build_object(
    'name', name,
    'in', "in",
    'description', description,
    'required', required,
    'deprecated', deprecated,
    'allowEmptyValue', allowEmptyValue,
    'style', style,
    'explode', explode,
    'schema', "schema",
    'example', example,
    'examples', examples
  )
$$;

create or replace function oas_security_scheme_object(
  type oas_security_scheme_type,
  description text default null,
  -- TODO: the following should be required depending on the "type"
  name text default null,
  "in" oas_security_scheme_in default null,
  scheme text default null,
  bearerFormat text default null,
  flows jsonb default null,
  openIdConnectUrl text default null
)
returns jsonb language sql as
$$
  select jsonb_build_object(
    'type', type,
    'description', description,
    'name', name,
    'in', "in",
    'scheme', scheme,
    'bearerFormat', bearerFormat,
    'flows', flows,
    'openIdConnectUrl', openIdConnectUrl
  );
$$;

create or replace function oas_example_object(
  summary text default null,
  description text default null,
  value jsonb default null,
  externalValue text default null
)
returns jsonb language sql as
$$
  select jsonb_build_object(
    'summary', summary,
    'description', description,
    'value', value,
    'externalValue', externalValue
  );
$$;
