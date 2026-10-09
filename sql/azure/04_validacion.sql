/* TRUCK TOP SERVICE S.A.C. | Azure 04 - Validación reproducible.
   Sólo lectura de tablas permanentes. Deben aparecer todos los conteos OK,
   cero errores de reglas y ninguna fila devuelta por DBCC CHECKCONSTRAINTS.
   Las reglas cruzadas validan esta muestra; para nuevas escrituras se necesita
   una capa transaccional de aplicación/procedimientos que también las aplique.
*/
SET NOCOUNT ON;
IF DB_NAME()<>N'TTS_OLTP'
BEGIN
    SET NOEXEC ON;
    THROW 51010,N'Contexto incorrecto de validación.',1;
END;
DROP TABLE IF EXISTS #Conteos;
DROP TABLE IF EXISTS #Reglas;
DROP TABLE IF EXISTS #TotalOrden;
DROP TABLE IF EXISTS #TotalPago;
CREATE TABLE #Conteos(Tabla SYSNAME PRIMARY KEY,Esperado BIGINT,Real BIGINT);
INSERT #Conteos VALUES
 (N'Cliente',5000,(SELECT COUNT_BIG(*) FROM dbo.Cliente)),
 (N'MarcaVehiculo',5,(SELECT COUNT_BIG(*) FROM dbo.MarcaVehiculo)),
 (N'ModeloVehiculo',25,(SELECT COUNT_BIG(*) FROM dbo.ModeloVehiculo)),
 (N'Vehiculo',15000,(SELECT COUNT_BIG(*) FROM dbo.Vehiculo)),
 (N'Especialidad',6,(SELECT COUNT_BIG(*) FROM dbo.Especialidad)),
 (N'Tecnico',200,(SELECT COUNT_BIG(*) FROM dbo.Tecnico)),
 (N'Servicio',50,(SELECT COUNT_BIG(*) FROM dbo.Servicio)),
 (N'OrdenServicio',200000,(SELECT COUNT_BIG(*) FROM dbo.OrdenServicio)),
 (N'DetalleServicio',396400,(SELECT COUNT_BIG(*) FROM dbo.DetalleServicio)),
 (N'Repuesto',500,(SELECT COUNT_BIG(*) FROM dbo.Repuesto)),
 (N'ConsumoRepuesto',297300,(SELECT COUNT_BIG(*) FROM dbo.ConsumoRepuesto)),
 (N'Proveedor',100,(SELECT COUNT_BIG(*) FROM dbo.Proveedor)),
 (N'CompraRepuesto',3600,(SELECT COUNT_BIG(*) FROM dbo.CompraRepuesto)),
 (N'DetalleCompraRepuesto',18000,(SELECT COUNT_BIG(*) FROM dbo.DetalleCompraRepuesto)),
 (N'Factura',200000,(SELECT COUNT_BIG(*) FROM dbo.Factura)),
 (N'Pago',200000,(SELECT COUNT_BIG(*) FROM dbo.Pago));
SELECT Tabla,Esperado,Real,CASE WHEN Esperado=Real THEN 'OK' ELSE 'ERROR' END AS Resultado
FROM #Conteos ORDER BY Tabla;

CREATE TABLE #Reglas(Regla NVARCHAR(180) PRIMARY KEY,Errores BIGINT NOT NULL);
-- FK y CHECK habilitadas y confiables: además se comprobarán todos los datos.
INSERT #Reglas SELECT N'FK habilitadas y confiables',COUNT_BIG(*) FROM sys.foreign_keys
WHERE is_disabled=1 OR is_not_trusted=1;
INSERT #Reglas SELECT N'CHECK habilitados y confiables',COUNT_BIG(*) FROM sys.check_constraints
WHERE is_disabled=1 OR is_not_trusted=1;
INSERT #Reglas SELECT N'Cliente de la orden coincide con titular del vehículo',COUNT_BIG(*)
FROM dbo.OrdenServicio o JOIN dbo.Vehiculo v ON v.VehiculoID=o.VehiculoID WHERE o.ClienteID<>v.ClienteID;
INSERT #Reglas SELECT N'Cliente y técnico registrados antes de su orden',COUNT_BIG(*)
FROM dbo.OrdenServicio o JOIN dbo.Cliente c ON c.ClienteID=o.ClienteID
JOIN dbo.Tecnico t ON t.TecnicoID=o.TecnicoID
WHERE o.FechaIngreso<c.FechaRegistro OR o.FechaIngreso<t.FechaIngreso;
INSERT #Reglas SELECT N'Servicios acordes con especialidad del técnico',COUNT_BIG(*)
FROM dbo.DetalleServicio d JOIN dbo.Servicio s ON s.ServicioID=d.ServicioID
JOIN dbo.OrdenServicio o ON o.OrdenID=d.OrdenID JOIN dbo.Tecnico t ON t.TecnicoID=o.TecnicoID
JOIN dbo.Especialidad e ON e.EspecialidadID=t.EspecialidadID WHERE s.Categoria<>e.Nombre;
INSERT #Reglas SELECT N'Repuestos acordes con categoría del trabajo',COUNT_BIG(*)
FROM dbo.ConsumoRepuesto c JOIN dbo.Repuesto r ON r.RepuestoID=c.RepuestoID
JOIN dbo.OrdenServicio o ON o.OrdenID=c.OrdenID JOIN dbo.Tecnico t ON t.TecnicoID=o.TecnicoID
JOIN dbo.Especialidad e ON e.EspecialidadID=t.EspecialidadID WHERE r.Categoria<>e.Nombre;

;WITH Fechas AS
(
 SELECT CONVERT(DATETIME2(0),FechaRegistro) Fecha FROM dbo.Cliente
 UNION ALL SELECT FechaIngreso FROM dbo.Tecnico
 UNION ALL SELECT FechaIngreso FROM dbo.OrdenServicio
 UNION ALL SELECT FechaSalida FROM dbo.OrdenServicio WHERE FechaSalida IS NOT NULL
 UNION ALL SELECT FechaCompra FROM dbo.CompraRepuesto
 UNION ALL SELECT FechaFactura FROM dbo.Factura WHERE FechaFactura IS NOT NULL
 UNION ALL SELECT FechaPago FROM dbo.Pago
)
INSERT #Reglas SELECT N'Fechas de eventos dentro de 2024-2026',COUNT_BIG(*) FROM Fechas
WHERE Fecha<'20240101' OR Fecha>='20270101';
INSERT #Reglas SELECT N'Orden cerrada antes de facturación; pago posterior a factura',COUNT_BIG(*)
FROM dbo.Factura f JOIN dbo.OrdenServicio o ON o.OrdenID=f.OrdenID
WHERE f.EstadoFactura='Emitida' AND (o.FechaSalida IS NULL OR f.FechaFactura<o.FechaSalida
 OR EXISTS(SELECT 1 FROM dbo.Pago p WHERE p.FacturaID=f.FacturaID AND p.FechaPago<f.FechaFactura));
;WITH Visitas AS
(
 SELECT VehiculoID,FechaIngreso,
     LAG(COALESCE(FechaSalida,CONVERT(DATETIME2(0),'20270101'))) OVER(PARTITION BY VehiculoID ORDER BY FechaIngreso,OrdenID) AS SalidaAnterior
 FROM dbo.OrdenServicio
)
INSERT #Reglas SELECT N'Sin visitas simultáneas del mismo vehículo',COUNT_BIG(*) FROM Visitas
WHERE FechaIngreso<SalidaAnterior;
INSERT #Reglas SELECT N'Abiertas únicamente en diciembre de 2026',COUNT_BIG(*)
FROM dbo.OrdenServicio WHERE Estado IN(N'Pendiente',N'En proceso') AND FechaIngreso<'20261201';

;WITH D AS(SELECT OrdenID,COUNT_BIG(*) Lineas,SUM(CostoManoObra) ManoObra FROM dbo.DetalleServicio GROUP BY OrdenID),
R AS(SELECT OrdenID,COUNT_BIG(*) Lineas,SUM(Costo) Costo FROM dbo.ConsumoRepuesto GROUP BY OrdenID)
SELECT o.OrdenID,COALESCE(d.Lineas,0) Detalles,COALESCE(r.Lineas,0) Consumos,
    COALESCE(d.ManoObra,0)+ROUND(COALESCE(r.Costo,0)*1.30,2) SubtotalCalculado
INTO #TotalOrden FROM dbo.OrdenServicio o LEFT JOIN D d ON d.OrdenID=o.OrdenID LEFT JOIN R r ON r.OrdenID=o.OrdenID;
CREATE UNIQUE CLUSTERED INDEX IX_TotalOrden ON #TotalOrden(OrdenID);
INSERT #Reglas SELECT N'Finalizadas/en proceso tienen dos servicios y uno o dos consumos',COUNT_BIG(*)
FROM dbo.OrdenServicio o JOIN #TotalOrden t ON t.OrdenID=o.OrdenID
WHERE o.Estado IN(N'Finalizado',N'En proceso') AND (t.Detalles<>2 OR t.Consumos<>1+CASE WHEN o.OrdenID%2=0 THEN 1 ELSE 0 END);
INSERT #Reglas SELECT N'Pendientes/canceladas sin trabajos ejecutados ni consumos',COUNT_BIG(*)
FROM dbo.OrdenServicio o JOIN #TotalOrden t ON t.OrdenID=o.OrdenID
WHERE o.Estado IN(N'Pendiente',N'Cancelado') AND (t.Detalles<>0 OR t.Consumos<>0);
INSERT #Reglas SELECT N'Importe mano de obra = horas totales por tarifa del escenario',COUNT_BIG(*)
FROM dbo.DetalleServicio d JOIN dbo.Servicio s ON s.ServicioID=d.ServicioID
WHERE d.CostoManoObra<>ROUND(d.HorasTrabajo*s.PrecioBase,2);
INSERT #Reglas SELECT N'Costo de consumo = cantidad por costo unitario del escenario',COUNT_BIG(*)
FROM dbo.ConsumoRepuesto c JOIN dbo.Repuesto r ON r.RepuestoID=c.RepuestoID WHERE c.Costo<>c.Cantidad*r.CostoUnitario;
INSERT #Reglas SELECT N'Una factura por cada orden',COUNT_BIG(*) FROM dbo.OrdenServicio o
WHERE (SELECT COUNT_BIG(*) FROM dbo.Factura f WHERE f.OrdenID=o.OrdenID)<>1;
INSERT #Reglas SELECT N'EstadoFactura coherente con estado de orden',COUNT_BIG(*)
FROM dbo.Factura f JOIN dbo.OrdenServicio o ON o.OrdenID=f.OrdenID
WHERE f.EstadoFactura<>CASE o.Estado WHEN N'Finalizado' THEN 'Emitida' WHEN N'Cancelado' THEN 'Anulada' ELSE 'Borrador' END;
INSERT #Reglas SELECT N'Subtotal emitido concilia con servicios y repuestos valorizados',COUNT_BIG(*)
FROM dbo.Factura f JOIN #TotalOrden t ON t.OrdenID=f.OrdenID
WHERE f.EstadoFactura='Emitida' AND f.Subtotal<>t.SubtotalCalculado;
INSERT #Reglas SELECT N'IGV y total concilian al centavo',COUNT_BIG(*) FROM dbo.Factura
WHERE IGV<>ROUND(Subtotal*0.18,2) OR Total<>Subtotal+IGV;

SELECT f.FacturaID,COALESCE(SUM(p.MontoPagado),0) Pagado,COUNT_BIG(p.PagoID) Pagos
INTO #TotalPago FROM dbo.Factura f LEFT JOIN dbo.Pago p ON p.FacturaID=f.FacturaID GROUP BY f.FacturaID;
CREATE UNIQUE CLUSTERED INDEX IX_TotalPago ON #TotalPago(FacturaID);
INSERT #Reglas SELECT N'Pago positivo y solamente a facturas emitidas',COUNT_BIG(*)
FROM dbo.Pago p JOIN dbo.Factura f ON f.FacturaID=p.FacturaID
WHERE p.MontoPagado<=0 OR f.EstadoFactura<>'Emitida';
INSERT #Reglas SELECT N'Estado de pago concilia con importes y saldo',COUNT_BIG(*)
FROM dbo.Factura f JOIN #TotalPago p ON p.FacturaID=f.FacturaID
WHERE p.Pagado>f.Total
 OR (f.EstadoPago='Pagado' AND p.Pagado<>f.Total)
 OR (f.EstadoPago='Parcial' AND NOT(p.Pagado>0 AND p.Pagado<f.Total))
 OR (f.EstadoPago IN('Pendiente','No aplica') AND p.Pagado<>0);
INSERT #Reglas SELECT N'Cantidad de cuotas esperada por factura del escenario',COUNT_BIG(*)
FROM dbo.Factura f JOIN #TotalPago p ON p.FacturaID=f.FacturaID
WHERE p.Pagos<>CASE WHEN f.EstadoFactura<>'Emitida' OR (f.OrdenID-1)%198>=195 THEN 0
                   WHEN (f.OrdenID-1)%198<190 THEN 1 ELSE 2 END;

;WITH D AS(SELECT CompraID,SUM(Importe) Total FROM dbo.DetalleCompraRepuesto GROUP BY CompraID)
INSERT #Reglas SELECT N'Total de compra concilia con sus líneas',COUNT_BIG(*)
FROM dbo.CompraRepuesto c LEFT JOIN D d ON d.CompraID=c.CompraID WHERE d.CompraID IS NULL OR c.MontoTotal<>d.Total;
;WITH E AS(SELECT RepuestoID,SUM(CONVERT(BIGINT,Cantidad)) Cantidad FROM dbo.DetalleCompraRepuesto GROUP BY RepuestoID),
S AS(SELECT RepuestoID,SUM(CONVERT(BIGINT,Cantidad)) Cantidad FROM dbo.ConsumoRepuesto GROUP BY RepuestoID)
INSERT #Reglas SELECT N'Stock actual = compras menos consumo; saldo inicial cero',COUNT_BIG(*)
FROM dbo.Repuesto r LEFT JOIN E e ON e.RepuestoID=r.RepuestoID LEFT JOIN S s ON s.RepuestoID=r.RepuestoID
WHERE r.StockActual<>COALESCE(e.Cantidad,0)-COALESCE(s.Cantidad,0) OR r.StockActual<0;
/* El modelo pedido no incluye FechaConsumo. En esta muestra el consumo ocurre
   al ingresar la orden; las compras DATE se reciben a las 00:00 del día 1.
   Esta convención permite comprobar el saldo después de cada instante registrado.
*/
;WITH Movimiento AS
(
 SELECT d.RepuestoID,CONVERT(DATETIME2(0),c.FechaCompra) Fecha,SUM(CONVERT(BIGINT,d.Cantidad)) Delta
 FROM dbo.DetalleCompraRepuesto d JOIN dbo.CompraRepuesto c ON c.CompraID=d.CompraID
 GROUP BY d.RepuestoID,c.FechaCompra
 UNION ALL
 SELECT c.RepuestoID,o.FechaIngreso,-SUM(CONVERT(BIGINT,c.Cantidad))
 FROM dbo.ConsumoRepuesto c JOIN dbo.OrdenServicio o ON o.OrdenID=c.OrdenID
 GROUP BY c.RepuestoID,o.FechaIngreso
), Diario AS
(
 SELECT RepuestoID,Fecha,SUM(Delta) Delta FROM Movimiento GROUP BY RepuestoID,Fecha
), Saldos AS
(
 SELECT RepuestoID,Fecha,SUM(Delta) OVER(PARTITION BY RepuestoID ORDER BY Fecha ROWS UNBOUNDED PRECEDING) Saldo FROM Diario
)
INSERT #Reglas SELECT N'Inventario sin saldo negativo en toda la cronología simulada',COUNT_BIG(*) FROM Saldos WHERE Saldo<0;

INSERT #Reglas SELECT N'Los 36 meses tienen órdenes finalizadas y facturación',
 CASE WHEN (SELECT COUNT(DISTINCT YEAR(FechaIngreso)*100+MONTH(FechaIngreso)) FROM dbo.OrdenServicio WHERE Estado=N'Finalizado')=36
       AND (SELECT COUNT(DISTINCT YEAR(FechaFactura)*100+MONTH(FechaFactura)) FROM dbo.Factura WHERE EstadoFactura='Emitida')=36
 THEN 0 ELSE 1 END;
INSERT #Reglas SELECT N'Distribución exacta de estados de orden',
 CASE WHEN (SELECT COUNT(*) FROM dbo.OrdenServicio WHERE Estado=N'Finalizado')=198000
       AND (SELECT COUNT(*) FROM dbo.OrdenServicio WHERE Estado=N'Cancelado')=1000
       AND (SELECT COUNT(*) FROM dbo.OrdenServicio WHERE Estado=N'Pendiente')=800
       AND (SELECT COUNT(*) FROM dbo.OrdenServicio WHERE Estado=N'En proceso')=200 THEN 0 ELSE 1 END;

SELECT Regla,Errores,CASE WHEN Errores=0 THEN 'OK' ELSE 'ERROR' END Resultado FROM #Reglas ORDER BY Regla;
-- Recorre todas las FK y CHECK; una tabla temporal captura las violaciones.
DROP TABLE IF EXISTS #Restricciones;
CREATE TABLE #Restricciones ([Table] NVARCHAR(776),[Constraint] NVARCHAR(776),[Where] NVARCHAR(MAX));
INSERT #Restricciones EXEC(N'DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS, ALL_ERRORMSGS, NO_INFOMSGS;');
SELECT * FROM #Restricciones;

SELECT Estado,COUNT_BIG(*) Ordenes,MIN(FechaIngreso) PrimerIngreso,MAX(FechaIngreso) UltimoIngreso
FROM dbo.OrdenServicio GROUP BY Estado ORDER BY Estado;
SELECT EstadoFactura,EstadoPago,COUNT_BIG(*) Documentos,SUM(Subtotal) Subtotal,SUM(Total) Total
FROM dbo.Factura GROUP BY EstadoFactura,EstadoPago ORDER BY EstadoFactura,EstadoPago;

IF EXISTS(SELECT 1 FROM #Conteos WHERE Esperado<>Real)
 OR EXISTS(SELECT 1 FROM #Reglas WHERE Errores<>0)
 OR EXISTS(SELECT 1 FROM #Restricciones)
    THROW 51011,N'Validación fallida: revisar resultados anteriores.',1;
PRINT N'VALIDACIÓN COMPLETA: conteos exactos, reglas sin errores y restricciones íntegras.';
GO
