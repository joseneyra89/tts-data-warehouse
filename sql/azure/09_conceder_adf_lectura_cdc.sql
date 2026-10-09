/* Azure 09 - Autorizar la identidad administrada de ADF para leer el OLTP y CDC.
   Ejecutar conectado directamente a TTS_OLTP con la cuenta administradora de Microsoft Entra.
   No concede escritura, DDL ni db_owner. */
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> N'TTS_OLTP'
    THROW 51090, N'Conéctese directamente a la base TTS_OLTP antes de continuar.', 1;

DECLARE @Identidad SYSNAME = N'adf-tts-p3-dev-joseneyra';
DECLARE @SQL NVARCHAR(MAX);

IF DATABASE_PRINCIPAL_ID(N'cdc_reader') IS NULL
    THROW 51091, N'No existe el rol cdc_reader. Ejecute primero 06_habilitar_cdc.sql.', 1;

IF DATABASE_PRINCIPAL_ID(@Identidad) IS NULL
BEGIN
    SET @SQL = N'CREATE USER ' + QUOTENAME(@Identidad) + N' FROM EXTERNAL PROVIDER;';
    EXEC sys.sp_executesql @SQL;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    WHERE drm.role_principal_id = DATABASE_PRINCIPAL_ID(N'db_datareader')
      AND drm.member_principal_id = DATABASE_PRINCIPAL_ID(@Identidad)
)
BEGIN
    SET @SQL = N'ALTER ROLE [db_datareader] ADD MEMBER ' + QUOTENAME(@Identidad) + N';';
    EXEC sys.sp_executesql @SQL;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    WHERE drm.role_principal_id = DATABASE_PRINCIPAL_ID(N'cdc_reader')
      AND drm.member_principal_id = DATABASE_PRINCIPAL_ID(@Identidad)
)
BEGIN
    SET @SQL = N'ALTER ROLE [cdc_reader] ADD MEMBER ' + QUOTENAME(@Identidad) + N';';
    EXEC sys.sp_executesql @SQL;
END;

SELECT
    Usuario = miembro.name,
    Tipo = miembro.type_desc,
    Rol = rol.name
FROM sys.database_role_members AS drm
JOIN sys.database_principals AS rol
  ON rol.principal_id = drm.role_principal_id
JOIN sys.database_principals AS miembro
  ON miembro.principal_id = drm.member_principal_id
WHERE miembro.name = @Identidad
ORDER BY rol.name;

