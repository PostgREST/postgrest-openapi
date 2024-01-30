-- Functions to build the Paths Object of the OAS document

create or replace function oas_build_paths(schemas text[])
returns jsonb language sql as
$$
  select oas_build_path_item_root() ||
         oas_build_path_items_from_tables(schemas);
$$;

create or replace function oas_build_path_items_from_tables(schemas text[])
returns jsonb language sql as
$$
select jsonb_object_agg(x.path, x.oas_path_item)
from (
  select '/' || table_name as path,
    oas_path_item_object(
      get :=oas_operation_object(
        description := table_description,
        tags := array[table_name],
        parameters := jsonb_agg(
          oas_build_reference_to_parameters(format('rowFilter.%1$s.%2$s', table_name, column_name))
        ) ||
        jsonb_build_array(
          oas_build_reference_to_parameters('select'),
          oas_build_reference_to_parameters('order'),
          oas_build_reference_to_parameters('limit'),
          oas_build_reference_to_parameters('offset'),
          oas_build_reference_to_parameters('or'),
          oas_build_reference_to_parameters('and'),
          oas_build_reference_to_parameters('not.or'),
          oas_build_reference_to_parameters('not.and'),
          oas_build_reference_to_parameters('range'),
          oas_build_reference_to_parameters('preferGet')
        ),
        responses := jsonb_build_object(
          '200',
          oas_build_reference_to_responses('get.' || table_name, 'OK'),
          '206',
          oas_build_reference_to_responses('get.' || table_name, 'Partial Content'),
          'default',
          oas_build_reference_to_responses('defaultError', 'Error')
        )
      ),
      post :=
        case when insertable then
          oas_operation_object(
            description := table_description,
            tags := array[table_name],
            requestBody := oas_build_reference_to_request_bodies(table_name),
            parameters := jsonb_build_array(
              oas_build_reference_to_parameters('select'),
              oas_build_reference_to_parameters('columns'),
              oas_build_reference_to_parameters('preferPost')
            ),
            responses := jsonb_build_object(
              '201',
              oas_build_reference_to_responses('post.' || table_name, 'Created'),
              'default',
              oas_build_reference_to_responses('defaultError', 'Error')
            )
          )
        end
    ) as oas_path_item
  from (
   select table_schema, table_name, table_description, insertable, unnest(all_cols) as column_name
   from postgrest_get_all_tables(schemas)
  ) _
  where table_schema = any(schemas)
  group by table_schema, table_name, table_description, insertable
) x;
$$;

create or replace function oas_build_path_item_root()
returns jsonb language sql as
$$
select
  jsonb_build_object(
    '/',
    oas_path_item_object(
      get := oas_operation_object(
        description := 'OpenAPI description (this document)',
        tags := array['Introspection'],
        responses := jsonb_build_object(
          '200',
          oas_response_object(
            description := 'OK',
            content := jsonb_build_object(
              'application/json',
              oas_media_type_object(
                schema := oas_schema_object(
                  type := 'object'
                )
              ),
              'application/openapi+json',
              oas_media_type_object(
                schema := oas_schema_object(
                  type := 'object'
                )
              )
            )
          )
        )
      )
    )
  );
$$;
