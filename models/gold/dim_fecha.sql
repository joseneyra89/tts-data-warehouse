{{ config(materialized='table') }}

with limites_orden as (
    select
        min(to_date(fecha_ingreso)) as fecha_min,
        max(to_date(coalesce(fecha_salida, fecha_ingreso))) as fecha_max
    from {{ ref('stg_orden_servicio') }}
),
limites_factura as (
    select
        min(to_date(fecha_factura)) as fecha_min,
        max(to_date(fecha_factura)) as fecha_max
    from {{ ref('stg_factura') }}
),
limites as (
    select
        least(o.fecha_min, coalesce(f.fecha_min, o.fecha_min)) as fecha_min,
        greatest(o.fecha_max, coalesce(f.fecha_max, o.fecha_max)) as fecha_max
    from limites_orden o
    cross join limites_factura f
),
calendario as (
    select explode(sequence(fecha_min, fecha_max, interval 1 day)) as fecha
    from limites
)
select
    cast(date_format(fecha, 'yyyyMMdd') as int) as fecha_key,
    fecha,
    year(fecha) as anio,
    quarter(fecha) as trimestre,
    month(fecha) as mes_numero,
    date_format(fecha, 'MMMM') as mes_nombre,
    dayofmonth(fecha) as dia_mes,
    dayofweek(fecha) as dia_semana_numero,
    date_format(fecha, 'EEEE') as dia_semana_nombre,
    case when dayofweek(fecha) in (1, 7) then true else false end as es_fin_semana
from calendario
