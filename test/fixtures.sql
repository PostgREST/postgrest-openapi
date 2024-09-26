create extension postgrest_openapi;

drop schema if exists types, test, private cascade;

-- Custom types
create schema types;

create type types.dimension as (len numeric, wid numeric, hei numeric);
create type types.color as (hex char(6), def text);
create type types.attribute as (dim types.dimension, colors types.color[], other text);
create type types.hiddentype as (val text);
create type types.size as enum('XS', 'S', 'M', 'L', 'XL');

-- The detection of types used in functions need to be tested for arguments and returning values separately.
-- Used to test the detection of custom types inside the arguments
create type types.dimension_arg as (len numeric, wid numeric, hei numeric);
create type types.color_arg as (hex char(6), def text);
create type types.attribute_arg as (dim types.dimension_arg, colors types.color_arg[], other text);
-- Used to test the detection of custom types inside the returning values
create type types.dimension_ret as (len numeric, wid numeric, hei numeric);
create type types.color_ret as (hex char(6), def text);
create type types.attribute_ret as (dim types.dimension_ret, colors types.color_ret[], other text);
-- Used to test reference to composite types
create type types.dimension_ref as (len numeric, wid numeric, hei numeric);
create type types.color_ref as (hex char(6), def text);
create type types.attribute_ref as (dim types.dimension_ret, colors types.color_ret[], other text);

comment on type types.attribute is
$$Attribute summary

Attribute description
that spans
multiple lines.$$;

comment on column types.attribute.other is 'other information about the attribute';

-- Schema and tables for testing
create schema test;

comment on schema test is
$$My API title

My API summary

My API description
that spans
multiple lines$$;

create table test.products (
  id int generated always as identity,
  code char(6) not null unique,
  name text not null,
  description text not null,
  attr types.attribute,
  size types.size
);

comment on table test.products is
$$Products summary

Products description
that spans
multiple lines.$$;

comment on column test.products.id is 'identifier of a product';

CREATE TABLE test.openapi_types(
  "a_character_varying" character varying,
  "a_character" character(1),
  "a_text" text,
  "a_boolean" boolean,
  "a_smallint" smallint,
  "a_integer" integer,
  "a_bigint" bigint,
  "a_numeric" numeric,
  "a_real" real,
  "a_double_precision" double precision,
  "a_json" json,
  "a_jsonb" jsonb,
  "a_text_arr" text[],
  "a_int_arr" int[],
  "a_bool_arr" boolean[],
  "a_char_arr" char[],
  "a_varchar_arr" varchar[],
  "a_bigint_arr" bigint[],
  "a_numeric_arr" numeric[],
  "a_json_arr" json[],
  "a_jsonb_arr" jsonb[]
);

create view test.big_products as
  select id, code, name, size
  from test.products
  where size in ('L', 'XL');

comment on view test.big_products is
$$Big products summary

Big products description
that spans
multiple lines.$$;

create view test.non_auto_updatable as
  select 'this view is not auto updatable' as description;

-- Functions for testing

create function test.get_products_by_size(s types.size)
returns setof test.products stable language sql as
$$
  select *
  from test.products
  where size = s;
$$;

comment on function test.get_products_by_size(s types.size) is
$$Get Products By Size summary

Get Products By Size description
that spans
multiple lines.$$;

create function test.get_attribute(loc types.attribute_arg)
returns types.attribute_ret stable language sql as
$$
  select ((1,2,3),array[('a','b')]::types.color_ret[],'a');
$$;

create function test.returns_simple_type()
returns text
stable language sql as
$$
  select 'text';
$$;

create function test.returns_simple_type_arr()
returns text[]
stable language sql as
$$
  select array['text'];
$$;

create function test.returns_table()
returns table (num int, val text, comp types.dimension_ref)
stable language sql as
$$
  select (1,'text',(0.1,0.2,0.3));
$$;

create function test.returns_table_arr()
returns table (num int[], val text[], comp types.dimension_ref[])
stable language sql as
$$
  select (array[1],array['text'],array[(0.1,0.2,0.3)]::types.dimension_ref[]);
$$;

create function test.returns_inout(x int, inout y text, inout z types.color_ref)
returns record
stable language sql as
$$
  select ($2 || $1, $3);
$$;

create function test.returns_inout_arr(x int, inout y text[], inout z types.color_ref[])
returns record
stable language sql as
$$
  select (array[$2[$1]]::text[], array[$3]::types.color_ref[]);
$$;

create function test.returns_out(x int, y text, out a text, out b types.color_ref)
returns record
stable language sql as
$$
  select ($2 || $1, ('ffffff','white'));
$$;

create function test.returns_out_arr(x int, y text, out a text[], out b types.color_ref[])
returns record
stable language sql as
$$
  select (array[$2 || $1]::text[], array[('ffffff','white')]::types.color_ref[]);
$$;

create function test.returns_inout_out(x int, inout y text, out z types.color_ref)
returns record
stable language sql as
$$
  select ($2 || $1, ('ffffff','white'));
$$;

create function test.returns_inout_out_arr(x int, inout y text[], out z types.color_ref[])
returns record
stable language sql as
$$
  select (array[$2[$1]]::text[], array[('ffffff','white')]::types.color_ref[]);
$$;

create function test.returns_unknown_record()
returns record
stable language sql as
$$
  select (1, 'a', ('ffffff','white')::types.color_ref);
$$;

create function test.has_in_parameters(x int, y text[], z types.attribute_ref, o int default 0)
  returns record
  stable language sql as
$$
select ($1, $2, $3, $4);
$$;

create function test.has_inout_parameters(inout x int, inout y text[], inout z types.attribute_ref, inout o int default 0)
  returns record
  stable language sql as
$$
select ($1, $2, $3, $4);
$$;

create function test.has_variadic_parameter(x int, variadic y int[])
  returns record
  stable language sql as
$$
select ($1, $2);
$$;

create function test.single_unnamed_json_param(json) returns json stable language sql as 'select $1';
create function test.single_unnamed_jsonb_param(jsonb) returns jsonb stable language sql as 'select $1';
create function test.single_unnamed_text_param(text) returns text stable language sql as 'select $1';
create function test.single_unnamed_xml_param(xml) returns xml stable language sql as 'select $1';

create function test.single_unnamed_unrecognized_param(int) returns int stable language sql as 'select $1';
create function test.unnamed_params(int, numeric) returns numeric stable language sql as 'select $2 + $1';
create function test.named_and_unnamed_params(a int, numeric) returns numeric stable language sql as 'select $2 + $1';

create schema private;

create table private.secret_table (
  id int generated always as identity,
  name text not null
);

create function private.secret_function() returns int stable language sql as 'select 1';

-- Sample PostgREST config -- https://postgrest.org/en/stable/references/configuration.html#in-database-configuration
create schema postgrest;

-- Create pseudo-config, since we're not actually using PostgREST in the test
create or replace function postgrest.pre_config()
returns void as $$
  select
    set_config('pgrst.server_port', '3000', false),
    set_config('pgrst.server_host', '127.0.0.2', false),
    set_config('pgrst.db_schemas', 'test', false),
    set_config('pgrst.version', '0000.1111', false)
  ;
$$ language sql;

-- Table that stores openapi documents for different schemas. It speeds up the testing process.
create table public.postgrest_openapi(
  schemas text[] primary key,
  document jsonb
);

-- Wrapper function to retrieve openapi documents according to the schema
create or replace function public.get_openapi_document(schemas text[])
returns jsonb
immutable language sql as
$$
  select document
  from public.postgrest_openapi p
  where p.schemas = $1;
$$;

create or replace function public.insert_openapi_document(schemas text[])
returns void
language plpgsql as
$$begin
  -- Before inserting the openapi document, we emulate the PostgREST search path
  perform set_config('search_path', array_to_string(schemas || '{public}', ','), true);
  insert into public.postgrest_openapi
  select schemas, public.postgrest_openapi_spec(schemas);
end$$;

select public.insert_openapi_document('{test}');
select public.insert_openapi_document('{types}');
