select
    'replacing underscore with space' as {{ normalize_identifier('new column name') }},
    'a renamed column' as renamed_column,
    'a new column is added' as new_column,
    {{ current_timestamp() }} as insert_time
