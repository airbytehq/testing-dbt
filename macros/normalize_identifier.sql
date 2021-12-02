{% macro normalize_identifier(column_name) -%}
  {{ adapter.dispatch('normalize_identifier')(column_name) }}
{%- endmacro %}

{% macro default__normalize_identifier(column_name) -%}
  {{ adapter.quote(column_name) }}
{%- endmacro %}

{% macro bigquery__normalize_identifier(column_name) -%}
  -- BigQuery does not support special characters in column names, replacing them by '_'
  {{ column_name.replace(' ', '_').replace('"', '_').replace("'", '_').replace('`', '_') }}
{%- endmacro %}
