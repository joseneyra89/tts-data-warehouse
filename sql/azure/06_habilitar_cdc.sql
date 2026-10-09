/* Azure 06 - Habilitar CDC después de validar la carga completa.
   Ejecutar como db_owner conectado directamente a TTS_OLTP. */
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> N'TTS_OLTP'
    THROW 51070, N'Conéctese directamente a TTS_OLTP antes de habilitar CDC.', 1;

IF EXISTS
(
    SELECT 1
    FROM (VALUES
        (N'Cliente'), (N'Vehiculo'), (N'Tecnico'), (N'Servicio'),
        (N'Repuesto'), (N'OrdenServicio'), (N'DetalleServicio'),
        (N'ConsumoRepuesto'), (N'Factura')
    ) AS Requerida(Nombre)
    WHERE OBJECT_ID(N'dbo.' + Requerida.Nombre, N'U') IS NULL
)
    THROW 51071, N'Faltan tablas requeridas. Complete y valide la carga antes de habilitar CDC.', 1;

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = DB_NAME() AND is_cdc_enabled = 1)
    EXEC sys.sp_cdc_enable_db;

DECLARE @Tabla SYSNAME;
DECLARE TablasCDC CURSOR LOCAL FAST_FORWARD FOR
SELECT Nombre
FROM (VALUES
    (N'Cliente'), (N'Vehiculo'), (N'Tecnico'), (N'Servicio'),
    (N'Repuesto'), (N'OrdenServicio'), (N'DetalleServicio'),
    (N'ConsumoRepuesto'), (N'Factura')
) AS T(Nombre);

OPEN TablasCDC;
FETCH NEXT FROM TablasCDC INTO @Tabla;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.tables
        WHERE object_id = OBJECT_ID(N'dbo.' + @Tabla)
          AND is_tracked_by_cdc = 0
    )
    BEGIN
        EXEC sys.sp_cdc_enable_table
            @source_schema = N'dbo',
            @source_name = @Tabla,
            @role_name = N'cdc_reader',
            @supports_net_changes = 1;
    END;

    FETCH NEXT FROM TablasCDC INTO @Tabla;
END;

CLOSE TablasCDC;
DEALLOCATE TablasCDC;

SELECT
    DB_NAME() AS BaseDatos,
    d.is_cdc_enabled AS CDC_Base,
    s.name AS Esquema,
    t.name AS Tabla,
    t.is_tracked_by_cdc AS CDC_Tabla
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
CROSS JOIN sys.databases AS d
WHERE d.name = DB_NAME()
  AND s.name = N'dbo'
  AND t.name IN
  (
      N'Cliente', N'Vehiculo', N'Tecnico', N'Servicio', N'Repuesto',
      N'OrdenServicio', N'DetalleServicio', N'ConsumoRepuesto', N'Factura'
  )
ORDER BY t.name;
