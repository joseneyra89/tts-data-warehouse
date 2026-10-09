# Databricks y dbt para Silver y Gold

## Objetivo

Crear el motor de transformación que leerá las tablas Delta de `bronze`, ejecutará dbt y escribirá modelos Delta en `silver` y `gold`.

Recursos previstos:

- Workspace: `adb-tts-p3-dev-joseneyra`
- Access Connector: `ac-tts-p3-dev-joseneyra`
- Cuenta ADLS: `stttsp3devjoseneyra`
- Grupo de recursos: `rg-tts-p3-dev`
- Región: `centralus`

Estado al 2026-10-09:

- Workspace creado correctamente con SKU Premium.
- Estado: `Succeeded`.
- Workspace ID: `7405619700877744`.
- URL: `adb-7405619700877744.4.azuredatabricks.net`.
- Access Connector creado con identidad administrada.
- Rol `Storage Blob Data Contributor` concedido sobre `stttsp3devjoseneyra`.
- Unity Catalog habilitado automáticamente.
- Catálogo predeterminado visible: `adb_tts_p3_dev_joseneyra`.
- Catálogos del sistema y de muestras disponibles: `system` y `samples`.
- Credencial de almacenamiento creada: `cred_adls_tts`.
- Ubicación `ext_bronze_tts`: `abfss://bronze@stttsp3devjoseneyra.dfs.core.windows.net/`, limitada a solo lectura y sin eventos de archivos.
- Ubicación `ext_silver_tts`: `abfss://silver@stttsp3devjoseneyra.dfs.core.windows.net/`, con escritura y sin eventos de archivos.
- Ubicación `ext_gold_tts`: `abfss://gold@stttsp3devjoseneyra.dfs.core.windows.net/`, con escritura y sin eventos de archivos.
- Esquemas creados en `adb_tts_p3_dev_joseneyra`: `bronze`, `silver` y `gold`.
- `silver` usa `ext_silver_tts/managed` como almacenamiento administrado.
- `gold` usa `ext_gold_tts/managed` como almacenamiento administrado.
- Las 12 tablas Delta de Bronze se registraron como tablas externas en `adb_tts_p3_dev_joseneyra.bronze` mediante `databricks/01_registrar_bronze.sql`.
- El comando `SHOW TABLES` devolvió las 12 tablas y las 15 instrucciones SQL finalizaron correctamente.
- `databricks/02_validar_bronze.sql` confirmó lectura de las 12 tablas y un total de 1,114,486 filas.

## 1. Aprovisionamiento

Ejecutar en Azure Cloud Shell, modo Bash:

```bash
cd ~/proyecto-3
bash infra/azure-cli/04_crear_databricks.sh
```

El script:

1. Registra el proveedor `Microsoft.Databricks`.
2. Crea un workspace Azure Databricks con SKU Premium. Azure for Students no admite el SKU `trial` y las nuevas áreas de trabajo Standard ya no son la opción vigente.
3. Crea un Access Connector con identidad administrada.
4. Concede `Storage Blob Data Contributor` sobre la cuenta de almacenamiento.

No inicia clústeres ni modifica los datos existentes en `bronze`.

## 2. Próximos pasos

Después del aprovisionamiento:

1. Abrir el workspace de Databricks.
2. Confirmar o crear el metastore de Unity Catalog.
3. Crear una credencial de almacenamiento con el Access Connector.
4. Registrar ubicaciones externas para `bronze`, `silver` y `gold`.
5. Crear un SQL warehouse pequeño y detenerlo automáticamente cuando no se use.
6. Crear el proyecto dbt con el adaptador `dbt-databricks`.
7. Implementar modelos incrementales con estrategia `merge`.
8. Crear un trabajo de Databricks y llamarlo desde ADF.

## Control de costos

- El workspace usa SKU Premium; el costo aparece cuando se ejecuta cómputo de Databricks, además de los recursos de Azure asociados.
- Mantener detenidos el SQL warehouse y cualquier cómputo cuando no se estén usando.
- Usar tamaños pequeños para este volumen académico.
- Revisar Azure Cost Management durante la implementación.
