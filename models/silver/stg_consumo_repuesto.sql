{{ config(unique_key='consumo_id') }}

select
    cast(ConsumoID as int) as consumo_id,
    cast(OrdenID as int) as orden_id,
    cast(RepuestoID as int) as repuesto_id,
    cast(Cantidad as int) as cantidad,
    cast(Costo as decimal(12,2)) as costo_total,
    current_timestamp() as dbt_actualizado_en
from {{ source('bronze', 'consumorepuesto') }}
