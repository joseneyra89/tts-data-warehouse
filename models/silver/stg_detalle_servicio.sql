{{ config(unique_key='detalle_id') }}

select
    cast(DetalleID as int) as detalle_id,
    cast(OrdenID as int) as orden_id,
    cast(ServicioID as int) as servicio_id,
    cast(Cantidad as smallint) as cantidad,
    cast(HorasTrabajo as decimal(6,2)) as horas_trabajo,
    cast(CostoManoObra as decimal(12,2)) as importe_mano_obra,
    current_timestamp() as dbt_actualizado_en
from {{ source('bronze', 'detalleservicio') }}
