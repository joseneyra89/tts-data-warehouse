/*
    TRUCK TOP SERVICE S.A.C. - Azure 05, consultas de prueba para el ETL
    Azure SQL Database. Ejecutar despues de los scripts 00 a 04.

    Todas las consultas son de solo lectura.
    - Ventas: Factura.EstadoFactura = 'Emitida', periodo por FechaFactura.
    - Cobros: periodo por Pago.FechaPago; son una medida diferente de las ventas.
    - CostoManoObra es el IMPORTE COBRADO por la linea de servicio.
    - HorasTrabajo son las horas TOTALES de la linea; no multiplicar por Cantidad.
    - ConsumoRepuesto.Costo es el COSTO TOTAL de la linea de consumo.
    - El costo interno de mano de obra se estima en S/ 65 por hora.
    - El generador cobra los repuestos al costo por 1.30.
    - El margen mostrado es estimado: excluye gastos y otros costos indirectos.

    Cada tabla de detalle se agrega por separado antes de unirla con otra.
    Unir DetalleServicio, ConsumoRepuesto y Pago sin agregacion previa
    multiplicaria filas y produciria importes y cantidades incorrectos.
*/
SET NOCOUNT ON;

-- La guarda evita ejecutar las consultas en otra base.
IF DB_NAME() <> N'TTS_OLTP'
    THROW 51060, 'Ejecute las consultas en la base TTS_OLTP.', 1;

IF EXISTS
(
    SELECT 1
    FROM (VALUES
        (N'dbo.Cliente'), (N'dbo.Vehiculo'), (N'dbo.ModeloVehiculo'),
        (N'dbo.Tecnico'), (N'dbo.Servicio'), (N'dbo.OrdenServicio'),
        (N'dbo.DetalleServicio'), (N'dbo.Repuesto'),
        (N'dbo.ConsumoRepuesto'), (N'dbo.Factura'), (N'dbo.Pago')
    ) AS Esperada(Nombre)
    WHERE OBJECT_ID(Esperada.Nombre, N'U') IS NULL
)
    THROW 51061, 'Faltan tablas: ejecute primero los scripts de creacion y carga.', 1;

IF COL_LENGTH(N'dbo.Factura', N'EstadoFactura') IS NULL
    THROW 51062, 'Falta Factura.EstadoFactura: utilice el esquema de este entregable.', 1;

/*
    1. SERVICIOS REALIZADOS POR MES
    Periodo operativo por FechaSalida de ordenes finalizadas.
    CantidadServicios suma las unidades; LineasServicio cuenta los detalles.
    Una orden con varias lineas se cuenta una sola vez en OrdenesAtendidas.
*/
SELECT
    DATEFROMPARTS(YEAR(o.FechaSalida), MONTH(o.FechaSalida), 1) AS MesServicio,
    COUNT(DISTINCT o.OrdenID) AS OrdenesAtendidas,
    COUNT_BIG(*) AS LineasServicio,
    SUM(CONVERT(bigint, d.Cantidad)) AS CantidadServicios,
    SUM(d.HorasTrabajo) AS HorasTrabajo,
    SUM(d.CostoManoObra) AS ImporteManoObraCobrado
FROM dbo.OrdenServicio AS o
INNER JOIN dbo.DetalleServicio AS d ON d.OrdenID = o.OrdenID
WHERE o.Estado = N'Finalizado'
GROUP BY DATEFROMPARTS(YEAR(o.FechaSalida), MONTH(o.FechaSalida), 1)
ORDER BY MesServicio;

/*
    2. INGRESOS POR ANIO
    VentasSinIGV es la medida de ingreso. TotalFacturado incluye IGV.
    No se usa la fecha de los pagos para asignar el periodo de las ventas.
    Los importes del anio 2026 pertenecen a un escenario sintetico completo.
*/
SELECT
    YEAR(f.FechaFactura) AS Anio,
    COUNT_BIG(*) AS FacturasEmitidas,
    SUM(f.Subtotal) AS VentasSinIGV,
    SUM(f.IGV) AS IGVFacturado,
    SUM(f.Total) AS TotalFacturado,
    CAST(AVG(f.Subtotal) AS decimal(18,2)) AS VentaMediaSinIGV
FROM dbo.Factura AS f
WHERE f.EstadoFactura = N'Emitida'
GROUP BY YEAR(f.FechaFactura)
ORDER BY Anio;

/*
    3. TOP 20 CLIENTES POR MARGEN ESTIMADO
    La venta se toma del Subtotal historico de la factura emitida.
    Costo estimado = horas registradas * S/ 65 + costo de repuestos consumidos.
    No se resta IGV ni se considera el cobro un segundo ingreso.
    MargenEstimado no equivale a utilidad neta contable.
*/
;WITH ManoObraPorOrden AS
(
    SELECT OrdenID, SUM(HorasTrabajo) AS HorasTrabajo
    FROM dbo.DetalleServicio
    GROUP BY OrdenID
), RepuestoPorOrden AS
(
    SELECT OrdenID, SUM(Costo) AS CostoRepuestos
    FROM dbo.ConsumoRepuesto
    GROUP BY OrdenID
), RentabilidadCliente AS
(
    SELECT
        o.ClienteID,
        COUNT_BIG(*) AS OrdenesFacturadas,
        SUM(f.Subtotal) AS VentasSinIGV,
        SUM(COALESCE(m.HorasTrabajo, 0) * CAST(65.00 AS decimal(10,2)))
            AS CostoManoObraEstimado,
        SUM(COALESCE(r.CostoRepuestos, 0)) AS CostoRepuestos
    FROM dbo.Factura AS f
    INNER JOIN dbo.OrdenServicio AS o ON o.OrdenID = f.OrdenID
    LEFT JOIN ManoObraPorOrden AS m ON m.OrdenID = o.OrdenID
    LEFT JOIN RepuestoPorOrden AS r ON r.OrdenID = o.OrdenID
    WHERE f.EstadoFactura = N'Emitida'
    GROUP BY o.ClienteID
)
SELECT TOP (20)
    c.ClienteID,
    c.RUC,
    c.RazonSocial,
    c.TipoCliente,
    c.Ciudad,
    r.OrdenesFacturadas,
    r.VentasSinIGV,
    CAST(r.CostoManoObraEstimado AS decimal(18,2)) AS CostoManoObraEstimado,
    r.CostoRepuestos,
    CAST(r.VentasSinIGV - r.CostoManoObraEstimado - r.CostoRepuestos
        AS decimal(18,2)) AS MargenEstimado,
    CAST(100.0 * (r.VentasSinIGV - r.CostoManoObraEstimado - r.CostoRepuestos)
        / NULLIF(r.VentasSinIGV, 0) AS decimal(10,2)) AS MargenEstimadoPct
FROM RentabilidadCliente AS r
INNER JOIN dbo.Cliente AS c ON c.ClienteID = r.ClienteID
ORDER BY MargenEstimado DESC, c.ClienteID;

/*
    4. TOP 20 TECNICOS POR ORDENES FINALIZADAS
    Productividad operativa: ordenes, servicios y horas registradas.
    No representa utilizacion de capacidad, ya que el modelo no incluye
    turnos disponibles ni ausencias. La duracion de estancia usa cada orden
    una sola vez, despues de agregar sus detalles.
*/
;WITH ServicioPorOrden AS
(
    SELECT
        OrdenID,
        SUM(CONVERT(bigint, Cantidad)) AS CantidadServicios,
        SUM(HorasTrabajo) AS HorasTrabajo,
        SUM(CostoManoObra) AS ImporteManoObraCobrado
    FROM dbo.DetalleServicio
    GROUP BY OrdenID
)
SELECT TOP (20)
    t.TecnicoID,
    CONCAT(t.Nombre, N' ', t.Apellido) AS Tecnico,
    COUNT_BIG(*) AS OrdenesFinalizadas,
    SUM(COALESCE(d.CantidadServicios, 0)) AS CantidadServicios,
    SUM(COALESCE(d.HorasTrabajo, 0)) AS HorasTrabajo,
    SUM(COALESCE(d.ImporteManoObraCobrado, 0)) AS ImporteManoObraCobrado,
    CAST(AVG(CONVERT(decimal(10,2), DATEDIFF(DAY, o.FechaIngreso, o.FechaSalida)))
        AS decimal(10,2)) AS DiasEstanciaPromedio
FROM dbo.OrdenServicio AS o
INNER JOIN dbo.Tecnico AS t ON t.TecnicoID = o.TecnicoID
LEFT JOIN ServicioPorOrden AS d ON d.OrdenID = o.OrdenID
WHERE o.Estado = N'Finalizado'
GROUP BY t.TecnicoID, t.Nombre, t.Apellido
ORDER BY OrdenesFinalizadas DESC, HorasTrabajo DESC, t.TecnicoID;

/*
    5. TOP 20 REPUESTOS MAS UTILIZADOS
    Incluye consumo realizado de ordenes finalizadas y en proceso.
    Costo ya es el importe total de cada linea: no multiplicar por Cantidad.
    StockActual es una foto actual y no debe sumarse sobre las lineas.
*/
SELECT TOP (20)
    r.RepuestoID,
    r.NombreRepuesto,
    r.Categoria,
    r.Marca,
    SUM(CONVERT(bigint, cr.Cantidad)) AS UnidadesConsumidas,
    COUNT(DISTINCT cr.OrdenID) AS OrdenesConConsumo,
    SUM(cr.Costo) AS CostoTotalConsumido,
    r.StockActual
FROM dbo.ConsumoRepuesto AS cr
INNER JOIN dbo.Repuesto AS r ON r.RepuestoID = cr.RepuestoID
INNER JOIN dbo.OrdenServicio AS o ON o.OrdenID = cr.OrdenID
WHERE o.Estado IN (N'Finalizado', N'En proceso')
GROUP BY r.RepuestoID, r.NombreRepuesto, r.Categoria, r.Marca, r.StockActual
ORDER BY UnidadesConsumidas DESC, r.RepuestoID;

/*
    6. CARTERA POR CLIENTE AL CIERRE SIMULADO
    Cada pago se agrega por factura antes de unirlo con Factura.
    La cartera se reconstruye al corte; no depende del EstadoPago actual.
    Antiguedad mide dias desde emision, NO mora: no existe FechaVencimiento.
    El limite exclusivo tambien funciona si las fechas contienen hora.
*/
DECLARE @FechaCorte date = CONVERT(date, '20261231', 112);
DECLARE @FinCorte datetime2(0) = DATEADD(DAY, 1, CONVERT(datetime2(0), @FechaCorte));

;WITH PagosPorFactura AS
(
    SELECT FacturaID, SUM(MontoPagado) AS PagadoAlCorte
    FROM dbo.Pago
    WHERE FechaPago < @FinCorte
    GROUP BY FacturaID
), SaldoPorFactura AS
(
    SELECT
        o.ClienteID,
        f.FacturaID,
        f.FechaFactura,
        f.Total - COALESCE(p.PagadoAlCorte, 0) AS SaldoAlCorte
    FROM dbo.Factura AS f
    INNER JOIN dbo.OrdenServicio AS o ON o.OrdenID = f.OrdenID
    LEFT JOIN PagosPorFactura AS p ON p.FacturaID = f.FacturaID
    WHERE f.EstadoFactura = N'Emitida'
      AND f.FechaFactura < @FinCorte
)
SELECT
    @FechaCorte AS FechaCorte,
    c.ClienteID,
    c.RazonSocial,
    COUNT_BIG(*) AS FacturasConSaldo,
    SUM(s.SaldoAlCorte) AS SaldoTotal,
    SUM(CASE WHEN DATEDIFF(DAY, s.FechaFactura, @FechaCorte) <= 30
        THEN s.SaldoAlCorte ELSE 0 END) AS SaldoAntiguedad0a30Dias,
    SUM(CASE WHEN DATEDIFF(DAY, s.FechaFactura, @FechaCorte) BETWEEN 31 AND 90
        THEN s.SaldoAlCorte ELSE 0 END) AS SaldoAntiguedad31a90Dias,
    SUM(CASE WHEN DATEDIFF(DAY, s.FechaFactura, @FechaCorte) > 90
        THEN s.SaldoAlCorte ELSE 0 END) AS SaldoAntiguedadMayor90Dias
FROM SaldoPorFactura AS s
INNER JOIN dbo.Cliente AS c ON c.ClienteID = s.ClienteID
WHERE s.SaldoAlCorte > 0
GROUP BY c.ClienteID, c.RazonSocial
ORDER BY SaldoTotal DESC, c.ClienteID;

/*
    7. COBROS POR MES Y METODO DE PAGO
    Grano de origen: un pago. Una factura puede tener varios pagos.
    La fecha corresponde al movimiento de efectivo, no a la venta.
*/
SELECT
    DATEFROMPARTS(YEAR(p.FechaPago), MONTH(p.FechaPago), 1) AS MesCobro,
    p.MetodoPago,
    COUNT_BIG(*) AS CantidadPagos,
    COUNT(DISTINCT p.FacturaID) AS FacturasConPago,
    SUM(p.MontoPagado) AS MontoCobrado
FROM dbo.Pago AS p
INNER JOIN dbo.Factura AS f ON f.FacturaID = p.FacturaID
WHERE f.EstadoFactura = N'Emitida'
GROUP BY DATEFROMPARTS(YEAR(p.FechaPago), MONTH(p.FechaPago), 1), p.MetodoPago
ORDER BY MesCobro, p.MetodoPago;

/*
    8. COLA OPERATIVA AL CIERRE DEL ESCENARIO
    Estado es el estado actual; esta consulta no reconstruye estados pasados.
    Con los parametros predeterminados: 800 pendientes y 200 en proceso.
*/
SELECT
    o.Estado,
    o.Prioridad,
    COUNT_BIG(*) AS Ordenes,
    COUNT(DISTINCT o.VehiculoID) AS Vehiculos,
    COUNT(DISTINCT o.TecnicoID) AS TecnicosAsignados,
    MIN(o.FechaIngreso) AS IngresoMasAntiguo,
    MAX(o.FechaIngreso) AS IngresoMasReciente
FROM dbo.OrdenServicio AS o
WHERE o.Estado IN (N'Pendiente', N'En proceso')
GROUP BY o.Estado, o.Prioridad
ORDER BY o.Estado, CASE o.Prioridad WHEN N'Alta' THEN 1 WHEN N'Media' THEN 2 ELSE 3 END;

/*
    9. EJEMPLO DE LINAJE ETL: HECHO DE DETALLE DE SERVICIO
    Grano: exactamente una fila fuente por DetalleID.
    Los ID de origen son claves de negocio para buscar claves sustitutas
    en las dimensiones del DW; no son por si mismos claves sustitutas DW.
    OrdenID es una dimension degenerada que permite rastrear la orden.
    FechaIngreso y FechaSalida seran roles distintos de DimFecha.
    No se incluye TotalFactura: repetirlo por detalle duplicaria las ventas.
    TOP (100) es solo una muestra; retirarlo en una extraccion completa.
*/
SELECT TOP (100)
    d.DetalleID AS DetalleIDOrigen,
    o.OrdenID AS OrdenIDOrigen,
    o.ClienteID AS ClienteIDOrigen,
    o.VehiculoID AS VehiculoIDOrigen,
    v.ModeloID AS ModeloIDOrigen,
    mv.MarcaID AS MarcaIDOrigen,
    o.TecnicoID AS TecnicoIDOrigen,
    d.ServicioID AS ServicioIDOrigen,
    o.FechaIngreso,
    o.FechaSalida,
    o.Estado AS EstadoOrden,
    o.Prioridad,
    d.Cantidad,
    d.HorasTrabajo,
    d.CostoManoObra AS ImporteManoObraCobrado,
    CAST(d.HorasTrabajo * CAST(65.00 AS decimal(10,2)) AS decimal(18,2))
        AS CostoManoObraInternoEstimado
FROM dbo.DetalleServicio AS d
INNER JOIN dbo.OrdenServicio AS o ON o.OrdenID = d.OrdenID
INNER JOIN dbo.Vehiculo AS v ON v.VehiculoID = o.VehiculoID
INNER JOIN dbo.ModeloVehiculo AS mv ON mv.ModeloID = v.ModeloID
ORDER BY d.DetalleID;

/*
    10. EJEMPLO DE LINAJE ETL: HECHO DE CONSUMO DE REPUESTOS
    Grano: exactamente una fila fuente por ConsumoID.
    Es un hecho separado del detalle de servicio: ambos comparten la orden,
    pero el modelo no vincula un consumo con un detalle de servicio concreto.
    ConsumoRepuesto no contiene FechaConsumo. Se conserva FechaIngresoOrden
    como contexto; no se afirma que sea la fecha real del consumo.
    Para analisis diario de movimientos se debe incorporar FechaConsumo al
    OLTP. Una fecha de consumo inferida debe identificarse como estimacion.
*/
SELECT TOP (100)
    cr.ConsumoID AS ConsumoIDOrigen,
    cr.OrdenID AS OrdenIDOrigen,
    cr.RepuestoID AS RepuestoIDOrigen,
    o.ClienteID AS ClienteIDOrigen,
    o.VehiculoID AS VehiculoIDOrigen,
    o.TecnicoID AS TecnicoIDOrigen,
    o.FechaIngreso AS FechaIngresoOrden,
    o.FechaSalida AS FechaSalidaOrden,
    o.Estado AS EstadoOrden,
    cr.Cantidad AS UnidadesConsumidas,
    cr.Costo AS CostoTotalConsumido
FROM dbo.ConsumoRepuesto AS cr
INNER JOIN dbo.OrdenServicio AS o ON o.OrdenID = cr.OrdenID
ORDER BY cr.ConsumoID;
