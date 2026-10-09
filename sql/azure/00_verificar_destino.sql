/* Verificación de seguridad antes de cargar el OLTP en Azure SQL Database.
   Este archivo no crea ni modifica objetos permanentes. */
SET NOCOUNT ON;

IF DB_NAME() <> N'TTS_OLTP'
    THROW 51000, N'Conéctese directamente a la base TTS_OLTP antes de continuar.', 1;

IF CONVERT(nvarchar(128), DATABASEPROPERTYEX(DB_NAME(), 'Collation')) <> N'Modern_Spanish_CI_AS'
    THROW 51001, N'La intercalación no coincide con Modern_Spanish_CI_AS.', 1;

SELECT
    DB_NAME() AS BaseDatos,
    SUSER_SNAME() AS UsuarioActual,
    CONVERT(nvarchar(128), DATABASEPROPERTYEX(DB_NAME(), 'Collation')) AS Intercalacion,
    CONVERT(nvarchar(128), DATABASEPROPERTYEX(DB_NAME(), 'Edition')) AS Edicion,
    CONVERT(nvarchar(128), DATABASEPROPERTYEX(DB_NAME(), 'ServiceObjective')) AS ObjetivoServicio,
    (SELECT is_cdc_enabled FROM sys.databases WHERE name = DB_NAME()) AS CDC_Habilitado,
    (SELECT COUNT_BIG(*) FROM sys.tables WHERE is_ms_shipped = 0) AS TablasUsuario;
