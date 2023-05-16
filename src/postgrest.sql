-- Functions to get and transform the information that PostgREST uses
-- for the OpenAPI output

-- TODO: simplify the query to have only relevant info for OpenAPI
-- TODO: verify if this query should directly send the data in JSONB format
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
  required_cols text[],
  columns jsonb
) language sql as
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
      a.attnum::integer AS position
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
      array_agg(info.column_name) filter (where not info.is_nullable) AS required_cols,
      jsonb_object_agg(
        info.column_name,
        openapi_schema_object(
          description :=  info.description,
          type := pgtype_to_oastype(info.data_type),
          format := info.data_type::text,
          maxlength := info.character_maximum_length,
          -- "default" :=  to_jsonb(info.column_default),
          enum := to_jsonb(enum_info.vals)
        ) order by info.position
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
  cols_agg.required_cols,
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


create or replace function postgrest_tables_to_openapi_schema_components(schemas text[])
returns jsonb language sql as
$$
select jsonb_object_agg(x.table_name, x.oas_schema)
from (
  select table_name,
    openapi_schema_object(
      properties := columns,
      required := required_cols,
      type := 'object'
    ) as oas_schema
  from postgrest_get_all_tables(schemas)
) x;
$$;
