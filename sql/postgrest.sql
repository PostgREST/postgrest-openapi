-- Functions to get information from PostgREST to generate the OpenAPI output

create or replace function postgrest_get_all_tables_and_composite_types()
returns table (
  column_name text,
  column_description text,
  column_default text,
  column_is_nullable bool,
  column_data_type text,
  column_item_data_type text,
  column_character_maximum_length integer,
  column_enums text[],
  column_composite_relid oid,
  column_position int,
  column_is_pk bool,
  table_oid oid,
  table_namespace oid,
  table_schema text,
  table_name text,
  table_description text,
  is_table bool,
  is_view bool,
  is_composite bool,
  insertable bool,
  updatable bool,
  deletable bool
) language sql stable as
$$
WITH RECURSIVE
  tbl_pk_cols AS (
    SELECT
      r.oid AS relid,
      a.attnum AS position
    FROM pg_class r
    JOIN pg_constraint c
      ON r.oid = c.conrelid
    JOIN pg_attribute a
      ON a.attrelid = r.oid AND a.attnum = ANY (c.conkey)
    WHERE
      c.contype in ('p')
      AND r.relkind IN ('r', 'p')
      AND r.relnamespace NOT IN ('pg_catalog'::regnamespace, 'information_schema'::regnamespace)
      AND NOT pg_is_other_temp_schema(r.relnamespace)
      AND NOT a.attisdropped
    GROUP BY r.oid, a.attnum
  )
  SELECT
    a.attname::name AS column_name,
    d.description AS column_description,
    -- typbasetype and typdefaultbin handles `CREATE DOMAIN .. DEFAULT val`,  attidentity/attgenerated handles generated columns, pg_get_expr gets the default of a column
    CASE
      WHEN t.typbasetype  != 0  THEN pg_get_expr(t.typdefaultbin, 0)
      WHEN a.attidentity  = 'd' THEN format('nextval(%L)', seq.objid::regclass)
      WHEN a.attgenerated = 's' THEN null
      ELSE pg_get_expr(ad.adbin, ad.adrelid)::text
    END AS column_default,
    NOT (a.attnotnull OR t.typtype = 'd' AND t.typnotnull) AS is_nullable,
    CASE
        WHEN t.typtype = 'd' THEN
        CASE
            WHEN bt.typnamespace = 'pg_catalog'::regnamespace THEN format_type(t.typbasetype, NULL::integer)
            ELSE format_type(a.atttypid, a.atttypmod)
        END
        ELSE
        CASE
            WHEN t.typnamespace = 'pg_catalog'::regnamespace THEN format_type(a.atttypid, NULL::integer)
            ELSE format_type(a.atttypid, a.atttypmod)
        END
    END::text AS column_data_type,
    CASE
        WHEN t_arr.typtype = 'd' THEN
        CASE
            WHEN bt_arr.typnamespace = 'pg_catalog'::regnamespace THEN format_type(t_arr.typbasetype, NULL::integer)
            ELSE format_type(t_arr.oid, t_arr.typtypmod)
        END
        ELSE
        CASE
            WHEN t_arr.typnamespace = 'pg_catalog'::regnamespace THEN format_type(t_arr.oid, NULL::integer)
            ELSE format_type(t_arr.oid, t_arr.typtypmod)
        END
    END::text AS column_item_data_type,
    information_schema._pg_char_max_length(
        information_schema._pg_truetypid(a.*, t.*),
        information_schema._pg_truetypmod(a.*, t.*)
    )::integer AS column_character_maximum_length,
    (SELECT array_agg(enumlabel ORDER BY enumsortorder) FROM pg_enum WHERE enumtypid = COALESCE(COALESCE(bt_arr.oid, bt.oid), COALESCE(t_arr.oid, t.oid))) AS column_enums,
    -- If the column or item is a composite type, this references the relid.
    COALESCE(COALESCE(bt_arr.typrelid, t_arr.typrelid), COALESCE(bt.typrelid, t.typrelid)) AS column_composite_relid,
    a.attnum::integer AS position,
    tpks.position IS NOT NULL AS column_is_pk,
    c.oid AS table_oid,
    c.relnamespace AS table_namespace,
    n.nspname AS table_schema,
    c.relname AS table_name,
    td.description AS table_description,
    c.relkind IN ('r','f','p') AS is_table,
    c.relkind IN ('v','m') AS is_view,
    c.relkind IN ('c') AS is_composite,
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
    ) AS deletable
  FROM pg_attribute a
    LEFT JOIN pg_description AS d
        ON d.objoid = a.attrelid and d.objsubid = a.attnum
    LEFT JOIN pg_attrdef ad
        ON a.attrelid = ad.adrelid AND a.attnum = ad.adnum
    JOIN pg_class c
        ON a.attrelid = c.oid
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    LEFT JOIN pg_description AS td
        ON td.objoid = CASE WHEN c.relkind = 'c' then c.reltype else c.oid end AND td.objsubid = 0
    JOIN pg_type t
        ON a.atttypid = t.oid
    LEFT JOIN pg_type t_arr
        ON t.typarray = 0 AND t.oid = t_arr.typarray
    LEFT JOIN pg_type bt
        ON t.typtype = 'd' AND t.typbasetype = bt.oid
    LEFT JOIN pg_type bt_arr
        ON bt.typarray = 0 AND bt.oid = bt_arr.typarray
    LEFT JOIN pg_depend seq
        ON seq.refobjid = a.attrelid AND seq.refobjsubid = a.attnum and seq.deptype = 'i'
    LEFT JOIN tbl_pk_cols tpks
        ON c.oid = tpks.relid AND a.attrelid = tpks.position
  WHERE
    NOT pg_is_other_temp_schema(c.relnamespace)
    AND a.attnum > 0
    AND NOT a.attisdropped
    AND c.relkind in ('r', 'v', 'f', 'm', 'p', 'c')
    AND c.relnamespace NOT IN ('pg_catalog'::regnamespace, 'information_schema'::regnamespace)
    AND not c.relispartition;
$$;

-- TODO: simplify the query to have only relevant info for OpenAPI
-- TODO: Further optimize the query (takes ~160ms compared to ~17ms from the query in the core repo)
create or replace function postgrest_get_all_functions(schemas text[])
returns table (
  proc_schema text,
  proc_name text,
  proc_description text,
  schema text,
  name text,
  rettype_is_setof boolean,
  rettype_is_composite boolean,
  rettype_is_table boolean,
  rettype_is_composite_alias boolean,
  provolatile char,
  hasvariadic boolean,
  transaction_isolation_level text,
  statement_timeout text,
  composite_args_ret oid[],
  required_args text[],
  all_args text[],
  args jsonb
) language sql stable as
$$
 -- Recursively get the base types of domains
  WITH
  base_types AS (
    WITH RECURSIVE
    recurse AS (
      SELECT
        oid,
        typbasetype,
        COALESCE(NULLIF(typbasetype, 0), oid) AS base
      FROM pg_type
      UNION
      SELECT
        t.oid,
        b.typbasetype,
        COALESCE(NULLIF(b.typbasetype, 0), b.oid) AS base
      FROM recurse t
      JOIN pg_type b ON t.typbasetype = b.oid
    )
    SELECT
      oid,
      base
    FROM recurse
    WHERE typbasetype = 0
  ),
  arguments AS (
    SELECT
      p.oid as proc_oid,
      pa.idx AS idx,
      COALESCE(pa.name, '') as name,
      type,
      CASE type
        WHEN 'bit'::regtype THEN 'bit varying'
        WHEN 'bit[]'::regtype THEN 'bit varying[]'
        WHEN 'character'::regtype THEN 'character varying'
        WHEN 'character[]'::regtype THEN 'character varying[]'
        ELSE type::regtype::text
      END AS type_ignore_length, -- convert types that ignore the lenth and accept any value till maximum size
      pa.idx <= (p.pronargs - p.pronargdefaults) AS is_required,
      t.typarray = 0 AS is_array,
      t.typtype = 'c' AS is_composite,
      t.typrelid AS composite_oid,
      CASE
        WHEN t.typtype = 'd' THEN
          CASE
            WHEN nbt.nspname = 'pg_catalog'::name THEN format_type(t.typbasetype, NULL::integer)
            ELSE format_type(pa.type, NULL::integer)
            END
        ELSE format_type(pa.type, NULL::integer)
        END::text AS data_type,
      t.oid AS data_type_id,
      COALESCE(bt.typname, t.typname)::name AS udt_name,
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
      t_arr.oid AS item_data_type_id,
      COALESCE(mode = 'v', FALSE) AS is_variadic
    FROM pg_proc p
      CROSS JOIN unnest(proargnames, proargtypes, proargmodes)
        WITH ORDINALITY AS pa (name, type, mode, idx)
      JOIN (pg_type t JOIN pg_namespace nt ON t.typnamespace = nt.oid)
        ON pa.type = t.oid
      LEFT JOIN (pg_type bt JOIN pg_namespace nbt ON bt.typnamespace = nbt.oid)
        ON t.typtype = 'd' AND t.typbasetype = bt.oid
      LEFT JOIN (pg_type t_arr JOIN pg_namespace nt_arr ON t_arr.typnamespace = nt_arr.oid)
        ON t.oid = t_arr.typarray
      LEFT JOIN (pg_type bt_arr JOIN pg_namespace nbt_arr ON bt_arr.typnamespace = nbt_arr.oid)
        ON t_arr.typtype = 'd' AND t_arr.typbasetype = bt_arr.oid
    -- TODO: Add output arguments (including "returns table") to build the response object schema
    WHERE pa.type IS NOT NULL -- only input arguments
  ),
  arguments_agg AS (
    SELECT
      info.proc_oid as oid,
      array_agg(coalesce(info.composite_oid, info.item_composite_oid)) filter (where info.is_composite or info.item_is_composite) AS composite_args,
      array_agg(info.name order by info.idx) filter (where info.is_required) AS required_args,
      array_agg(info.name order by info.idx) AS all_args,
      jsonb_object_agg(
        info.name,
          case when info.is_composite then
            oas_build_reference_to_schemas(info.data_type)
          else
            oas_schema_object(
              type := postgrest_pgtype_to_oastype(info.data_type),
              format := info.data_type::text,
              -- TODO: take default values from pg_proc.pronargdefaults
              -- "default" :=  to_jsonb(info.arg_default),
              enum := to_jsonb(enum_info.vals),
              items :=
                case
                when not info.is_array then
                  null
                when info.item_is_composite then
                  oas_build_reference_to_schemas(info.item_data_type)
                else
                  oas_schema_object(
                    type := postgrest_pgtype_to_oastype(info.item_data_type),
                    format := info.item_data_type::text
                  )
                end
            )
          end order by info.idx
      ) as args,
      CASE COUNT(*) - COUNT(nullif(info.name,'')) -- number of unnamed arguments
        WHEN 0 THEN true
        WHEN 1 THEN COUNT(*) = 1 AND (array_agg(info.type))[1] IN ('bytea'::regtype, 'json'::regtype, 'jsonb'::regtype, 'text'::regtype, 'xml'::regtype)
        ELSE false
      END AS callable
    FROM arguments as info
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
    GROUP BY proc_oid
  )
  SELECT
    pn.nspname AS proc_schema,
    p.proname AS proc_name,
    d.description AS proc_description,
    tn.nspname AS schema,
    COALESCE(comp.relname, t.typname) AS name,
    p.proretset AS rettype_is_setof,
    t.typtype = 'c' AS rettype_is_composite,
    COALESCE(proargmodes::text[] @> '{t}', false) AS rettype_is_table,
    -- TODO: add support for rettype out/inout
    bt.oid <> bt.base as rettype_is_composite_alias,
    p.provolatile,
    p.provariadic > 0 as hasvariadic,
    lower((regexp_split_to_array((regexp_split_to_array(iso_config, '='))[2], ','))[1]) AS transaction_isolation_level,
    lower((regexp_split_to_array((regexp_split_to_array(timeout_config, '='))[2], ','))[1]) AS statement_timeout,
    a.composite_args || case when t.typtype = 'c' then t.typrelid end as composite_args_ret,
    a.required_args,
    a.all_args,
    COALESCE(a.args, '{}') AS args
  FROM pg_proc p
  LEFT JOIN arguments_agg a ON a.oid = p.oid
  JOIN pg_namespace pn ON pn.oid = p.pronamespace
  JOIN base_types bt ON bt.oid = p.prorettype
  JOIN pg_type t ON t.oid = bt.base
  JOIN pg_namespace tn ON tn.oid = t.typnamespace
  -- TODO: Add support for functions returning array types (extra joins needed)
  LEFT JOIN pg_class comp ON comp.oid = t.typrelid
  LEFT JOIN pg_description as d ON d.objoid = p.oid
  LEFT JOIN LATERAL unnest(proconfig) iso_config ON iso_config like 'default_transaction_isolation%'
  LEFT JOIN LATERAL unnest(proconfig) timeout_config ON timeout_config like 'statement_timeout%'
  WHERE t.oid <> 'trigger'::regtype AND COALESCE(a.callable, true)
    AND prokind = 'f'
    AND pn.nspname = ANY(schemas);
$$;

create or replace function postgrest_get_schema_description(schema text)
returns table (
  title text,
  summary text,
  description text
) language sql stable as
$$
select
  coalesce(title, 'PostgREST API') as title,
  (postgrest_unfold_comment(sum_and_desc))[1] as summary,
  coalesce(
    (postgrest_unfold_comment(sum_and_desc))[2],
    'This is a dynamic API generated by PostgREST'
  ) as description
from (
  select
    (postgrest_unfold_comment(description))[1] as title,
    (postgrest_unfold_comment(description))[2] as sum_and_desc
  from
    pg_namespace n
      left join pg_description d on d.objoid = n.oid
  where
      n.nspname = schema
) _;
$$;
