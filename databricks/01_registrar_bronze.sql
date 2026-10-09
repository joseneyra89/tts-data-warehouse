-- Registra en Unity Catalog las tablas Delta que ADF ya mantiene en ADLS Bronze.
-- Estas sentencias solo crean metadatos; no copian ni reescriben los datos.

USE CATALOG `adb_tts_p3_dev_joseneyra`;
USE SCHEMA `bronze`;

CREATE TABLE IF NOT EXISTS `cliente`
USING DELTA
LOCATION 'abfss://bronze@stttsp3devjoseneyra.dfs.core.windows.net/dbo.Cliente';

CREATE TABLE IF NOT EXISTS `vehiculo`
USING DELTA
LOCATION 'abfss://bronze@stttsp3devjoseneyra.dfs.core.windows.net/dbo.Vehiculo';

CREATE TABLE IF NOT EXISTS `tecnico`
USING DELTA
LOCATION 'abfss://bronze@stttsp3devjoseneyra.dfs.core.windows.net/dbo.Tecnico';

CREATE TABLE IF NOT EXISTS `servicio`
USING DELTA
LOCATION 'abfss://bronze@stttsp3devjoseneyra.dfs.core.windows.net/dbo.Servicio';

CREATE TABLE IF NOT EXISTS `repuesto`
USING DELTA
LOCATION 'abfss://bronze@stttsp3devjoseneyra.dfs.core.windows.net/dbo.Repuesto';

CREATE TABLE IF NOT EXISTS `ordenservicio`
USING DELTA
LOCATION 'abfss://bronze@stttsp3devjoseneyra.dfs.core.windows.net/dbo.OrdenServicio';

CREATE TABLE IF NOT EXISTS `detalleservicio`
USING DELTA
LOCATION 'abfss://bronze@stttsp3devjoseneyra.dfs.core.windows.net/dbo.DetalleServicio';

CREATE TABLE IF NOT EXISTS `consumorepuesto`
USING DELTA
LOCATION 'abfss://bronze@stttsp3devjoseneyra.dfs.core.windows.net/dbo.ConsumoRepuesto';

CREATE TABLE IF NOT EXISTS `factura`
USING DELTA
LOCATION 'abfss://bronze@stttsp3devjoseneyra.dfs.core.windows.net/dbo.Factura';

CREATE TABLE IF NOT EXISTS `marcavehiculo`
USING DELTA
LOCATION 'abfss://bronze@stttsp3devjoseneyra.dfs.core.windows.net/dbo.MarcaVehiculo';

CREATE TABLE IF NOT EXISTS `modelovehiculo`
USING DELTA
LOCATION 'abfss://bronze@stttsp3devjoseneyra.dfs.core.windows.net/dbo.ModeloVehiculo';

CREATE TABLE IF NOT EXISTS `especialidad`
USING DELTA
LOCATION 'abfss://bronze@stttsp3devjoseneyra.dfs.core.windows.net/dbo.Especialidad';

SHOW TABLES IN `adb_tts_p3_dev_joseneyra`.`bronze`;
