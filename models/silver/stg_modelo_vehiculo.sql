{{ config(unique_key='modelo_id') }}

select
    cast(ModeloID as int) as modelo_id,
    cast(MarcaID as int) as marca_id,
    trim(cast(NombreModelo as string)) as nombre_modelo,
    current_timestamp() as dbt_actualizado_en
from {{ source('bronze', 'modelovehiculo') }}
