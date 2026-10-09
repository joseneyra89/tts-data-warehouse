{{ config(unique_key='marca_id') }}

select
    cast(MarcaID as int) as marca_id,
    trim(cast(NombreMarca as string)) as nombre_marca,
    current_timestamp() as dbt_actualizado_en
from {{ source('bronze', 'marcavehiculo') }}
