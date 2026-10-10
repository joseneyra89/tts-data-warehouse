SELECT 'dim_cliente' AS tabla, COUNT_BIG(*) AS filas FROM gold.dim_cliente
UNION ALL SELECT 'dim_fecha', COUNT_BIG(*) FROM gold.dim_fecha
UNION ALL SELECT 'dim_repuesto', COUNT_BIG(*) FROM gold.dim_repuesto
UNION ALL SELECT 'dim_servicio', COUNT_BIG(*) FROM gold.dim_servicio
UNION ALL SELECT 'dim_tecnico', COUNT_BIG(*) FROM gold.dim_tecnico
UNION ALL SELECT 'dim_vehiculo', COUNT_BIG(*) FROM gold.dim_vehiculo
UNION ALL SELECT 'fact_consumo_repuesto', COUNT_BIG(*) FROM gold.fact_consumo_repuesto
UNION ALL SELECT 'fact_factura', COUNT_BIG(*) FROM gold.fact_factura
UNION ALL SELECT 'fact_servicio', COUNT_BIG(*) FROM gold.fact_servicio
ORDER BY tabla;
