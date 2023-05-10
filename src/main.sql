-- Functions to get information for the OpenAPI output

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

create or replace function openapi_paths_object(
  paths jsonb
)
returns jsonb language sql as
$$
select jsonb_build_object(
  'paths', paths
);
$$;

-- Minimal required OpenAPI object

create or replace function get_openapi_spec()
returns jsonb language sql as
$$
select openapi_object(
  '3.1.0',
  openapi_info_object(
    title := 'PostgREST API',
    version := '11.0.1 (4197d2f)'
  ),
  openapi_paths_object(
    paths := '{}'
  )
);
$$;
