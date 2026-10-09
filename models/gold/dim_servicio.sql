{{ config(unique_key='servicio_key') }}

select
    servicio_id as servicio_key,
    nombre_servicio,
    categoria,
    precio_base,
    current_timestamp() as dbt_actualizado_en
from {{ ref('stg_servicio') }}
