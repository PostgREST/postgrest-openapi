create extension postgrest_openapi;

drop schema if exists types, test, private cascade;

-- Custom types
create schema types;

create type types.dimension as (len numeric, wid numeric, hei numeric);
create type types.color as (hex char(6), def text);
create type types.attribute as (dim types.dimension, colors types.color[], other text);
create type types.hiddentype as (val text);
create type types.size as enum('XS', 'S', 'M', 'L', 'XL');

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

create schema private;

create table private.secret_table (
  id int generated always as identity,
  name text not null
);


-- Sample PostgREST config -- https://postgrest.org/en/stable/references/configuration.html#in-database-configuration
create schema postgrest;

create or replace function postgrest.pre_config()
returns void as $$
  select
      set_config('pgrst.server_port', '3000', true)
    , set_config('pgrst.server_host', '127.0.0.2', true);
$$ language sql;
SELECT postgrest.pre_config();
