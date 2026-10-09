/* Azure 08 - Retirar la fila ficticia y verificar el DELETE en CDC.
   El script es idempotente por RUC. */
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> N'TTS_OLTP'
    THROW 51090, N'Conéctese directamente a TTS_OLTP antes de limpiar la prueba CDC.', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.tables
    WHERE object_id = OBJECT_ID(N'dbo.Cliente')
      AND is_tracked_by_cdc = 1
)
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.Cliente WHERE RUC = '20999999999')
    BEGIN
        DELETE dbo.Cliente
        WHERE RUC = '20999999999';

        PRINT N'Cliente ficticio eliminado. Se espera el ciclo de captura CDC.';
    END
    ELSE
        PRINT N'El cliente ficticio ya no existe; no se realiza otro DELETE.';
END
ELSE
    THROW 51091, N'CDC no está habilitado en dbo.Cliente.', 1;

WAITFOR DELAY '00:00:25';

DECLARE @Desde binary(10) = sys.fn_cdc_get_min_lsn(N'dbo_Cliente');
DECLARE @Hasta binary(10) = sys.fn_cdc_get_max_lsn();

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

SELECT
    COUNT_BIG(*) AS ClientesActuales,
    COUNT_BIG(CASE WHEN RUC = '20999999999' THEN 1 END) AS FilasPruebaRestantes
FROM dbo.Cliente;
