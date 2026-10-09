{{ config(unique_key='factura_key') }}

select
    f.factura_id as factura_key,
    f.orden_id,
    case
        when f.fecha_factura is not null
        then cast(date_format(to_date(f.fecha_factura), 'yyyyMMdd') as int)
    end as fecha_factura_key,
    cast(date_format(to_date(o.fecha_ingreso), 'yyyyMMdd') as int) as fecha_ingreso_key,
    o.cliente_id as cliente_key,
    o.vehiculo_id as vehiculo_key,
    o.tecnico_id as tecnico_key,
    f.estado_factura,
    f.estado_pago,
    f.subtotal,
    f.igv,
    f.total,
    current_timestamp() as dbt_actualizado_en
from {{ ref('stg_factura') }} f
inner join {{ ref('stg_orden_servicio') }} o
    on f.orden_id = o.orden_id
