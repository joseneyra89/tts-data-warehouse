-- Publica una instantanea reemplazable de Gold en Parquet para Synapse Serverless.
-- INSERT OVERWRITE evita duplicados cuando el proceso se vuelve a ejecutar.

INSERT OVERWRITE DIRECTORY
  'abfss://gold@stttsp3devjoseneyra.dfs.core.windows.net/synapse/dim_cliente'
USING PARQUET
SELECT * FROM adb_tts_p3_dev_joseneyra.gold.dim_cliente;

INSERT OVERWRITE DIRECTORY
  'abfss://gold@stttsp3devjoseneyra.dfs.core.windows.net/synapse/dim_vehiculo'
USING PARQUET
SELECT * FROM adb_tts_p3_dev_joseneyra.gold.dim_vehiculo;

INSERT OVERWRITE DIRECTORY
  'abfss://gold@stttsp3devjoseneyra.dfs.core.windows.net/synapse/dim_tecnico'
USING PARQUET
SELECT * FROM adb_tts_p3_dev_joseneyra.gold.dim_tecnico;

INSERT OVERWRITE DIRECTORY
  'abfss://gold@stttsp3devjoseneyra.dfs.core.windows.net/synapse/dim_servicio'
USING PARQUET
SELECT * FROM adb_tts_p3_dev_joseneyra.gold.dim_servicio;

INSERT OVERWRITE DIRECTORY
  'abfss://gold@stttsp3devjoseneyra.dfs.core.windows.net/synapse/dim_repuesto'
USING PARQUET
SELECT * FROM adb_tts_p3_dev_joseneyra.gold.dim_repuesto;

INSERT OVERWRITE DIRECTORY
  'abfss://gold@stttsp3devjoseneyra.dfs.core.windows.net/synapse/dim_fecha'
USING PARQUET
SELECT * FROM adb_tts_p3_dev_joseneyra.gold.dim_fecha;

INSERT OVERWRITE DIRECTORY
  'abfss://gold@stttsp3devjoseneyra.dfs.core.windows.net/synapse/fact_servicio'
USING PARQUET
SELECT * FROM adb_tts_p3_dev_joseneyra.gold.fact_servicio;

INSERT OVERWRITE DIRECTORY
  'abfss://gold@stttsp3devjoseneyra.dfs.core.windows.net/synapse/fact_consumo_repuesto'
USING PARQUET
SELECT * FROM adb_tts_p3_dev_joseneyra.gold.fact_consumo_repuesto;

INSERT OVERWRITE DIRECTORY
  'abfss://gold@stttsp3devjoseneyra.dfs.core.windows.net/synapse/fact_factura'
USING PARQUET
SELECT * FROM adb_tts_p3_dev_joseneyra.gold.fact_factura;
