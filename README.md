# Tests on dbt CLI

This repo includes tests on dbt CLI to check if some features are ready to be leveraged as part of Airbyte's sync.

## Usage

1. The test suite can be started by running the shell script `./run_test.sh`.
2. It will run 3 `dbt run` commands against a default database (postgres in docker container)
3. The first run is a forced full refresh that will create models/tables in the target database. The models can be found in the [first_project/models/](first_project/models) folder. This step should generally be SUCCESSFUL.
4. The second run is where tests are actually starting. It is running the exact same models but in incremental mode, and should append more rows to already existing tables (created in the previous step). This step does not currently pass successfully for most of target db unfortunately.
5. The third run is running similar models to previous step in incremental mode, but it would introduce slight changes to models files. The models can be found in the [second_project/models/](second_project/models) folder. This is done to review what types of changes is supported by `incremental` materialization with the setting `on_schema_change: sync_all_columns` ([docs](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/configuring-incremental-models#what-if-the-columns-of-my-incremental-model-change))

You can find in the [output/](output/) folder some `dbt.log` files that were run for each of these steps.
The naming of the file denotes for which `TARGET_DB` it was run for and what was the final status code returned by the `dbt run` command (SUCCESSFUL or FAILED).

## Advanced Usage

It is possible to change some default variables while running the test:

- TARGET_DB: which database flavor to run the test against. It is expected to have a valid `profiles.yml` to connect to that database type in the `db_${TARGET_DB}` folder. Default value is "postgres".
- DBT_DOCKER_IMAGE: The test suite can be run through docker containers (or local dbt cli installation if ran like this: `./run_test.sh local`. Default value is "fishtownanalytics/dbt".
- DBT_VERSION: The docker image version tag to use with DBT_DOCKER_IMAGE. Default value is "0.21.0".
- EXPORT_LOGS: Whether the dbt.log files should be exported to the output folder or not. Default value is "false".
- EXTRA_DOCKER_ARG: Additional arguments to pass when invoking the docker run command.

For example:

    TARGET_DB=bigquery EXPORT_LOGS=true ./run_tests.sh

For convenience, the script `./run_all_tests.sh` will run and regenerate all dbt.log for all destinations.

## Related GitHub Issues:

- column_with_quotes: https://github.com/dbt-labs/dbt-core/issues/4422
- change_column_names:
  - dbt repository: https://github.com/dbt-labs/dbt-core/issues/4423
  - airbyte repository: https://github.com/airbytehq/airbyte/issues/8240
