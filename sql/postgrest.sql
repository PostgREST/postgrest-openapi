-- Functions to get information from PostgREST to generate the OpenAPI output

-- TODO: simplify the query to have only relevant info for OpenAPI
-- TODO: to keep it reusable it may need to return data as is without using OAS objects.
--       To do so, "columns" has to be normalized (not a JSON aggregate)
create or replace function postgrest_get_all_tables(schemas text[])
returns table (
  table_schema text,
  table_name text,
  table_description text,
  is_view bool,
  insertable bool,
  updatable bool,
  deletable bool,
  pk_cols text[],
  composite_cols oid[],
  required_cols text[],
  all_cols text[],
  columns jsonb
) language sql stable as
$$
WITH
  columns AS (
    SELECT
      nc.nspname::name AS table_schema,
      c.relname::name AS table_name,
      a.attname::name AS column_name,
      d.description AS description,
      CASE
        WHEN a.attidentity  = 'd' THEN format('nextval(%s)', quote_literal(seqsch.nspname || '.' || seqclass.relname))
        WHEN a.attgenerated = 's' THEN null
        ELSE pg_get_expr(ad.adbin, ad.adrelid)::text
        END AS column_default,
      not (a.attnotnull OR t.typtype = 'd' AND t.typnotnull) AS is_nullable,
      t.typarray = 0 AS is_array,
      t.typtype = 'c' AS is_composite,
      t.typrelid AS composite_oid,
      CASE
        WHEN t.typtype = 'd' THEN
          CASE
            WHEN nbt.nspname = 'pg_catalog'::name THEN format_type(t.typbasetype, NULL::integer)
            ELSE format_type(a.atttypid, a.atttypmod)
            END
        ELSE
          CASE
            WHEN nt.nspname = 'pg_catalog'::name THEN format_type(a.atttypid, NULL::integer)
            ELSE format_type(a.atttypid, a.atttypmod)
            END
        END::text AS data_type,
      t.oid AS data_type_id,
      information_schema._pg_char_max_length(
          information_schema._pg_truetypid(a.*, t.*),
          information_schema._pg_truetypmod(a.*, t.*)
        )::integer AS character_maximum_length,
      COALESCE(bt.typname, t.typname)::name AS udt_name,
      a.attnum::integer AS position,
      CASE
        WHEN t_arr.typtype = 'd' THEN
          CASE
            WHEN nbt_arr.nspname = 'pg_catalog'::name THEN format_type(t_arr.typbasetype, NULL::integer)
            ELSE format_type(t_arr.oid, t_arr.typtypmod)
            END
        ELSE
          CASE
            WHEN nt_arr.nspname = 'pg_catalog'::name THEN format_type(t_arr.oid, NULL::integer)
            ELSE format_type(t_arr.oid, t_arr.typtypmod)
            END
        END::text AS item_data_type,
      t_arr.typtype = 'c' AS item_is_composite,
      t_arr.typrelid AS item_composite_oid,
      t_arr.oid AS item_data_type_id
    FROM pg_attribute a
      LEFT JOIN pg_description AS d
        ON d.objoid = a.attrelid and d.objsubid = a.attnum
      LEFT JOIN pg_attrdef ad
        ON a.attrelid = ad.adrelid AND a.attnum = ad.adnum
      JOIN (pg_class c JOIN pg_namespace nc ON c.relnamespace = nc.oid)
        ON a.attrelid = c.oid
      JOIN (pg_type t JOIN pg_namespace nt ON t.typnamespace = nt.oid)
        ON a.atttypid = t.oid
      LEFT JOIN (pg_type bt JOIN pg_namespace nbt ON bt.typnamespace = nbt.oid)
        ON t.typtype = 'd' AND t.typbasetype = bt.oid
      LEFT JOIN (pg_type t_arr JOIN pg_namespace nt_arr ON t_arr.typnamespace = nt_arr.oid)
        ON t.oid = t_arr.typarray
      LEFT JOIN (pg_type bt_arr JOIN pg_namespace nbt_arr ON bt_arr.typnamespace = nbt_arr.oid)
        ON t_arr.typtype = 'd' AND t_arr.typbasetype = bt_arr.oid
      LEFT JOIN (pg_collation co JOIN pg_namespace nco ON co.collnamespace = nco.oid)
        ON a.attcollation = co.oid AND (nco.nspname <> 'pg_catalog'::name OR co.collname <> 'default'::name)
      LEFT JOIN pg_depend dep
        ON dep.refobjid = a.attrelid and dep.refobjsubid = a.attnum and dep.deptype = 'i'
      LEFT JOIN pg_class seqclass
        ON seqclass.oid = dep.objid
      LEFT JOIN pg_namespace seqsch
        ON seqsch.oid = seqclass.relnamespace
    WHERE
      NOT pg_is_other_temp_schema(nc.oid)
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND c.relkind in ('r', 'v', 'f', 'm', 'p')
      AND nc.nspname = ANY(schemas)
  ),
   columns_agg AS (
    SELECT DISTINCT
      info.table_schema AS table_schema,
      info.table_name AS table_name,
      array_agg(coalesce(info.composite_oid, info.item_composite_oid)) filter (where info.is_composite or info.item_is_composite) AS composite_cols,
      array_agg(info.column_name order by info.position) filter (where not info.is_nullable) AS required_cols,
      array_agg(info.column_name order by info.position) AS all_cols,
      jsonb_object_agg(
        info.column_name,
          case when info.is_composite then
            oas_build_reference_to_schemas(info.data_type)
          else
            oas_schema_object(
              description :=  info.description,
              type := pgtype_to_oastype(info.data_type),
              format := info.data_type::text,
              maxlength := info.character_maximum_length,
              -- "default" :=  to_jsonb(info.column_default),
              enum := to_jsonb(enum_info.vals),
              items :=
                case
                when not info.is_array then
                  null
                when info.item_is_composite then
                  oas_build_reference_to_schemas(info.item_data_type)
                else
                  oas_schema_object(
                    type := pgtype_to_oastype(info.item_data_type),
                    format := info.item_data_type::text
                  )
                end
            )
          end order by info.position
      ) as columns
    FROM columns info
    LEFT OUTER JOIN (
      SELECT
        n.nspname AS s,
        t.typname AS n,
        array_agg(e.enumlabel ORDER BY e.enumsortorder) AS vals
      FROM pg_type t
             JOIN pg_enum e ON t.oid = e.enumtypid
             JOIN pg_namespace n ON n.oid = t.typnamespace
      GROUP BY s,n
    ) AS enum_info ON info.udt_name = enum_info.n
    WHERE info.table_schema NOT IN ('pg_catalog', 'information_schema')
    GROUP BY info.table_schema, info.table_name
  ),
  tbl_constraints AS (
    SELECT
      c.conname::name AS constraint_name,
      nr.nspname::name AS table_schema,
      r.relname::name AS table_name
    FROM pg_namespace nc
      JOIN pg_constraint c ON nc.oid = c.connamespace
      JOIN pg_class r ON c.conrelid = r.oid
      JOIN pg_namespace nr ON nr.oid = r.relnamespace
    WHERE
        r.relkind IN ('r', 'p')
      AND NOT pg_is_other_temp_schema(nr.oid)
      AND c.contype = 'p'
  ),
  key_col_usage AS (
    SELECT
      ss.conname::name AS constraint_name,
      ss.nr_nspname::name AS table_schema,
      ss.relname::name AS table_name,
      a.attname::name AS column_name,
      (ss.x).n::integer AS ordinal_position,
      CASE
        WHEN ss.contype = 'f' THEN information_schema._pg_index_position(ss.conindid, ss.confkey[(ss.x).n])
        ELSE NULL::integer
        END::integer AS position_in_unique_constraint
    FROM pg_attribute a
           JOIN (
      SELECT r.oid AS roid,
             r.relname,
             r.relowner,
             nc.nspname AS nc_nspname,
             nr.nspname AS nr_nspname,
             c.oid AS coid,
             c.conname,
             c.contype,
             c.conindid,
             c.confkey,
             information_schema._pg_expandarray(c.conkey) AS x
      FROM pg_namespace nr
             JOIN pg_class r
                  ON nr.oid = r.relnamespace
             JOIN pg_constraint c
                  ON r.oid = c.conrelid
             JOIN pg_namespace nc
                  ON c.connamespace = nc.oid
      WHERE
          c.contype in ('p', 'u')
        AND r.relkind IN ('r', 'p')
        AND NOT pg_is_other_temp_schema(nr.oid)
    ) ss ON a.attrelid = ss.roid AND a.attnum = (ss.x).x
    WHERE
      NOT a.attisdropped
  ),
  tbl_pk_cols AS (
    SELECT
      key_col_usage.table_schema,
      key_col_usage.table_name,
      array_agg(key_col_usage.column_name) as pk_cols
    FROM
      tbl_constraints
        JOIN
      key_col_usage
      ON
            key_col_usage.table_name = tbl_constraints.table_name AND
            key_col_usage.table_schema = tbl_constraints.table_schema AND
            key_col_usage.constraint_name = tbl_constraints.constraint_name
    WHERE
        key_col_usage.table_schema NOT IN ('pg_catalog', 'information_schema')
    GROUP BY key_col_usage.table_schema, key_col_usage.table_name
  )
SELECT
  n.nspname AS table_schema,
  c.relname AS table_name,
  d.description AS table_description,
  c.relkind IN ('v','m') as is_view,
  (
    c.relkind IN ('r','p')
    OR (
      c.relkind in ('v','f')
      -- The function `pg_relation_is_updateable` returns a bitmask where 8
      -- corresponds to `1 << CMD_INSERT` in the PostgreSQL source code, i.e.
      -- it's possible to insert into the relation.
      AND (pg_relation_is_updatable(c.oid::regclass, TRUE) & 8) = 8
    )
  ) AS insertable,
  (
    c.relkind IN ('r','p')
    OR (
      c.relkind in ('v','f')
      -- CMD_UPDATE
      AND (pg_relation_is_updatable(c.oid::regclass, TRUE) & 4) = 4
    )
  ) AS updatable,
  (
    c.relkind IN ('r','p')
    OR (
      c.relkind in ('v','f')
      -- CMD_DELETE
      AND (pg_relation_is_updatable(c.oid::regclass, TRUE) & 16) = 16
    )
  ) AS deletable,
  coalesce(tpks.pk_cols, '{}') as pk_cols,
  cols_agg.composite_cols,
  cols_agg.required_cols,
  cols_agg.all_cols,
  coalesce(cols_agg.columns, '{}') as columns
FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  LEFT JOIN pg_description d on d.objoid = c.oid and d.objsubid = 0
  LEFT JOIN tbl_pk_cols tpks ON n.nspname = tpks.table_schema AND c.relname = tpks.table_name
  LEFT JOIN columns_agg cols_agg ON n.nspname = cols_agg.table_schema AND c.relname = cols_agg.table_name
WHERE c.relkind IN ('v','r','m','f','p')
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND not c.relispartition
ORDER BY table_schema, table_name;
$$;

-- TODO: This function could be integrated in postgrest_get_all_tables
create or replace function postgrest_get_all_composite_types(schemas text[])
returns table (
  comptype_schema text,
  comptype_name text,
  comptype_description text,
  columns jsonb
) language sql as
$$
WITH
  columns AS (
    SELECT
      nc.nspname::name AS comptype_schema,
      c.relname::name AS comptype_name,
      a.attname::name AS column_name,
      d.description AS description,
      t.typarray = 0 AS is_array,
      t.typtype = 'c' AS is_composite,
      CASE
        WHEN t.typtype = 'd' THEN
          CASE
            WHEN nbt.nspname = 'pg_catalog'::name THEN format_type(t.typbasetype, NULL::integer)
            ELSE format_type(a.atttypid, a.atttypmod)
            END
        ELSE
          CASE
            WHEN nt.nspname = 'pg_catalog'::name THEN format_type(a.atttypid, NULL::integer)
            ELSE format_type(a.atttypid, a.atttypmod)
            END
        END::text AS data_type,
      t.oid AS data_type_id,
        information_schema._pg_char_max_length(
          information_schema._pg_truetypid(a.*, t.*),
          information_schema._pg_truetypmod(a.*, t.*)
        )::integer AS character_maximum_length,
      COALESCE(bt.typname, t.typname)::name AS udt_name,
      a.attnum::integer AS position,
      CASE
        WHEN t_arr.typtype = 'd' THEN
          CASE
            WHEN nbt_arr.nspname = 'pg_catalog'::name THEN format_type(t_arr.typbasetype, NULL::integer)
            ELSE format_type(t_arr.oid, t_arr.typtypmod)
            END
        ELSE
          CASE
            WHEN nt_arr.nspname = 'pg_catalog'::name THEN format_type(t_arr.oid, NULL::integer)
            ELSE format_type(t_arr.oid, t_arr.typtypmod)
            END
        END::text AS item_data_type,
      t_arr.typtype = 'c' AS item_is_composite,
      t_arr.typrelid AS item_comptype_id,
      t_arr.oid AS item_data_type_id,
      -- Used for the recursive query
      a.attrelid AS comptype_id,
      t.typrelid AS column_comptype_id
    FROM pg_attribute a
      LEFT JOIN pg_description AS d
        ON d.objoid = a.attrelid and d.objsubid = a.attnum
      JOIN (pg_class c JOIN pg_namespace nc ON c.relnamespace = nc.oid)
        ON a.attrelid = c.oid
      JOIN (pg_type t JOIN pg_namespace nt ON t.typnamespace = nt.oid)
        ON a.atttypid = t.oid
      LEFT JOIN (pg_type bt JOIN pg_namespace nbt ON bt.typnamespace = nbt.oid)
        ON t.typtype = 'd' AND t.typbasetype = bt.oid
      LEFT JOIN (pg_type t_arr JOIN pg_namespace nt_arr ON t_arr.typnamespace = nt_arr.oid)
        ON t.oid = t_arr.typarray
      LEFT JOIN (pg_type bt_arr JOIN pg_namespace nbt_arr ON bt_arr.typnamespace = nbt_arr.oid)
        ON t_arr.typtype = 'd' AND t_arr.typbasetype = bt_arr.oid
      LEFT JOIN (pg_collation co JOIN pg_namespace nco ON co.collnamespace = nco.oid)
        ON a.attcollation = co.oid AND (nco.nspname <> 'pg_catalog'::name OR co.collname <> 'default'::name)
      LEFT JOIN pg_depend dep
        ON dep.refobjid = a.attrelid and dep.refobjsubid = a.attnum and dep.deptype = 'i'
      LEFT JOIN pg_class seqclass
        ON seqclass.oid = dep.objid
      LEFT JOIN pg_namespace seqsch
        ON seqsch.oid = seqclass.relnamespace
    WHERE
      NOT pg_is_other_temp_schema(nc.oid)
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND c.relkind = 'c'
  ),
  all_comptype_columns AS (
    -- TODO: This may repeat cycles,verify if UNION is performant enough
    WITH RECURSIVE recurse AS (
      SELECT
        comptype_schema,
        comptype_name,
        column_name,
        description,
        is_array,
        is_composite,
        data_type,
        data_type_id,
        character_maximum_length,
        udt_name,
        position,
        comptype_id,
        column_comptype_id,
        item_data_type,
        item_is_composite,
        item_comptype_id
      FROM columns
      -- List only the the composite types that are used by tables in the exposed schema
      WHERE comptype_id in (select unnest(composite_cols) from postgrest_get_all_tables(schemas))
      UNION
      SELECT
        c.comptype_schema,
        c.comptype_name,
        c.column_name,
        c.description,
        c.is_array,
        c.is_composite,
        c.data_type,
        c.data_type_id,
        c.character_maximum_length,
        c.udt_name,
        c.position,
        c.comptype_id,
        c.column_comptype_id,
        c.item_data_type,
        c.item_is_composite,
        c.item_comptype_id
      FROM columns c
        JOIN recurse r on c.comptype_id = coalesce(r.item_comptype_id, r.column_comptype_id)
    )
    SELECT * FROM recurse
  ),
  columns_agg AS (
    SELECT DISTINCT
      info.comptype_schema AS comptype_schema,
      info.comptype_name AS comptype_name,
      array_agg(coalesce(info.data_type_id, info.item_comptype_id)) filter (where info.is_composite or info.item_is_composite) AS composite_cols,
      jsonb_object_agg(
          info.column_name,
          case when info.is_composite then
            oas_build_reference_to_schemas(info.data_type)
          else
            oas_schema_object(
              description :=  info.description,
              type := pgtype_to_oastype(info.data_type),
              format := info.data_type::text,
              maxlength := info.character_maximum_length,
              -- "default" :=  to_jsonb(info.column_default),
              enum := to_jsonb(enum_info.vals),
              items :=
                case
                when not info.is_array then
                  null
                when info.item_is_composite then
                  oas_build_reference_to_schemas(info.item_data_type)
                else
                  oas_schema_object(
                    type := pgtype_to_oastype(info.item_data_type),
                    format := info.item_data_type::text
                  )
                end
            )
          end order by info.position
        ) as columns
    FROM all_comptype_columns info
      LEFT OUTER JOIN (
        SELECT
          n.nspname AS s,
          t.typname AS n,
          array_agg(e.enumlabel ORDER BY e.enumsortorder) AS vals
        FROM pg_type t
               JOIN pg_enum e ON t.oid = e.enumtypid
               JOIN pg_namespace n ON n.oid = t.typnamespace
        GROUP BY s,n
      ) AS enum_info ON info.udt_name = enum_info.n
    WHERE info.comptype_schema NOT IN ('pg_catalog', 'information_schema')
    GROUP BY info.comptype_schema, info.comptype_name
  )
SELECT
  n.nspname AS comptype_schema,
  c.relname AS comptype_name,
  d.description AS comptype_description,
  coalesce(cols_agg.columns, '{}') as columns
FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  LEFT JOIN pg_description d on d.objoid = c.reltype and d.objsubid = 0
  JOIN columns_agg cols_agg ON n.nspname = cols_agg.comptype_schema AND c.relname = cols_agg.comptype_name
WHERE c.relkind = 'c'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema');
$$;

create or replace function postgrest_get_schema_description(schema text)
returns table (
  title text,
  description text
) language sql as
$$
select
  substr(sd.schema_desc, 0, break_position) as title,
  trim(leading from substr(sd.schema_desc, break_position), '
') as description
from (
  select
    description as schema_desc,
    strpos(description, '
') as break_position
  from
    pg_namespace n
      left join pg_description d on d.objoid = n.oid
  where
      n.nspname = schema
) sd;
$$;
