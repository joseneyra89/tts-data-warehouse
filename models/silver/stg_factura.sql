{{ config(unique_key='factura_id') }}

select
    cast(FacturaID as int) as factura_id,
    cast(OrdenID as int) as orden_id,
    cast(FechaFactura as timestamp) as fecha_factura,
    cast(Subtotal as decimal(14,2)) as subtotal,
    cast(IGV as decimal(14,2)) as igv,
    cast(Total as decimal(14,2)) as total,
    trim(cast(EstadoPago as string)) as estado_pago,
    trim(cast(EstadoFactura as string)) as estado_factura,
    current_timestamp() as dbt_actualizado_en
from {{ source('bronze', 'factura') }}
