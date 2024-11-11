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
  column_composite_full_name text,
  column_is_composite bool,
  column_position int,
  column_is_pk bool,
  table_oid oid,
  table_namespace oid,
  table_schema text,
  table_name text,
  table_full_name text,
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
    cc.oid AS column_composite_relid,
    -- The "full name" of the composite type is `<schema>.<name>`. We omit `<schema>.` when it belongs to the `current_schema`
    COALESCE(NULLIF(cc.relnamespace::regnamespace::text, current_schema) || '.', '') || cc.relname AS column_composite_full_name,
    COALESCE(cc.oid <> 0, FALSE) AS column_is_composite,
    a.attnum::integer AS position,
    tpks.position IS NOT NULL AS column_is_pk,
    c.oid AS table_oid,
    c.relnamespace AS table_namespace,
    n.nspname AS table_schema,
    c.relname AS table_name,
    COALESCE(NULLIF(n.nspname, current_schema) || '.', '') || c.relname AS table_full_name,
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
    LEFT JOIN pg_class cc
        ON cc.oid = COALESCE(COALESCE(bt_arr.typrelid, t_arr.typrelid), COALESCE(bt.typrelid, t.typrelid))
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

create or replace function postgrest_get_all_functions(schemas text[])
returns table (
  argument_input_qty int,
  argument_default_qty int,
  argument_name text,
  argument_reg_type oid,
  argument_type_name text,
  argument_item_type_name text,
  argument_is_required bool,
  argument_is_in bool,
  argument_is_inout bool,
  argument_is_out bool,
  argument_is_table bool,
  argument_is_variadic bool,
  argument_position int,
  argument_composite_relid oid,
  argument_composite_full_name text,
  argument_is_composite bool,
  function_oid oid,
  function_schema name,
  function_name name,
  function_full_name text,
  function_description text,
  function_input_argument_types oidvector,
  return_type_name text,
  return_type_item_name text,
  return_type_is_set bool,
  return_type_is_table bool,
  return_type_is_out bool,
  return_type_is_composite_alias bool,
  return_type_composite_relid oid,
  return_type_composite_full_name text,
  return_type_is_composite bool,
  is_volatile bool,
  has_variadic bool
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
  all_functions AS (
    SELECT
      p.pronargs AS argument_input_qty,
      p.pronargdefaults AS argument_default_qty,
      COALESCE(pa.name, '') AS argument_name,
      pa.type AS argument_reg_type,
      format_type(ta.oid, NULL::integer) AS argument_type_name,
      format_type(ta_arr.oid, NULL::integer) AS argument_item_type_name,
      pa.idx <= (array_length(COALESCE(p.proallargtypes, p.proargtypes), 1) - p.pronargdefaults) AS argument_is_required,
      COALESCE(pa.mode = 'i', TRUE) AS argument_is_in, -- if the mode IS NULL then it is an IN argument
      COALESCE(pa.mode = 'b', FALSE) AS argument_is_inout,
      COALESCE(pa.mode = 'o', FALSE) AS argument_is_out,
      COALESCE(pa.mode = 't', FALSE) AS argument_is_table,
      COALESCE(pa.mode = 'v', FALSE) AS argument_is_variadic,
      pa.idx as argument_position,
      -- If the argument or item is a composite type, this references the relid.
      ca.oid AS argument_composite_relid,
      -- The "full name" of the composite type is `<schema>.<name>`. We omit `<schema>.` when it belongs to the `current_schema`
      COALESCE(NULLIF(ca.relnamespace::regnamespace::text, current_schema) || '.', '') || ca.relname AS argument_composite_full_name,
      COALESCE(ca.oid <> 0, FALSE) AS argument_is_composite,
      p.oid as function_oid,
      pn.nspname AS function_schema,
      p.proname AS function_name,
      -- The "full name" of the function `<schema>.<name>`. We omit `<schema>.` when it belongs to the `current_schema`
      COALESCE(NULLIF(pn.nspname, current_schema) || '.', '') || p.proname AS function_full_name,
      d.description AS function_description,
      p.proargtypes AS function_input_argument_types,
      format_type(t.oid, NULL::integer) AS return_type_name,
      format_type(t_arr.oid, NULL::integer) AS return_type_item_name,
      p.proretset AS return_type_is_set,
      COALESCE(proargmodes::text[] && '{t}', FALSE) return_type_is_table, -- If the function RETURNS TABLE
      COALESCE(proargmodes::text[] && '{b,o}', FALSE) return_type_is_out, -- If the function has INOUT or OUT arguments
      bt.oid <> bt.base AS return_type_is_composite_alias,
      -- If the return type or item is a composite type, this references the relid.
      c.oid AS return_type_composite_relid,
      COALESCE(NULLIF(c.relnamespace::regnamespace::text, current_schema) || '.', '') || c.relname AS return_type_composite_full_name,
      COALESCE(c.oid <> 0, FALSE) AS return_type_is_composite,
      p.provolatile = 'v' AS is_volatile,
      p.provariadic > 0 AS has_variadic
    FROM pg_proc p
    LEFT JOIN LATERAL unnest(proargnames, coalesce(proallargtypes,proargtypes), proargmodes)
      WITH ORDINALITY AS pa (name, type, mode, idx) ON TRUE
    JOIN pg_namespace pn ON pn.oid = p.pronamespace
    -- Joins relevant to the return type
    JOIN base_types bt ON bt.oid = p.prorettype
    JOIN pg_type t ON t.oid = bt.base
    LEFT JOIN pg_type t_arr
      ON t.typarray = 0 AND t.oid = t_arr.typarray
    LEFT JOIN pg_class c
      ON c.oid = COALESCE(t_arr.typrelid, t.typrelid)
    LEFT JOIN base_types bta ON bta.oid = pa.type
    LEFT JOIN pg_type ta ON ta.oid = bta.base
    LEFT JOIN pg_type ta_arr
      ON ta.typarray = 0 AND ta.oid = ta_arr.typarray
    LEFT JOIN pg_class ca
      ON ca.oid = COALESCE(ta_arr.typrelid, ta.typrelid)
    LEFT JOIN pg_description as d ON d.objoid = p.oid
    WHERE t.oid <> 'trigger'::regtype
    AND prokind = 'f'
    AND p.pronamespace = ANY(schemas::regnamespace[])
  )
  SELECT a.*
  FROM all_functions a
  WHERE NOT EXISTS (
    SELECT 1
    FROM all_functions x
    -- Do not include functions with unnamed arguments, unless it's a function with a single unnamed parameter of certain types
    WHERE x.argument_input_qty > 0
      AND x.argument_name = ''
      AND (x.argument_is_in OR x.argument_is_inout OR x.argument_is_variadic)
      AND NOT (x.argument_input_qty = 1 AND x.function_input_argument_types[0] IN ('bytea'::regtype, 'json'::regtype, 'jsonb'::regtype, 'text'::regtype, 'xml'::regtype))
      AND x.function_oid = a.function_oid
  );
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
