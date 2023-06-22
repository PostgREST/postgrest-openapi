# PostgREST OpenAPI

SQL functions to build the OpenAPI output of a PostgREST instance.

## Roadmap

- The first step in the roadmap is to migrate the OpenAPI spec from the PostgREST core repository (version 2.0 to 3.1):
  - [] Info object
  - [x] Server object (replaces host, basePath and schemes from OAS 2.0)
  - [] Components object
    - [x] Schemas (definitions in OAS 2.0)
    - [] Security scheme (security definitions in OAS 2.0)
    - [] Parameters
    - [] Responses (produces in OAS 2.0 - simple implementation)
    - [] Request bodies (consumes in OAS 2.0 - simple implementation)
  - [] Paths object
- The next step is to fix the issues tagged with `OpenAPI` in the core repo.

## Development

- Execute the script to build the PostgreSQL extension file:

  ```
  sh scripts/build.sh
  ```

- Run tests using [Nix](https://nixos.org/download.html):

  ```
  nix-shell --run "with-pg-15 make installcheck"
  ```

## References

- [OpenAPI 3 Specification Documentation](https://spec.openapis.org/oas/v3.1.0): The official documentation of the spec.
- [OpenAPI Specification Explained](https://learn.openapis.org/specification/): Introductory explanation of the spec.
- [OpenAPI Guide](https://swagger.io/docs/specification/about/): Detailed explanation for each concept of the spec, useful to build it from scratch.
- [OpenAPI Visual Map](http://openapi-map.apihandyman.io/?version=3.0): Visual representation of the spec using an interactive GUI to navigate through its components. 
