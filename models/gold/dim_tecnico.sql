{{ config(unique_key='tecnico_key') }}

select
    t.tecnico_id as tecnico_key,
    t.nombre,
    t.apellido,
    concat(t.nombre, ' ', t.apellido) as nombre_completo,
    t.especialidad_id,
    e.nombre_especialidad,
    t.fecha_ingreso,
    t.estado,
    current_timestamp() as dbt_actualizado_en
from {{ ref('stg_tecnico') }} t
inner join {{ ref('stg_especialidad') }} e
    on t.especialidad_id = e.especialidad_id
