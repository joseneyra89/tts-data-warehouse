{{ config(unique_key='vehiculo_key') }}

select
    v.vehiculo_id as vehiculo_key,
    v.cliente_id as cliente_key,
    v.modelo_id,
    m.marca_id,
    ma.nombre_marca,
    m.nombre_modelo,
    v.placa,
    v.anio,
    v.kilometraje_actual,
    v.tipo_vehiculo,
    current_timestamp() as dbt_actualizado_en
from {{ ref('stg_vehiculo') }} v
inner join {{ ref('stg_modelo_vehiculo') }} m
    on v.modelo_id = m.modelo_id
inner join {{ ref('stg_marca_vehiculo') }} ma
    on m.marca_id = ma.marca_id
