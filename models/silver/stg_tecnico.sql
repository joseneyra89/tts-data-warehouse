{{ config(unique_key='tecnico_id') }}

select
    cast(TecnicoID as int) as tecnico_id,
    trim(cast(Nombre as string)) as nombre,
    trim(cast(Apellido as string)) as apellido,
    cast(EspecialidadID as int) as especialidad_id,
    cast(FechaIngreso as date) as fecha_ingreso,
    trim(cast(Estado as string)) as estado,
    current_timestamp() as dbt_actualizado_en
from {{ source('bronze', 'tecnico') }}
