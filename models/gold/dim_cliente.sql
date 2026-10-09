{{ config(unique_key='cliente_key') }}

select
    cliente_id as cliente_key,
    ruc,
    razon_social,
    telefono,
    direccion,
    ciudad,
    tipo_cliente,
    fecha_registro,
    estado,
    current_timestamp() as dbt_actualizado_en
from {{ ref('stg_cliente') }}
