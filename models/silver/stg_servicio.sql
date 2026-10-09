{{ config(unique_key='servicio_id') }}

select
    cast(ServicioID as int) as servicio_id,
    trim(cast(NombreServicio as string)) as nombre_servicio,
    trim(cast(Categoria as string)) as categoria,
    cast(PrecioBase as decimal(10,2)) as precio_base,
    current_timestamp() as dbt_actualizado_en
from {{ source('bronze', 'servicio') }}
