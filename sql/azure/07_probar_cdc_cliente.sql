/* Azure 07 - Prueba controlada de CDC en dbo.Cliente.
   La fila es ficticia e identificable. El script es idempotente por RUC. */
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> N'TTS_OLTP'
    THROW 51080, N'Conéctese directamente a TTS_OLTP antes de probar CDC.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.tables
    WHERE object_id = OBJECT_ID(N'dbo.Cliente')
      AND is_tracked_by_cdc = 1
)
    THROW 51081, N'CDC no está habilitado en dbo.Cliente.', 1;

IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE RUC = '20999999999')
BEGIN
    INSERT dbo.Cliente
    (
        RUC, RazonSocial, Telefono, Direccion, Ciudad,
        TipoCliente, FechaRegistro, Estado
    )
    VALUES
    (
        '20999999999', N'Cliente CDC Prueba TTS S.A.C.', '900999999',
        N'Av. Prueba CDC 100', N'Lima', N'Transporte', '20260928', N'Activo'
    );

    PRINT N'Cliente ficticio insertado. Se espera el ciclo de captura CDC.';
END
ELSE
    PRINT N'El cliente ficticio ya existe; no se inserta un duplicado.';

SELECT ClienteID, RUC, RazonSocial, FechaRegistro, Estado
FROM dbo.Cliente
WHERE RUC = '20999999999';

-- En Azure SQL Database el ciclo normal de captura se ejecuta periódicamente.
WAITFOR DELAY '00:00:25';

DECLARE @Desde binary(10) = sys.fn_cdc_get_min_lsn(N'dbo_Cliente');
DECLARE @Hasta binary(10) = sys.fn_cdc_get_max_lsn();

IF @Desde IS NULL
    THROW 51082, N'No se encontró el LSN mínimo de la instancia dbo_Cliente.', 1;

SELECT
    CASE c.__$operation
        WHEN 1 THEN N'DELETE'
        WHEN 2 THEN N'INSERT'
        WHEN 3 THEN N'UPDATE_ANTES'
        WHEN 4 THEN N'UPDATE_DESPUES'
    END AS OperacionCDC,
    sys.fn_cdc_map_lsn_to_time(c.__$start_lsn) AS FechaCaptura,
    c.ClienteID,
    c.RUC,
    c.RazonSocial,
    c.Estado
FROM cdc.fn_cdc_get_all_changes_dbo_Cliente(@Desde, @Hasta, N'all') AS c
WHERE c.RUC = '20999999999'
ORDER BY c.__$start_lsn, c.__$seqval;
