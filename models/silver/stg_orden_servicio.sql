{{ config(unique_key='orden_id') }}

select
    cast(OrdenID as int) as orden_id,
    cast(ClienteID as int) as cliente_id,
    cast(VehiculoID as int) as vehiculo_id,
    cast(TecnicoID as int) as tecnico_id,
    cast(FechaIngreso as timestamp) as fecha_ingreso,
    cast(FechaSalida as timestamp) as fecha_salida,
    trim(cast(Estado as string)) as estado,
    trim(cast(Prioridad as string)) as prioridad,
    nullif(trim(cast(Observacion as string)), '') as observacion,
    current_timestamp() as dbt_actualizado_en
from {{ source('bronze', 'ordenservicio') }}
