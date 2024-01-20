# About the project

The goal is to define and use PostgreSQL functions to generate an OpenAPI output in JSON format for a PostgREST instance.
These functions are grouped by similarity in different files inside the [`/sql`](/sql) folder:

## Functions to get data from PostgREST

The file [`postgrest.sql`](/sql/postgrest.sql) contains all the functions that get the database information relevant to PostgREST.
That is, to get data like the exposed tables in a schema, their columns with their data types, etc.
They are based on the queries used to build [the Schema Cache in the core repository](https://github.com/PostgREST/postgrest/blob/main/src/PostgREST/SchemaCache.hs).

## Functions to define the OpenAPI Specification

The file [`openapi.sql`](/sql/openapi.sql) defines all the objects belonging to the [OpenAPI specification](https://swagger.io/specification).
The functions have the form `oas_<object_name>`.
For instance, the `oas_info_object` function generates a JSON object with the same fields as [the Info Object definition](https://swagger.io/specification/#info-object).

## Functions to build the OpenAPI Document 

The rest of the files contain the functions used to build the OpenAPI document itself.
They are separated by and have the same name as each field of the [OpenAPI Object](https://swagger.io/specification/#openapi-object) (if needed),
e.g. [`components.sql`](/sql/components.sql) has the functions to build the Components Object.
The functions have the form `oas_build_<name>`.

Other files are:
- [`main.sql`](/sql/main.sql), which builds the main OpenAPI Object and other small objects that don't need a separate file.
- [`utils.sql`](/sql/utils.sql), which have common functions used by different modules.

### Building common parameters

Defined in the [`components.sql`](/sql/components.sql) file, these are common query parameters and headers that are used by many resources.
The OpenAPI document path is `#/components/parameters/` and are referenced by the `parameters` field of the [Operation Object](https://swagger.io/specification/#path-item-object).

#### Query parameters

All the common query parameters used by PostgREST requests, e.g. `select`, `order`, `limit`, etc.
These are defined in the `oas_build_component_parameters_query_params` function.
A part of the resulting object looks like this:

```json
{
  ...
  "limit": {
    "in": "query",
    "name": "limit",
    "schema": {
      "type": "integer"
    },
    "explode": false,
    "description": "Limit the number of rows returned"
  },
  "order": {
    "in": "query",
    "name": "order",
    "schema": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "explode": false,
    "description": "Ordering by column"
  },
  "select": {
    "in": "query",
    "name": "select",
    "schema": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "explode": false,
    "description": "Vertical filtering of columns"
  },
  ...
}
```

#### Headers

All the common headers used by PostgREST requests, such as `Range` and `Prefer`
(note that `Accept`, `Content-Type` or `Authorization` are not allowed here [according to the spec](https://swagger.io/specification/#fixed-fields-10).)
These are defined in the `oas_build_component_parameters_headers` function.
A partial example of the output looks like this:

```json
{
  ...
  "range": {
    "in": "header",
    "name": "Range",
    "schema": {
      "type": "string"
    },
    "example": "5-10",
    "description": "For limits and pagination"
  },
  "preferGet": {
    "in": "header",
    "name": "Prefer",
    "schema": {
      "allOf": [
        {
          "$ref": "header.preferHandling"
        },
        {
          "$ref": "header.preferTimezone"
        },
        {
          "$ref": "header.preferCount"
        }
      ]
    },
    "explode": true,
    "examples": {
      "all": {
        "value": {
          "count": "",
          "handling": "lenient",
          "timezone": ""
        },
        "summary": "All default preferences"
      },
      "nothing": {
        "summary": "No preferences"
      }
    },
    "description": "Specify a required or optional behavior for the request"
  },
  ...
}
```

##### Prefer headers

They are all the preferences allowed for PostgREST as [mentioned in the docs](https://postgrest.org/en/latest/references/api/preferences.html).
Since the `Prefer` header has a value in the form of `key=value`, we defined as "object" in the `#/components/schemas/` path of the OpenAPI document.
The `oas_build_component_schemas_headers` generates a schema for each preference and returns a JSON object like this one:

```json
{
  ...
  "header.preferCount": {
    "type": "object",
    "properties": {
      "count": {
        "enum": [
          "exact",
          "planned",
          "estimated"
        ],
        "type": "string",
        "description": "Get the total size of the table"
      }
    }
  },
  "header.preferReturn": {
    "type": "object",
    "properties": {
      "return": {
        "enum": [
          "minimal",
          "headers-only",
          "representation"
        ],
        "type": "string",
        "default": "minimal",
        "description": "Return information of the affected resource"
      }
    }
  },
  "header.preferMaxAffected": {
    "type": "object",
    "properties": {
      "max-affected": {
        "type": "integer",
        "description": "Specify the amount of resources affected"
      }
    }
  },
  ...
}
```

Having one schema for each preference allows us to group them depending on the method used in the request.
For example, a `GET` request can use only the `handling`, `timezone` and `count` preferences.
That is why in `#/components/parameters/` we add `"preferGet"` and group in the `schema` all those preferences:

```json
{
  ...
  "preferGet": {
    ...
    "schema": {
      "allOf": [
        {
          "$ref": "header.preferHandling"
        },
        {
          "$ref": "header.preferTimezone"
        },
        {
          "$ref": "header.preferCount"
        }
      ]
    },
    "explode": true,
    ...
  }
}
```

The field `explode` is set to `true` to convert the JSON example to a key/value pair, e.g.:

```json
{
  "count": "exact",
  "timezone": "UTC"
}
```
```
Prefer: count=exact,timezone=UTC
```
