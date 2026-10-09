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

Etapa actual: 5 - diseñar e implementar Silver/Gold con `dbt` incremental y `MERGE`, orquestado por ADF, y publicar Gold mediante Azure Synapse Analytics. El workspace Premium `adb-tts-p3-dev-joseneyra`, su Access Connector, Unity Catalog y las ubicaciones externas de `bronze`, `silver` y `gold` ya están configurados. Los tres esquemas Medallion y las 12 tablas Delta externas de Bronze están registrados y validados con 1,114,486 filas. La primera versión del proyecto dbt contiene las 12 fuentes Bronze y 12 modelos Silver incrementales con estrategia Delta `merge`.

Azure Cloud Shell se usa en modo efímero sin almacenamiento. El código reproducible se conserva en este repositorio y no contiene contraseñas.
