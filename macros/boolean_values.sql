{% macro boolean_value_true() -%}
  {{ adapter.dispatch('boolean_value_true')() }}
{%- endmacro %}

{% macro default__boolean_value_true() -%}
    true
{%- endmacro %}

{% macro sqlserver__boolean_value_true() -%}
    cast(1 as BIT)
{%- endmacro %}

{% macro boolean_value_false() -%}
  {{ adapter.dispatch('boolean_value_false')() }}
{%- endmacro %}

{% macro default__boolean_value_false() -%}
    false
{%- endmacro %}

{% macro sqlserver__boolean_value_false() -%}
    cast(0 as BIT)
{%- endmacro %}