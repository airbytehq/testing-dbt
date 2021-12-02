#!/usr/bin/env bash

TARGET_DB=${TARGET_DB:-"postgres"}
DBT_DOCKER_IMAGE=${DBT_DOCKER_IMAGE:-"fishtownanalytics/dbt"}
DBT_VERSION=${DBT_VERSION:-"0.21.0"}
EXPORT_LOGS=${EXPORT_LOGS:-"false"}
EXTRA_DOCKER_ARG=${EXPORT_DOCKER_ARG:-}

function yesno() {
    local ans
    local ok=0
    local timeout=0
    local default
    local t

    while [[ "$1" ]]
    do
        case "$1" in
        --default)
            shift
            default=$1
            if [[ ! "$default" ]]; then error "Missing default value"; fi
            t=$(tr '[:upper:]' '[:lower:]' <<<$default)

            if [[ "$t" != 'y'  &&  "$t" != 'yes'  &&  "$t" != 'n'  &&  "$t" != 'no' ]]; then
                error "Illegal default answer: $default"
            fi
            default=$t
            shift
            ;;

        --timeout)
            shift
            timeout=$1
            if [[ ! "$timeout" ]]; then error "Missing timeout value"; fi
            if [[ ! "$timeout" =~ ^[0-9][0-9]*$ ]]; then error "Illegal timeout value: $timeout"; fi
            shift
            ;;

        -*)
            error "Unrecognized option: $1"
            ;;

        *)
            break
            ;;
        esac
    done

    if [[ $timeout -ne 0  &&  ! "$default" ]]; then
        error "Non-zero timeout requires a default answer"
    fi

    if [[ ! "$*" ]]; then error "Missing question"; fi

    while [[ $ok -eq 0 ]]
    do
        if [[ $timeout -ne 0 ]]; then
            if ! read -t $timeout -p "$*" ans; then
                ans=$default
            else
                # Turn off timeout if answer entered.
                timeout=0
                if [[ ! "$ans" ]]; then ans=$default; fi
            fi
        else
            read -p "$*" ans
            if [[ ! "$ans" ]]; then
                ans=$default
            else
                ans=$(tr '[:upper:]' '[:lower:]' <<<$ans)
            fi
        fi

        if [[ "$ans" == 'y'  ||  "$ans" == 'yes'  ||  "$ans" == 'n'  ||  "$ans" == 'no' ]]; then
            ok=1
        fi

        if [[ $ok -eq 0 ]]; then warning "Valid answers are: yes y no n"; fi
    done
    [[ "$ans" = "y" || "$ans" == "yes" ]]
}

function exportLogs() {
    if [ "$3" -eq 0 ]; then
        OUTCOME="SUCCESS"
    else
        OUTCOME="FAILED"
    fi
    if [ "${EXPORT_LOGS}" = "true" ]; then
        echo -e "Exporting '$1logs/dbt.log' to 'output/${TARGET_DB}-$2-${OUTCOME}-dbt.log'"
        mkdir -p "output"
        cp "$1/logs/dbt.log" "output/${TARGET_DB}-$2-${OUTCOME}-dbt.log"
    else
        echo -e "Not exporting 'output/${TARGET_DB}-$2-${OUTCOME}-dbt.log'"
    fi
}

#########################
# Test containers setup #
#########################

if [ "${TARGET_DB}" = "postgres" ]; then
    docker run --rm --name postgres-test-database -e POSTGRES_PASSWORD=password -p 4000:5432 -d postgres
elif [ "${TARGET_DB}" = "mssql" ]; then
    docker run --rm --name mssql-test-database -h mssql-test-database -e ACCEPT_EULA='Y' -e SA_PASSWORD='MyStr0ngP@ssw0rd' -e MSSQL_PID='Standard' -p 4000:1433 -d mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
    echo "...Waiting for MSSQL database to start for 30sec..."
    sleep 30
    docker exec mssql-test-database /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P MyStr0ngP@ssw0rd -Q "CREATE DATABASE [test_dbt]"
    DBT_DOCKER_IMAGE="airbyte/normalization-mssql"
    DBT_VERSION="0.1.61"
    EXTRA_DOCKER_ARG="${EXTRA_DOCKER_ARG} --entrypoint /usr/local/bin/dbt"
fi

#################
# dbt CLI setup #
#################

if [ "$1" = "local" ]; then
    echo -e "Running with local dbt installation $(which dbt)"
    DBT_CLI_COMMAND="dbt"
    PROJECT_DIR=$(pwd)
else
    echo -e "Running with dbt from docker ${DBT_DOCKER_IMAGE}:${DBT_VERSION}"
    DBT_CLI_COMMAND="docker run -it --rm -v $(pwd):/data --network host ${EXTRA_DOCKER_ARG} ${DBT_DOCKER_IMAGE}:${DBT_VERSION}"
    PROJECT_DIR="/data"
fi
PROFILES_DIR="${PROJECT_DIR}/db_${TARGET_DB}"

##############
# Test Suite #
##############

echo -e "\n******\nChecking tests setup for ${PROFILES_DIR}:\n******\n"
echo -e "> dbt debug\n"

${DBT_CLI_COMMAND} debug    --profiles-dir=${PROFILES_DIR} --project-dir="${PROJECT_DIR}/first_project/"

echo -e "\n******\nRun first_project for the first time and force a full-refresh:\n******\n"
echo -e "> dbt run --full-refresh\n"
${DBT_CLI_COMMAND} clean    --profiles-dir=${PROFILES_DIR} --project-dir="${PROJECT_DIR}/first_project/"
${DBT_CLI_COMMAND} run      --profiles-dir=${PROFILES_DIR} --project-dir="${PROJECT_DIR}/first_project/" --full-refresh
exportLogs "first_project/" "1-full-refresh" $?

echo -e "\n******\nRun first_project for the second time (incremental):\n******\n"
echo -e "> dbt run --full-refresh\n"
${DBT_CLI_COMMAND} clean    --profiles-dir=${PROFILES_DIR} --project-dir="${PROJECT_DIR}/first_project/"
${DBT_CLI_COMMAND} run      --profiles-dir=${PROFILES_DIR} --project-dir="${PROJECT_DIR}/first_project/"
exportLogs "first_project/" "2-incremental" $?

echo -e "\n******\nRun second_project with modified models from first_project (incremental):\n******\n"
echo -e "> dbt run\n"
${DBT_CLI_COMMAND} clean    --profiles-dir=${PROFILES_DIR} --project-dir="${PROJECT_DIR}/second_project/"
${DBT_CLI_COMMAND} run      --profiles-dir=${PROFILES_DIR} --project-dir="${PROJECT_DIR}/second_project/"
exportLogs "second_project/" "3-schema-change" $?

#############################
# Test containers tear down #
#############################

if [ "${TARGET_DB}" = "postgres" ]; then
    if yesno --timeout 5 --default yes "Kill ${TARGET_DB} database? Yes or no (timeout 5, default yes) ? "; then
        echo -e "\n> docker kill postgres-test-database"
        docker kill postgres-test-database
    fi
elif [ "${TARGET_DB}" = "mssql" ]; then
    if yesno --timeout 5 --default yes "Kill ${TARGET_DB} database? Yes or no (timeout 5, default yes) ? "; then
        echo -e "\n> docker kill mssql-test-database"
        docker kill mssql-test-database
    fi
fi
