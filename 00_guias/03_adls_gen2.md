# ADLS Gen2 y zonas Medallion

## Resultado desplegado

La cuenta se creó manualmente desde Azure Portal después de revisar costo, red, recuperación y seguridad.

| Propiedad | Valor |
|---|---|
| Cuenta | `stttsp3devjoseneyra` |
| Grupo de recursos | `rg-tts-p3-dev` |
| Región | Central US |
| Tipo | StorageV2 con espacio de nombres jerárquico |
| Rendimiento | Estándar |
| Redundancia | LRS |
| Nivel | Hot |
| TLS mínimo | 1.2 |
| Acceso anónimo | Deshabilitado |
| Acceso público de red | Habilitado desde todas las redes |
| Copias entre cuentas | Solo el mismo inquilino de Microsoft Entra |
| Eliminación temporal | 7 días para blobs y contenedores |
| Versionado y fuente de cambios | Deshabilitados |

El usuario de desarrollo tiene el rol `Storage Blob Data Owner` en la cuenta para trabajar con datos y ACL de ADLS mediante Microsoft Entra. Las claves de cuenta permanecen habilitadas temporalmente para la configuración inicial, pero no deben guardarse ni usarse en el código.

## Contenedores

- `bronze`: datos recibidos desde el origen sin reglas de negocio.
- `silver`: datos depurados, tipados y deduplicados.
- `gold`: dimensiones, hechos y agregados de consumo.

Los tres contenedores son privados. El contenedor del sistema `$logs` no forma parte de la arquitectura y no debe usarse ni eliminarse manualmente.

## Infraestructura reproducible

`infra/azure-cli/03_crear_adls_gen2.sh` representa la configuración aprobada. Usa autenticación de Microsoft Entra para crear los contenedores y no lee ni guarda claves de almacenamiento.

## Decisión aplicada para Bronze

El recurso CDC de nivel superior de Azure Data Factory aplica cambios netos a tablas Delta, lo que produce una réplica de estado actual. El requisito académico de este proyecto describe Bronze como un historial inmutable con operación CDC, LSN, hora de captura y tabla de origen. Se evaluaron conscientemente dos opciones:

1. Réplica Delta de estado actual mediante el recurso CDC de ADF.
2. Eventos CDC append-only mediante micro-lotes de ADF que consultan las funciones CDC y escriben archivos de eventos.

Se eligió la primera opción porque el enunciado exige explícitamente el recurso CDC nativo de ADF. La diferencia semántica se documenta como limitación: ADF escribe el estado neto por clave y no conserva todos los eventos ni sus LSN como filas append-only. La configuración y la prueba se registran en `00_guias/04_adf_cdc_bronze.md`.
