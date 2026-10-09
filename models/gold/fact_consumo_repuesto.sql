{{ config(unique_key='consumo_repuesto_key') }}

select
    c.consumo_id as consumo_repuesto_key,
    c.orden_id,
    cast(date_format(to_date(o.fecha_ingreso), 'yyyyMMdd') as int) as fecha_ingreso_key,
    o.cliente_id as cliente_key,
    o.vehiculo_id as vehiculo_key,
    o.tecnico_id as tecnico_key,
    c.repuesto_id as repuesto_key,
    o.estado as estado_orden,
    o.prioridad,
    c.cantidad,
    c.costo_total,
    cast(c.costo_total / c.cantidad as decimal(12,2)) as costo_unitario_historico,
    current_timestamp() as dbt_actualizado_en
from {{ ref('stg_consumo_repuesto') }} c
inner join {{ ref('stg_orden_servicio') }} o
    on c.orden_id = o.orden_id
