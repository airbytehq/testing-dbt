# Tests on dbt CLI

This repo includes tests on dbt CLI to check if some features are ready to be leveraged as part of Airbyte's sync.

## Usage

1. The test suite can be started by running the shell script `./run_test.sh`.
2. It will run 3 `dbt run` commands against a default database (postgres in docker container)
3. The first run is a forced full refresh that will create models/tables in the target database. The models can be found in the [first_project/models/](first_project/models) folder. This step should generally be SUCCESSFUL.
4. The second run is where tests are actually starting. It is running the exact same models but in incremental mode, and should append more rows to already existing tables (created in the previous step). This step does not currently pass successfully for most of target db unfortunately.
5. The third run is running similar models to previous step in incremental mode, but it would introduce slight changes to models files. The models can be found in the [second_project/models/](second_project/models) folder. This is done to review what types of changes is supported by `incremental` materialization with the setting `on_schema_change: sync_all_columns` ([docs](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/configuring-incremental-models#what-if-the-columns-of-my-incremental-model-change))