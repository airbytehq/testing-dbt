#!/usr/bin/env bash

rm -rf output

for target_db in `echo "postgres mssql bigquery snowflake redshift"`; do
    TARGET_DB=${target_db} EXPORT_LOGS=${EXPORT_LOGS:-true} DBT_DOCKER_IMAGE=${DBT_DOCKER_IMAGE:-"fishtownanalytics/dbt"} DBT_VERSION=${DBT_VERSION:-"0.21.0"} EXTRA_DOCKER_ARG=${EXPORT_DOCKER_ARG:-} ./run_tests.sh
done