{{ config(unique_key='repuesto_key') }}

select
    repuesto_id as repuesto_key,
    nombre_repuesto,
    categoria,
    marca,
    costo_unitario,
    stock_actual,
    current_timestamp() as dbt_actualizado_en
from {{ ref('stg_repuesto') }}
