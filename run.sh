#!/usr/bin/env bash

TARGET_DB=${TARGET_DB:-"postgres"}
DBT_DOCKER_IMAGE=${DBT_DOCKER_IMAGE:-"fishtownanalytics/dbt"}
DBT_VERSION=${DBT_VERSION:-"0.21.0"}

if [ "${TARGET_DB}" = "postgres" ]; then
    docker run --rm --name postgres-test-database -e POSTGRES_PASSWORD=password -p 4000:5432 -d postgres
fi

if [ "$1" = "local" ]; then
    echo -e "Running with local dbt installation $(which dbt)"
    DBT_CLI_COMMAND="dbt"
    PROJECT_DIR=$(pwd)
else
    echo -e "Running with dbt from docker ${DBT_DOCKER_IMAGE}:${DBT_VERSION}"
    DBT_CLI_COMMAND="docker run -it --rm -v $(pwd):/data --network host ${DBT_DOCKER_IMAGE}:${DBT_VERSION}"
    PROJECT_DIR="/data"
fi
PROFILES_DIR="${PROJECT_DIR}/db_${TARGET_DB}"

echo -e "\n******\nChecking tests setup for ${PROFILES_DIR}:\n******\n"
echo -e "> dbt debug\n"

${DBT_CLI_COMMAND} debug    --profiles-dir=${PROFILES_DIR} --project-dir="${PROJECT_DIR}/first_project/"

echo -e "\n******\nRun first_project for the first time and force a full-refresh:\n******\n"
echo -e "> dbt run --full-refresh\n"
${DBT_CLI_COMMAND} clean    --profiles-dir=${PROFILES_DIR} --project-dir="${PROJECT_DIR}/first_project/"
${DBT_CLI_COMMAND} run      --profiles-dir=${PROFILES_DIR} --project-dir="${PROJECT_DIR}/first_project/" --full-refresh

echo -e "\n******\nRun first_project for the second time (incremental):\n******\n"
echo -e "> dbt run --full-refresh\n"
${DBT_CLI_COMMAND} clean    --profiles-dir=${PROFILES_DIR} --project-dir="${PROJECT_DIR}/first_project/"
${DBT_CLI_COMMAND} run      --profiles-dir=${PROFILES_DIR} --project-dir="${PROJECT_DIR}/first_project/"

echo -e "\n******\nRun second_project with modified models from first_project (incremental):\n******\n"
echo -e "> dbt run\n"
${DBT_CLI_COMMAND} clean    --profiles-dir=${PROFILES_DIR} --project-dir="${PROJECT_DIR}/second_project/"
${DBT_CLI_COMMAND} run      --profiles-dir=${PROFILES_DIR} --project-dir="${PROJECT_DIR}/second_project/"

if [ "${TARGET_DB}" = "postgres" ]; then
    docker kill postgres-test-database
fi