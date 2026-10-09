-- Valida que las 12 tablas externas de Bronze sean legibles desde Databricks.

WITH conteos AS (
    SELECT 'cliente' AS tabla, COUNT(*) AS filas FROM adb_tts_p3_dev_joseneyra.bronze.cliente
    UNION ALL SELECT 'consumorepuesto', COUNT(*) FROM adb_tts_p3_dev_joseneyra.bronze.consumorepuesto
    UNION ALL SELECT 'detalleservicio', COUNT(*) FROM adb_tts_p3_dev_joseneyra.bronze.detalleservicio
    UNION ALL SELECT 'especialidad', COUNT(*) FROM adb_tts_p3_dev_joseneyra.bronze.especialidad
    UNION ALL SELECT 'factura', COUNT(*) FROM adb_tts_p3_dev_joseneyra.bronze.factura
    UNION ALL SELECT 'marcavehiculo', COUNT(*) FROM adb_tts_p3_dev_joseneyra.bronze.marcavehiculo
    UNION ALL SELECT 'modelovehiculo', COUNT(*) FROM adb_tts_p3_dev_joseneyra.bronze.modelovehiculo
    UNION ALL SELECT 'ordenservicio', COUNT(*) FROM adb_tts_p3_dev_joseneyra.bronze.ordenservicio
    UNION ALL SELECT 'repuesto', COUNT(*) FROM adb_tts_p3_dev_joseneyra.bronze.repuesto
    UNION ALL SELECT 'servicio', COUNT(*) FROM adb_tts_p3_dev_joseneyra.bronze.servicio
    UNION ALL SELECT 'tecnico', COUNT(*) FROM adb_tts_p3_dev_joseneyra.bronze.tecnico
    UNION ALL SELECT 'vehiculo', COUNT(*) FROM adb_tts_p3_dev_joseneyra.bronze.vehiculo
)
SELECT
    tabla,
    filas,
    SUM(filas) OVER () AS total_bronze
FROM conteos
ORDER BY tabla;
