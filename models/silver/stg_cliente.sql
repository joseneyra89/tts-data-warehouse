{{ config(unique_key='cliente_id') }}

select
    cast(ClienteID as int) as cliente_id,
    trim(cast(RUC as string)) as ruc,
    trim(cast(RazonSocial as string)) as razon_social,
    trim(cast(Telefono as string)) as telefono,
    trim(cast(Direccion as string)) as direccion,
    trim(cast(Ciudad as string)) as ciudad,
    trim(cast(TipoCliente as string)) as tipo_cliente,
    cast(FechaRegistro as date) as fecha_registro,
    trim(cast(Estado as string)) as estado,
    current_timestamp() as dbt_actualizado_en
from {{ source('bronze', 'cliente') }}
