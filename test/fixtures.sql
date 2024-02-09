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

create view test.non_auto_updatable as
  select 'this view is not auto updatable' as description;

create function test.get_products_by_size(s types.size)
returns setof test.products stable language sql as
$$
  select *
  from test.products
  where size = s;
$$;

create function test.get_attribute(loc types.attribute_arg)
returns types.attribute_ret stable language sql as
$$
  select ((1,2,3),array[('a','b')]::types.color_ret[],'a');
$$;

create schema private;

create table private.secret_table (
  id int generated always as identity,
  name text not null
);


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
