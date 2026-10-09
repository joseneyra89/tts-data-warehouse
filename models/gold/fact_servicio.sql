{{ config(unique_key='detalle_servicio_key') }}

select
    d.detalle_id as detalle_servicio_key,
    d.orden_id,
    cast(date_format(to_date(o.fecha_ingreso), 'yyyyMMdd') as int) as fecha_ingreso_key,
    case
        when o.fecha_salida is not null
        then cast(date_format(to_date(o.fecha_salida), 'yyyyMMdd') as int)
    end as fecha_salida_key,
    o.cliente_id as cliente_key,
    o.vehiculo_id as vehiculo_key,
    o.tecnico_id as tecnico_key,
    d.servicio_id as servicio_key,
    o.estado as estado_orden,
    o.prioridad,
    d.cantidad,
    d.horas_trabajo,
    d.importe_mano_obra,
    current_timestamp() as dbt_actualizado_en
from {{ ref('stg_detalle_servicio') }} d
inner join {{ ref('stg_orden_servicio') }} o
    on d.orden_id = o.orden_id
