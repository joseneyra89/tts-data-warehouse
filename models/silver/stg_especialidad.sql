{{ config(unique_key='especialidad_id') }}

select
    cast(EspecialidadID as int) as especialidad_id,
    trim(cast(Nombre as string)) as nombre_especialidad,
    current_timestamp() as dbt_actualizado_en
from {{ source('bronze', 'especialidad') }}
