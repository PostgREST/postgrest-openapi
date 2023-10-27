##### Base #####
FROM postgres:16-alpine AS postgres-openapi-base


ENV extension_dir=/usr/local/share/postgresql/extension
ENV extensionName=postgrest_openapi
ENV build_dir=/buildroot
ENV out_dir=$build_dir/output

##### Build/Text #####
FROM postgres-openapi-base AS postgres-openapi-build

RUN apk --no-cache add make

RUN mkdir -p $build_dir/sql $build_dir/test $out_dir/ && chown postgres:postgres $out_dir/

COPY Makefile postgrest_openapi.control.in $build_dir/
COPY sql $build_dir/sql/
COPY test $build_dir/test/

# Do a build, install, and setup
RUN cd $build_dir && make && make install

COPY hosting/tests/scripts/run-tests.sh /docker-entrypoint-initdb.d/
RUN chmod a+x /docker-entrypoint-initdb.d/run-tests.sh

##### Final #####
FROM postgres-openapi-base AS postgres-openapi

RUN mkdir $extension_dir/bin
COPY sql/*.sql $extension_dir/share/postgresql/extension/
COPY --from=postgres-openapi-build $build_dir/${extensionName}.control $extension_dir/share/postgresql/extension/
