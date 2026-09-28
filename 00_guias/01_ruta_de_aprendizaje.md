# Ruta de aprendizaje e implementación

Esta guía avanza por etapas. No pases a la siguiente hasta que la comprobación de la actual funcione. Cada archivo de código se guardará en este repositorio antes de ejecutarse en Azure.

## Etapa 0 - Preparación sin costo

Objetivo: crear el repositorio Git, comprobar acceso a la suscripción Azure for Students e instalar las herramientas locales.

Necesitarás una cuenta de GitHub, tu cuenta de Azure for Students y Power BI Desktop. No se crea ningún recurso de pago en esta etapa.

Comprobación final:

```powershell
az login
az account show --output table
az version
git --version
```

### Acceso temporal por Cloud Shell

Si Azure CLI local queda bloqueado por la política de autenticación del directorio, se puede usar Cloud Shell desde el portal. Seleccionar **No se requiere ninguna cuenta de almacenamiento** crea una sesión Bash efímera, sin archivos persistentes. Es suficiente para ejecutar comandos CLI de administración mientras el código fuente se conserva localmente y en Git.

No pegues contraseñas, tokens ni cadenas de conexión en este repositorio o en el chat.

## Etapa 1 - Inventario y presupuesto

Objetivo: identificar la suscripción, región disponible, cuota y costo estimado antes de desplegar.

Resultado esperado: un presupuesto en Azure Cost Management, una alerta de consumo y un grupo de recursos vacío con etiquetas de proyecto.

## Etapa 2 - Origen en Azure SQL Database

Objetivo: migrar `TTS_OLTP`, sus 16 tablas y sus datos sintéticos a Azure SQL Database. Después se habilita CDC únicamente en las tablas necesarias para el dashboard: Cliente, Vehiculo, Tecnico, Servicio, Repuesto, OrdenServicio, DetalleServicio, ConsumoRepuesto y Factura.

Comprobación final: insertar una fila de prueba y ver su cambio en las tablas CDC.

## Etapa 3 - ADLS Gen2 y Bronze

Objetivo: crear el lago con contenedores y rutas particionadas. Bronze conserva eventos sin transformar, con operación CDC, marca de cambio, hora de captura y nombre de tabla.

## Etapa 4 - Azure Data Factory CDC

Objetivo: configurar el recurso CDC nativo de ADF desde Azure SQL Database hacia Bronze. Durante el aprendizaje se ejecuta solo en ventanas breves; no se deja continuo durante días.

## Etapa 5 - dbt y Silver/Gold

Objetivo: convertir las reglas existentes de dimensiones, hechos y calidad a modelos dbt. Los modelos incrementales deben usar una clave de negocio y la marca CDC para que una reejecución no duplique resultados.

## Etapa 6 - Synapse y Power BI Service

Objetivo: publicar el modelo Gold en Synapse, reconectar el dashboard actual y publicarlo a Power BI Service.

## Etapa 7 - Demostración y cierre

Objetivo: insertar 3 o 4 filas en el OLTP, iniciar los micro-lotes y probar que los cambios llegan al dashboard. Guardar capturas, logs y costos antes de pausar el cómputo.

## Decisión técnica que resolveremos antes de crear Synapse

El requisito pide `dbt` incremental con `MERGE`. Synapse serverless permite consultar archivos del lago, pero no ejecuta `MERGE`; un pool dedicado sí puede hacerlo y debe permanecer pausado cuando no se usa. Verificaremos la disponibilidad y el costo de tu región antes de crear este componente. Si no cabe en el presupuesto, documentaremos con claridad la alternativa aceptada por el docente antes de desplegarla.
