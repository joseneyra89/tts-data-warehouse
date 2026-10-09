{{ config(unique_key='vehiculo_id') }}

select
    cast(VehiculoID as int) as vehiculo_id,
    cast(ClienteID as int) as cliente_id,
    cast(ModeloID as int) as modelo_id,
    upper(trim(cast(Placa as string))) as placa,
    cast(`Año` as smallint) as anio,
    cast(KilometrajeActual as int) as kilometraje_actual,
    trim(cast(TipoVehiculo as string)) as tipo_vehiculo,
    current_timestamp() as dbt_actualizado_en
from {{ source('bronze', 'vehiculo') }}
