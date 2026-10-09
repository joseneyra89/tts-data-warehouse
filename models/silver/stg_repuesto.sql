{{ config(unique_key='repuesto_id') }}

select
    cast(RepuestoID as int) as repuesto_id,
    trim(cast(NombreRepuesto as string)) as nombre_repuesto,
    trim(cast(Categoria as string)) as categoria,
    trim(cast(Marca as string)) as marca,
    cast(CostoUnitario as decimal(12,2)) as costo_unitario,
    cast(StockActual as int) as stock_actual,
    current_timestamp() as dbt_actualizado_en
from {{ source('bronze', 'repuesto') }}
