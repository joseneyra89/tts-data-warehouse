# Proyecto 3 - TTS Data Warehouse en Azure

Este repositorio contiene la implementación académica de **TRUCK TOP SERVICE** para el Proyecto 3. Su objetivo es propagar cambios del OLTP hasta Power BI Service mediante CDC, arquitectura Medallion y micro-lotes.

## Arquitectura objetivo

```text
Azure SQL Database (OLTP + CDC)
  -> Azure Data Factory CDC nativo
  -> ADLS Gen2 /bronze (tablas Delta de estado actual)
  -> dbt: /silver (datos depurados) -> /gold (modelo dimensional)
  -> Azure Synapse Analytics
  -> Power BI Service
```

## Regla de costos

El presupuesto es US$100 de Azure for Students para un año. Ningún recurso de cómputo se deja ejecutándose fuera de una sesión de trabajo o demostración. En especial, el recurso CDC de ADF usa cómputo de Data Flow, y un pool dedicado de Synapse se pausa inmediatamente después de cada ejecución.

La guía de implementación empieza en [00_guias/01_ruta_de_aprendizaje.md](00_guias/01_ruta_de_aprendizaje.md). La etapa actual continúa en [00_guias/06_databricks_dbt.md](00_guias/06_databricks_dbt.md).

## Estado

Etapa 4 completada. La carga inicial escribió 1,114,450 filas en nueve tablas Delta dinámicas bajo `bronze/dbo.*`. Una carga complementaria escribió 36 filas de catálogo (`MarcaVehiculo`, `ModeloVehiculo` y `Especialidad`), dejando 12 tablas y 1,114,486 filas iniciales en Bronze. El recurso activo `cdcOltpBronzeV2` usa CDC nativo de ADF, cambios netos, claves explícitas y una latencia de 15 minutos. Una prueba controlada confirmó la propagación de un `INSERT` y su posterior `DELETE` en `dbo.Cliente`.

La primera definición `cdcOltpBronze` quedó con un punto de control fuera de la retención de CDC después de varios días detenida y fue reemplazada por `cdcOltpBronzeV2`. La retención de limpieza de CDC en Azure SQL se amplió a 30 días. El recurso se detiene fuera de pruebas para controlar costos.

Etapa actual: 6 - publicar Gold mediante Azure Synapse Analytics y conectarlo con Power BI. El Job `job_dbt_tts_medallion` ejecuta Silver y Gold en orden; ambas tareas finalizaron correctamente. Gold contiene seis dimensiones (21,846 filas) y tres hechos (893,700 filas). El workspace serverless `syn-tts-p3-dev-joseneyra` ya está creado y los scripts reproducibles para publicar Parquet y registrar las vistas están en `databricks/03_publicar_gold_synapse.sql` y `synapse/`.

Las cargas Silver/Gold usan `MERGE` para altas y modificaciones. Las operaciones `sync_silver_hard_deletes` y `sync_gold_hard_deletes` comparan las claves contra la capa anterior después de cada carga para propagar también las eliminaciones físicas.

Azure Cloud Shell se usa en modo efímero sin almacenamiento. El código reproducible se conserva en este repositorio y no contiene contraseñas.
