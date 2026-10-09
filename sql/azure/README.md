# Carga de TTS_OLTP en Azure SQL Database

Estos archivos conservan el modelo y los datos sintéticos del entregable local, pero se conectan directamente a la base `TTS_OLTP` ya creada en Azure. No crean bases, no cambian el modelo de recuperación y no contienen secretos.

Ejecutar en SSMS, en ventanas nuevas y en este orden:

1. `00_verificar_destino.sql`: confirma base, intercalación y estado vacío.
2. `01_crear_tablas.sql`: crea las 16 tablas y sus restricciones.
3. `02_datos_maestros.sql`: carga catálogos y maestros.
4. `03_generacion_masiva.sql`: genera la carga operativa de aproximadamente 1,1 millones de filas.
5. `04_validacion.sql`: comprueba conteos, reglas y restricciones.
6. `05_consultas_prueba.sql`: ejecuta consultas analíticas de solo lectura.
7. `06_habilitar_cdc.sql`: habilita CDC en la base y en las nueve tablas requeridas.
8. `07_probar_cdc_cliente.sql`: inserta una fila ficticia idempotente y comprueba su evento CDC.
9. `08_limpiar_prueba_cdc_cliente.sql`: elimina la fila ficticia, comprueba `DELETE` y restaura el conteo original.
10. `09_conceder_adf_lectura_cdc.sql`: crea el usuario de la identidad administrada de ADF y le concede solo lectura del OLTP y del CDC.

No continúe al archivo siguiente si el anterior informa un error. No ejecute `06_habilitar_cdc.sql` hasta que `04_validacion.sql` finalice correctamente. Los archivos 07 y 08 prueban el ciclo `INSERT`/`DELETE` con el RUC ficticio `20999999999` y dejan nuevamente 5000 clientes. El archivo 09 debe ejecutarse con autenticación Microsoft Entra y requiere que `adf-tts-p3-dev-joseneyra` conserve ese nombre. Los archivos originales de SQL Server local se conservan sin cambios fuera de este proyecto.
