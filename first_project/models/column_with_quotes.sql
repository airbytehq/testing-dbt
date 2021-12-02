select
    'a column with tricky name with quotes' as  {{ normalize_identifier('column`_\'with""_quotes') }},
    {{ current_timestamp() }} as insert_time
