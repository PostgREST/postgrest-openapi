-- Functions to build the Paths Object of the OAS document

create or replace function oas_build_paths(schemas text[])
returns jsonb language sql stable as
$$
  select oas_build_path_item_root() ||
         oas_build_path_items_from_tables(schemas) ||
         oas_build_path_items_from_functions(schemas);
$$;

create or replace function oas_build_path_items_from_tables(schemas text[])
returns jsonb language sql stable as
$$
select jsonb_object_agg(x.path, x.oas_path_item)
from (
  select '/' || table_name as path,
    oas_path_item_object(
      get :=oas_operation_object(
        summary := (postgrest_unfold_comment(table_description))[1],
        description := (postgrest_unfold_comment(table_description))[2],
        tags := array[table_name],
        parameters := jsonb_agg(
          oas_build_reference_to_parameters(format('rowFilter.%1$s.%2$s', table_full_name, column_name))
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
          oas_build_reference_to_responses('notEmpty.' || table_full_name, 'OK'),
          '206',
          oas_build_reference_to_responses('notEmpty.' || table_full_name, 'Partial Content'),
          'default',
          oas_build_reference_to_responses('defaultError', 'Error')
        )
      ),
      post :=
        case when insertable then
          oas_operation_object(
            summary := (postgrest_unfold_comment(table_description))[1],
            description := (postgrest_unfold_comment(table_description))[2],
            tags := array[table_name],
            requestBody := oas_build_reference_to_request_bodies(table_full_name),
            parameters := jsonb_build_array(
              oas_build_reference_to_parameters('select'),
              oas_build_reference_to_parameters('columns'),
              oas_build_reference_to_parameters('preferPost')
            ),
            responses := jsonb_build_object(
              '201',
              oas_build_reference_to_responses('mayBeEmpty.' || table_full_name, 'Created'),
              'default',
              oas_build_reference_to_responses('defaultError', 'Error')
            )
          )
        end,
      patch :=
        case when updatable then
          oas_operation_object(
            summary := (postgrest_unfold_comment(table_description))[1],
            description := (postgrest_unfold_comment(table_description))[2],
            tags := array[table_name],
            requestBody := oas_build_reference_to_request_bodies(table_full_name),
            parameters := jsonb_agg(
              oas_build_reference_to_parameters(format('rowFilter.%1$s.%2$s', table_full_name, column_name))
            ) ||
            jsonb_build_array(
              oas_build_reference_to_parameters('select'),
              oas_build_reference_to_parameters('columns'),
              oas_build_reference_to_parameters('order'),
              oas_build_reference_to_parameters('limit'),
              oas_build_reference_to_parameters('or'),
              oas_build_reference_to_parameters('and'),
              oas_build_reference_to_parameters('not.or'),
              oas_build_reference_to_parameters('not.and'),
              oas_build_reference_to_parameters('preferPatch')
            ),
            responses := jsonb_build_object(
              '200',
              oas_build_reference_to_responses('notEmpty.' || table_full_name, 'OK'),
              '204',
              oas_build_reference_to_responses('empty', 'No Content'),
              'default',
              oas_build_reference_to_responses('defaultError', 'Error')
            )
          )
        end,
      delete :=
        case when deletable then
          oas_operation_object(
            summary := (postgrest_unfold_comment(table_description))[1],
            description := (postgrest_unfold_comment(table_description))[2],
            tags := array[table_name],
            parameters := jsonb_agg(
              oas_build_reference_to_parameters(format('rowFilter.%1$s.%2$s', table_full_name, column_name))
            ) ||
            jsonb_build_array(
              oas_build_reference_to_parameters('select'),
              oas_build_reference_to_parameters('order'),
              oas_build_reference_to_parameters('limit'),
              oas_build_reference_to_parameters('or'),
              oas_build_reference_to_parameters('and'),
              oas_build_reference_to_parameters('not.or'),
              oas_build_reference_to_parameters('not.and'),
              oas_build_reference_to_parameters('preferDelete')
            ),
            responses := jsonb_build_object(
              '200',
              oas_build_reference_to_responses('notEmpty.' || table_full_name, 'OK'),
              '204',
              oas_build_reference_to_responses('empty', 'No Content'),
              'default',
              oas_build_reference_to_responses('defaultError', 'Error')
            )
          )
        end
    ) as oas_path_item
  from (
   select table_schema, table_name, table_full_name, table_description, insertable, updatable, deletable, column_name
   from postgrest_get_all_tables_and_composite_types()
   where table_schema = any(schemas)
     and (is_table or is_view)
   order by table_schema, table_name, column_position
  ) _
  group by table_schema, table_name, table_full_name, table_description, insertable, updatable, deletable
) x;
$$;

create or replace function oas_build_path_items_from_functions(schemas text[])
returns jsonb language sql stable as
$$
select jsonb_object_agg(x.path, x.oas_path_item)
from (
  select '/rpc/' || function_name as path,
    oas_path_item_object(
      get :=oas_operation_object(
        summary := (postgrest_unfold_comment(function_description))[1],
        description := (postgrest_unfold_comment(function_description))[2],
        tags := array['(rpc) ' || function_name],
        parameters :=
          coalesce(
            jsonb_agg(
              oas_build_reference_to_parameters(format('rpcParam.%1$s.%2$s', function_full_name, argument_name))
            ) filter ( where argument_name <> '' and (argument_is_in or argument_is_inout or argument_is_variadic)),
            '[]'
          ) ||
          case when return_type_is_table or return_type_is_out or return_type_composite_relid <> 0 then
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
            )
          else
            jsonb_build_array(
              oas_build_reference_to_parameters('preferGet')
            )
          end,
        responses :=
          case when return_type_is_set then
            jsonb_build_object(
              '200',
              oas_build_reference_to_responses('rpc.' || function_full_name, 'OK'),
              '206',
              oas_build_reference_to_responses('rpc.' || function_full_name, 'Partial Content')
            )
          else
            jsonb_build_object(
              '200',
              oas_build_reference_to_responses('rpc.' || function_full_name, 'OK')
            )
          end ||
          jsonb_build_object(
            'default',
            oas_build_reference_to_responses('defaultError', 'Error')
          )
      ),
      post := oas_operation_object(
        summary := (postgrest_unfold_comment(function_description))[1],
        description := (postgrest_unfold_comment(function_description))[2],
        tags := array['(rpc) ' || function_name],
        requestBody := case when argument_input_qty > 0 then oas_build_reference_to_request_bodies('rpc.' || function_full_name) end,
        parameters :=
          -- TODO: The row filters for functions returning TABLE, OUT, INOUT and composite types should also work for the GET path.
          --       Right now they're not included in GET, because the argument names (in rpcParams) could clash with the name of the return type columns (in rowFilter).
          coalesce(
            jsonb_agg(
              oas_build_reference_to_parameters(format('rowFilter.rpc.%1$s.%2$s', function_full_name, argument_name))
            ) filter ( where argument_name <> '' and (argument_is_inout or argument_is_out or argument_is_table)),
            '[]'
          ) ||
          return_composite_param_ref ||
          case when return_type_is_table or return_type_is_out or return_type_composite_relid <> 0 then
            jsonb_build_array(
              oas_build_reference_to_parameters('select'),
              oas_build_reference_to_parameters('order'),
              oas_build_reference_to_parameters('limit'),
              oas_build_reference_to_parameters('offset'),
              oas_build_reference_to_parameters('or'),
              oas_build_reference_to_parameters('and'),
              oas_build_reference_to_parameters('not.or'),
              oas_build_reference_to_parameters('not.and'),
              oas_build_reference_to_parameters('preferPostRpc')
            )
          else
            jsonb_build_array(
              oas_build_reference_to_parameters('preferPostRpc')
            )
          end,
        responses :=
          case when return_type_is_set then
            jsonb_build_object(
              '200',
              oas_build_reference_to_responses('rpc.' || function_full_name, 'OK'),
              '206',
              oas_build_reference_to_responses('rpc.' || function_full_name, 'Partial Content')
            )
          else
            jsonb_build_object(
              '200',
              oas_build_reference_to_responses('rpc.' || function_full_name, 'OK')
            )
          end ||
          jsonb_build_object(
            'default',
            oas_build_reference_to_responses('defaultError', 'Error')
          )
      )
    ) as oas_path_item
  from (
    select function_name, function_full_name, function_description, return_type_name, return_type_is_set, return_type_is_table, return_type_is_out, return_type_composite_relid, argument_name, argument_is_in, argument_is_inout, argument_is_out, argument_is_table, argument_is_variadic, argument_input_qty,
           comp.return_composite_param_ref
    from postgrest_get_all_functions(schemas) f
    left join lateral (
      select coalesce(jsonb_agg(oas_build_reference_to_parameters(format('rowFilter.%1$s.%2$s', table_full_name, column_name))),'[]') as return_composite_param_ref
      from (
        select c.table_full_name, c.column_name
        from postgrest_get_all_tables_and_composite_types() c
        where f.return_type_composite_relid = c.table_oid
      ) _
    ) comp on true
  ) _
  group by function_name, function_full_name, function_description, return_type_name, return_type_is_set, return_type_is_table, return_type_is_out, return_type_composite_relid, argument_input_qty, return_composite_param_ref
) x;
$$;

create or replace function oas_build_path_item_root()
returns jsonb language sql stable as
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
