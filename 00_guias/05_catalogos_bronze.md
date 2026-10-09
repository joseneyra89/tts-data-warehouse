# Catálogos adicionales para Silver y Gold

## Motivo

Las nueve tablas dinámicas de Bronze contienen los hechos principales, pero `Vehiculo` y `Tecnico` guardan claves hacia catálogos que el dashboard necesita como descripciones. Antes de construir Silver se cargan tres tablas pequeñas:

| Origen | Destino Delta | Uso |
|---|---|---|
| `dbo.MarcaVehiculo` | `bronze/dbo.MarcaVehiculo` | Nombre de la marca |
| `dbo.ModeloVehiculo` | `bronze/dbo.ModeloVehiculo` | Modelo y relación con la marca |
| `dbo.Especialidad` | `bronze/dbo.Especialidad` | Especialidad del técnico |

## Implementación

Se usa el Mapping Data Flow independiente `dfCargaInicialCatalogos`, ejecutado por `plCargaInicialCatalogos`. Las tres ramas leen Azure SQL mediante `ls_azure_sql_tts_oltp` y escriben Delta mediante `ls_adls_gen2_tts`.

El proceso solo sobrescribe las tres rutas nuevas. No modifica las nueve tablas de la carga inicial principal. Los catálogos se consideran datos maestros de baja frecuencia y se cargan antes de ejecutar dbt.

## Validación realizada

La ejecución de `plCargaInicialCatalogos` terminó correctamente el 9 de octubre de 2026. Las tres ramas mostraron el mismo número de filas leídas y escritas:

| Receptor | Leídas | Escritas | Estado |
|---|---:|---:|---|
| `snkMarcaVehiculo` | 5 | 5 | `Success` |
| `snkModeloVehiculo` | 25 | 25 | `Success` |
| `snkEspecialidad` | 6 | 6 | `Success` |

Total cargado: 36 filas. No se vuelve a ejecutar salvo que cambien los catálogos del OLTP.
