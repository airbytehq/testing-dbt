select
    'a column with underscore' as column_name,
    'a column to rename' as column_to_rename,
    'a column to be deleted' as column_to_delete,
    {{ current_timestamp() }} as insert_time
