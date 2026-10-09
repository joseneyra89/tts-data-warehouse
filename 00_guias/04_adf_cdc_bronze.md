# Azure Data Factory CDC hacia Bronze

## Resultado desplegado

Se creó manualmente `adf-tts-p3-dev-joseneyra` en Central US y se configuró el recurso CDC nativo `cdcOltpBronzeV2`.

| Elemento | Configuración |
|---|---|
| Origen | Azure SQL Database `TTS_OLTP` |
| Servicio vinculado de origen | `ls_azure_sql_tts_oltp` |
| Autenticación SQL | Identidad administrada asignada por el sistema |
| Destino | Delta Lake en ADLS Gen2 |
| Servicio vinculado de destino | `ls_adls_gen2_tts` |
| Contenedor | `bronze` |
| Latencia | 15 minutos |
| Estado habitual | Detenido fuera de pruebas |

La identidad administrada de ADF tiene `Storage Blob Data Contributor` únicamente sobre `stttsp3devjoseneyra`. En `TTS_OLTP` es usuario externo y pertenece solo a `db_datareader` y `cdc_reader`.

## Mapeos y claves

| Origen | Destino Delta | Clave |
|---|---|---|
| `dbo.Cliente` | `bronze/dbo.Cliente` | `ClienteID` |
| `dbo.ConsumoRepuesto` | `bronze/dbo.ConsumoRepuesto` | `ConsumoID` |
| `dbo.DetalleServicio` | `bronze/dbo.DetalleServicio` | `DetalleID` |
| `dbo.Factura` | `bronze/dbo.Factura` | `FacturaID` |
| `dbo.OrdenServicio` | `bronze/dbo.OrdenServicio` | `OrdenID` |
| `dbo.Repuesto` | `bronze/dbo.Repuesto` | `RepuestoID` |
| `dbo.Servicio` | `bronze/dbo.Servicio` | `ServicioID` |
| `dbo.Tecnico` | `bronze/dbo.Tecnico` | `TecnicoID` |
| `dbo.Vehiculo` | `bronze/dbo.Vehiculo` | `VehiculoID` |

`Auto map` permanece habilitado en los nueve mapeos. Las claves permiten que el destino Delta aplique actualizaciones y eliminaciones.

## Carga inicial validada

El Data Flow `dfCargaInicialCliente`, ejecutado por `plCargaInicialCliente`, cargó una instantánea completa hacia las mismas tablas Delta. El nombre histórico del recurso se conserva, aunque contiene nueve ramas independientes.

| Tabla | Filas |
|---|---:|
| `Cliente` | 5,000 |
| `Vehiculo` | 15,000 |
| `Tecnico` | 200 |
| `Servicio` | 50 |
| `Repuesto` | 500 |
| `OrdenServicio` | 200,000 |
| `DetalleServicio` | 396,400 |
| `ConsumoRepuesto` | 297,300 |
| `Factura` | 200,000 |
| **Total** | **1,114,450** |

La carga inicial usa sobrescritura y no debe volver a ejecutarse después de activar CDC.

## Recuperación del punto de control

El primer recurso permaneció detenido durante más tiempo que la retención inicial del log CDC. Al reanudarlo, ADF devolvió un error engañoso sobre argumentos insuficientes para `cdc.fn_cdc_get_net_changes_*`; el LSN guardado ya estaba fuera del intervalo válido.

Se amplió la retención del trabajo de limpieza a 43,200 minutos (30 días), se creó `cdcOltpBronzeV2` con `skipInitialLoad: true` y se retiró el recurso anterior. Esto evita duplicar la instantánea ya cargada y establece un punto de control nuevo.

## Prueba final realizada

1. Se inició `cdcOltpBronzeV2` con el depurador de Data Flow apagado.
2. Se insertó un cliente ficticio con RUC `20999999997`.
3. ADF informó un cambio escrito en `dbo.Cliente`.
4. En un microlote posterior se eliminó la fila de prueba.
5. ADF informó dos cambios acumulados y las nueve tablas terminaron con estado `Succeeded`.
6. El resultado confirma inserciones y eliminaciones sobre la réplica Delta de Bronze.

El CDC de nivel superior aplica cambios netos por clave: Bronze representa el estado actual de cada tabla, no un diario append-only con cada operación y LSN. Esta diferencia respecto al texto académico debe explicarse en el informe.

## Control de costos

- Mantener `Data flow debug` apagado salvo una depuración deliberada.
- Usar latencia de 15 minutos, no tiempo real.
- Iniciar CDC solo durante pruebas o demostraciones supervisadas.
- Pulsar `Stop` después de verificar el ciclo esperado.

