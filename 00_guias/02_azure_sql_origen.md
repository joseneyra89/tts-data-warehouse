# Azure SQL Database como origen OLTP

## Resultado desplegado

La base `TTS_OLTP` se creó manualmente desde Azure Portal para comprender cada decisión antes de automatizarla.

| Propiedad | Valor |
|---|---|
| Suscripción | Azure for Students |
| Grupo de recursos | `rg-tts-p3-dev` |
| Servidor lógico | `sql-tts-p3-dev-joseneyra` |
| Base de datos | `TTS_OLTP` |
| Región | Central US |
| Plan | General Purpose, Serverless, Gen5, 2 vCores |
| Almacenamiento | 32 GB |
| Oferta gratuita | 100 000 segundos-vCore al mes |
| Al agotar la oferta | Pausar hasta el siguiente mes |
| Pausa por inactividad | 60 minutos |
| Copias de seguridad | Redundancia local |
| Intercalación | `Modern_Spanish_CI_AS` |
| TLS mínimo | 1.2 |

El grupo de recursos está registrado en `eastus`, pero los recursos de datos se ubican en `centralus` porque Azure for Students no permitió crear el servidor SQL en East US. La ubicación del grupo solo almacena sus metadatos; los siguientes recursos de datos deben usar Central US siempre que el servicio esté disponible allí.

## Comprobación inicial

Ejecutar en `TTS_OLTP`:

```sql
SELECT
    DB_NAME() AS BaseDatos,
    SUSER_SNAME() AS UsuarioActual,
    DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS Intercalacion,
    DATABASEPROPERTYEX(DB_NAME(), 'Edition') AS Edicion,
    DATABASEPROPERTYEX(DB_NAME(), 'ServiceObjective') AS ObjetivoServicio;

SELECT name, is_cdc_enabled
FROM sys.databases
WHERE name = DB_NAME();
```

Antes de la carga, `is_cdc_enabled` debe ser `0`. CDC se habilita después de crear y validar las tablas.

## Infraestructura reproducible

El archivo `infra/azure-cli/02_crear_azure_sql_gratuito.sh` representa la configuración aprobada en el portal. No guarda contraseñas: si el servidor no existe, las solicita de forma oculta durante la ejecución. El script es conservador y no vuelve a crear el servidor o la base si ya existen.

No ejecutar el script sobre otra suscripción sin verificar antes la disponibilidad de la oferta gratuita y la región. La variable opcional `CLIENT_IP` crea una regla para un equipo específico; no debe contener credenciales.

## Carga del modelo

Los archivos de `sql/azure` se conectan directamente a la base ya creada, por lo que no contienen `CREATE DATABASE`, `USE master`, cambios de recuperación ni rutas de archivos locales. Deben ejecutarse desde SSMS en el orden numérico y detenerse si una validación falla.

La carga completa supera un millón de filas. Se recomienda SSMS en lugar del editor web para evitar límites de sesión del navegador.
