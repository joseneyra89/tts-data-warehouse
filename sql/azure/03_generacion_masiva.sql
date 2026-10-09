/* TRUCK TOP SERVICE S.A.C. | Azure 03 - Generación masiva
   Azure SQL Database. Ejecutar después de 01 y 02 en TTS_OLTP.
   Corte simulado: 31/12/2026; contiene datos futuros respecto al desarrollo.
   WHILE controla lotes de 10000; INSERT...SELECT evita un bucle por fila.
   RAND(CHECKSUM(NEWID())) se materializa en temporales: azar distinto por fila.
   Una transacción preserva atomicidad; los lotes NO liberan el log hasta COMMIT.
   La ejecución no es determinista. Se conservan los conteos y las reglas.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N'TTS_OLTP'
BEGIN
    SET NOEXEC ON;
    THROW 51004, N'Contexto incorrecto; se requiere TTS_OLTP.', 1;
END;
IF (SELECT COUNT(*) FROM dbo.Servicio) <> 50
   OR (SELECT COUNT(*) FROM dbo.Repuesto) <> 500
   OR (SELECT COUNT(*) FROM dbo.ModeloVehiculo) <> 25
   OR (SELECT COUNT(*) FROM dbo.Especialidad) <> 6
   OR (SELECT COUNT(*) FROM dbo.Proveedor) <> 100
BEGIN
    SET NOEXEC ON;
    THROW 51005, N'Ejecute primero 02_datos_maestros.sql.', 1;
END;
IF EXISTS(SELECT 1 FROM dbo.Cliente) OR EXISTS(SELECT 1 FROM dbo.Vehiculo)
   OR EXISTS(SELECT 1 FROM dbo.Tecnico) OR EXISTS(SELECT 1 FROM dbo.OrdenServicio)
   OR EXISTS(SELECT 1 FROM dbo.DetalleServicio) OR EXISTS(SELECT 1 FROM dbo.ConsumoRepuesto)
   OR EXISTS(SELECT 1 FROM dbo.Factura) OR EXISTS(SELECT 1 FROM dbo.Pago)
   OR EXISTS(SELECT 1 FROM dbo.CompraRepuesto) OR EXISTS(SELECT 1 FROM dbo.DetalleCompraRepuesto)
BEGIN
    SET NOEXEC ON;
    THROW 51006, N'La carga requiere tablas operativas vacías. No se borra información.', 1;
END;

DROP TABLE IF EXISTS #N;
DROP TABLE IF EXISTS #ClienteBase;
DROP TABLE IF EXISTS #TecnicoBase;
DROP TABLE IF EXISTS #OrdenBase;
DROP TABLE IF EXISTS #ServicioPool;
DROP TABLE IF EXISTS #RepuestoPool;
DROP TABLE IF EXISTS #Linea;
DROP TABLE IF EXISTS #ConsumoMes;
DROP TABLE IF EXISTS #FacturaBase;
DROP TABLE IF EXISTS #PagoBase;

CREATE TABLE #N (n INT NOT NULL PRIMARY KEY);
;WITH D(n) AS (SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) x(n))
INSERT #N(n)
SELECT TOP (200000) CONVERT(INT, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)))
FROM D a CROSS JOIN D b CROSS JOIN D c CROSS JOIN D d CROSS JOIN D e CROSS JOIN D f;

DECLARE @Desde DATE = '20240101', @Corte DATETIME2(0) = '2026-12-31T23:59:59';
DECLARE @Inicio INT, @Lote INT = 10000;

BEGIN TRY
    BEGIN TRANSACTION;

    /* 5000 empresas inventadas. Los RUC tienen formato y dígito verificador;
       NO se consultan registros reales ni se afirma validez/inscripción fiscal.
       Todas son cartera inicial al 01/01/2024 para no tener órdenes anteriores.
    */
    SELECT n,
        CASE (n-1)%4 WHEN 0 THEN N'Transporte' WHEN 1 THEN N'Minería'
             WHEN 2 THEN N'Construcción' ELSE N'Logística' END AS Tipo,
        CASE (n-1)%10 WHEN 0 THEN N'Lima' WHEN 1 THEN N'Arequipa' WHEN 2 THEN N'Trujillo'
             WHEN 3 THEN N'Cusco' WHEN 4 THEN N'Piura' WHEN 5 THEN N'Chiclayo'
             WHEN 6 THEN N'Huancayo' WHEN 7 THEN N'Cajamarca' WHEN 8 THEN N'Ica' ELSE N'Tacna' END AS Ciudad,
        '209' + RIGHT('0000000'+CONVERT(VARCHAR(7),n),7) AS RucBase
    INTO #ClienteBase FROM #N WHERE n<=5000;

    SET IDENTITY_INSERT dbo.Cliente ON;
    INSERT dbo.Cliente(ClienteID,RUC,RazonSocial,Telefono,Direccion,Ciudad,TipoCliente,FechaRegistro,Estado)
    SELECT c.n, c.RucBase + CONVERT(VARCHAR(1),
           CASE 11-v.Suma%11 WHEN 10 THEN 0 WHEN 11 THEN 1 ELSE 11-v.Suma%11 END),
        CONCAT(CASE c.Tipo WHEN N'Transporte' THEN N'Transportes ' WHEN N'Minería' THEN N'Minera '
               WHEN N'Construcción' THEN N'Constructora ' ELSE N'Operador Logístico ' END,
               CASE (c.n/4)%10 WHEN 0 THEN N'Andes' WHEN 1 THEN N'Pacífico' WHEN 2 THEN N'Ruta Sur'
               WHEN 3 THEN N'Cordillera' WHEN 4 THEN N'Valle Alto' WHEN 5 THEN N'Nuevo Horizonte'
               WHEN 6 THEN N'Costa Azul' WHEN 7 THEN N'Camino Real' WHEN 8 THEN N'Sierra Norte' ELSE N'Altiplano' END,
               N' Simulada ',RIGHT('0000'+CONVERT(VARCHAR(4),c.n),4),N' S.A.C.'),
        '900'+RIGHT('000000'+CONVERT(VARCHAR(6),c.n),6),
        CONCAT(N'Av. Industrial Simulada ',100+c.n%2400,N', zona ',1+c.n%12),
        c.Ciudad,c.Tipo,@Desde,N'Activo'
    FROM #ClienteBase c
    -- Suma escalar: evita el error 8124 de SUM con referencias externas
    -- mezcladas con columnas locales. Conserva los diez pesos del algoritmo.
    CROSS APPLY (VALUES (
        CONVERT(INT,SUBSTRING(c.RucBase, 1,1))*5
      + CONVERT(INT,SUBSTRING(c.RucBase, 2,1))*4
      + CONVERT(INT,SUBSTRING(c.RucBase, 3,1))*3
      + CONVERT(INT,SUBSTRING(c.RucBase, 4,1))*2
      + CONVERT(INT,SUBSTRING(c.RucBase, 5,1))*7
      + CONVERT(INT,SUBSTRING(c.RucBase, 6,1))*6
      + CONVERT(INT,SUBSTRING(c.RucBase, 7,1))*5
      + CONVERT(INT,SUBSTRING(c.RucBase, 8,1))*4
      + CONVERT(INT,SUBSTRING(c.RucBase, 9,1))*3
      + CONVERT(INT,SUBSTRING(c.RucBase,10,1))*2
    )) v(Suma);
    SET IDENTITY_INSERT dbo.Cliente OFF;

    /* Flotas heterogéneas: 500 clientes con 12 vehículos y 4500 con 2.
       Caterpillar corresponde a camión minero; el modelo determina el tipo.
       Placas sintéticas y únicas: TAA-001 ...; ningún dato identifica vehículos reales.
    */
    SET IDENTITY_INSERT dbo.Vehiculo ON;
    INSERT dbo.Vehiculo(VehiculoID,ClienteID,ModeloID,Placa,[Año],KilometrajeActual,TipoVehiculo)
    SELECT n,CASE WHEN n<=6000 THEN 1+(n-1)/12 ELSE 501+(n-6001)/2 END,
        1+(n-1)%25,
        'T'+CHAR(65+((n-1)/1000)/26)+CHAR(65+((n-1)/1000)%26)+'-'+RIGHT('000'+CONVERT(VARCHAR(3),(n-1)%1000),3),
        2014+(n-1)%10,
        80000+(2026-(2014+(n-1)%10))*CONVERT(INT,35000+RAND(CHECKSUM(NEWID()))*25000),
        CASE WHEN 1+(n-1)%25>=21 THEN N'Camión minero'
             WHEN (1+(n-1)%25)%5 IN (1,2,3) THEN N'Tracto camión' ELSE N'Camión pesado' END
    FROM #N WHERE n<=15000;
    SET IDENTITY_INSERT dbo.Vehiculo OFF;

    SELECT n,
       CASE (n-1)%20 WHEN 0 THEN N'José' WHEN 1 THEN N'Luis' WHEN 2 THEN N'Carlos' WHEN 3 THEN N'Miguel'
       WHEN 4 THEN N'Ana' WHEN 5 THEN N'Jorge' WHEN 6 THEN N'María' WHEN 7 THEN N'Pedro'
       WHEN 8 THEN N'Rosa' WHEN 9 THEN N'Daniel' WHEN 10 THEN N'Elena' WHEN 11 THEN N'Víctor'
       WHEN 12 THEN N'Raúl' WHEN 13 THEN N'Carmen' WHEN 14 THEN N'Marco' WHEN 15 THEN N'Lucía'
       WHEN 16 THEN N'Julio' WHEN 17 THEN N'Patricia' WHEN 18 THEN N'Fernando' ELSE N'Diana' END AS Nombre,
       CASE (n-1)/20 WHEN 0 THEN N'Quispe' WHEN 1 THEN N'Flores' WHEN 2 THEN N'García' WHEN 3 THEN N'Rojas'
       WHEN 4 THEN N'Huamán' WHEN 5 THEN N'Vargas' WHEN 6 THEN N'Mendoza' WHEN 7 THEN N'Castillo'
       WHEN 8 THEN N'Salazar' ELSE N'Torres' END AS Apellido
    INTO #TecnicoBase FROM #N WHERE n<=200;
    SET IDENTITY_INSERT dbo.Tecnico ON;
    INSERT dbo.Tecnico(TecnicoID,Nombre,Apellido,EspecialidadID,FechaIngreso,Estado)
    SELECT n,Nombre,Apellido,1+(n-1)%6,@Desde,N'Activo' FROM #TecnicoBase;
    SET IDENTITY_INSERT dbo.Tecnico OFF;

    /* Visitas por vehículo separadas ~78 días (13/14 visitas en 3 años).
       El multiplicador 7919 es coprimo con 15000: cada ciclo visita la flota
       una sola vez. La fase distribuye las visitas; no solapa las estancias.
       Los últimos 1000 vehículos tienen su última orden abierta al cierre.
    */
    CREATE TABLE #OrdenBase
    (OrdenID INT PRIMARY KEY, VehiculoID INT NOT NULL, FechaIngreso DATETIME2(0) NOT NULL,
     DiasEstancia INT NOT NULL, Azar FLOAT NOT NULL);
    INSERT #OrdenBase
    SELECT n,1+((CONVERT(BIGINT,n)-1)*7919)%15000,
       DATEADD(HOUR,8+(n-1)%9,CONVERT(DATETIME2(0),
         CASE WHEN n>199800 THEN CONVERT(DATE,'20261231')
              WHEN n>199000 THEN DATEADD(DAY,(n-199001)%30,CONVERT(DATE,'20261201'))
              ELSE DATEADD(DAY,((n-1)/15000)*78
                    + CONVERT(INT,(((CONVERT(BIGINT,n)-1)*7919)%15000)*73/15000)
                    + CONVERT(INT,RAND(CHECKSUM(NEWID()))*3),@Desde) END)),
       1+CONVERT(INT,RAND(CHECKSUM(NEWID()))*3),RAND(CHECKSUM(NEWID()))
    FROM #N;

    SET IDENTITY_INSERT dbo.OrdenServicio ON;
    SET @Inicio=1;
    WHILE @Inicio<=200000
    BEGIN
        INSERT dbo.OrdenServicio(OrdenID,ClienteID,VehiculoID,TecnicoID,FechaIngreso,FechaSalida,Estado,Prioridad,Observacion)
        SELECT b.OrdenID,v.ClienteID,b.VehiculoID,1+(b.OrdenID-1)%200,b.FechaIngreso,
            CASE WHEN b.OrdenID<=198000 THEN DATEADD(DAY,b.DiasEstancia,b.FechaIngreso)
                 WHEN b.OrdenID<=199000 THEN DATEADD(HOUR,2,b.FechaIngreso) ELSE NULL END,
            CASE WHEN b.OrdenID<=198000 THEN N'Finalizado' WHEN b.OrdenID<=199000 THEN N'Cancelado'
                 WHEN b.OrdenID<=199800 THEN N'Pendiente' ELSE N'En proceso' END,
            CASE WHEN b.Azar<0.20 THEN N'Alta' WHEN b.Azar<0.75 THEN N'Media' ELSE N'Baja' END,
            CASE WHEN b.OrdenID<=198000 THEN N'Intervención realizada; inspección y prueba de funcionamiento conformes.'
                 WHEN b.OrdenID<=199000 THEN N'Cita cancelada por el cliente antes de ejecutar trabajos; sin cargos.'
                 WHEN b.OrdenID<=199800 THEN N'Solicitud registrada; pendiente de cita y autorización del cliente.'
                 ELSE N'Vehículo en taller; trabajos iniciados al cierre simulado del 31/12/2026.' END
        FROM #OrdenBase b JOIN dbo.Vehiculo v ON v.VehiculoID=b.VehiculoID
        WHERE b.OrdenID>=@Inicio AND b.OrdenID<@Inicio+@Lote;
        SET @Inicio+=@Lote;
    END;
    SET IDENTITY_INSERT dbo.OrdenServicio OFF;
    RAISERROR(N'Clientes, flota, técnicos y 200000 órdenes generados.',0,1) WITH NOWAIT;

    /* Dos servicios distintos de la especialidad del técnico por orden activa.
       HorasTrabajo es TOTAL de la línea, no horas por unidad.
       CostoManoObra es el importe COBRADO, no el costo interno del empleador.
       PrecioBase representa tarifa por hora en este conjunto de datos.
    */
    SELECT ServicioID,Categoria,ROW_NUMBER() OVER(PARTITION BY Categoria ORDER BY ServicioID) AS Pos,
       COUNT(*) OVER(PARTITION BY Categoria) AS CantidadServicios
    INTO #ServicioPool FROM dbo.Servicio;
    SELECT RepuestoID,Categoria,ROW_NUMBER() OVER(PARTITION BY Categoria ORDER BY RepuestoID) AS Pos,
       COUNT(*) OVER(PARTITION BY Categoria) AS CantidadRepuestos
    INTO #RepuestoPool FROM dbo.Repuesto;
    IF EXISTS(SELECT 1 FROM dbo.Especialidad e
      WHERE (SELECT COUNT(*) FROM #ServicioPool p WHERE p.Categoria=e.Nombre)<2
         OR (SELECT COUNT(*) FROM #RepuestoPool p WHERE p.Categoria=e.Nombre)<2)
        THROW 51007,N'Cada especialidad requiere al menos dos servicios y repuestos compatibles por categoría.',1;

    CREATE TABLE #Linea
    (OrdenID INT NOT NULL PRIMARY KEY, Categoria NVARCHAR(60) NOT NULL, Semilla INT NOT NULL,
     Unidades SMALLINT NOT NULL, HorasUnidad DECIMAL(6,2) NOT NULL, CantidadRepuesto INT NOT NULL);
    SET @Inicio=1;
    WHILE @Inicio<=200000
    BEGIN
        TRUNCATE TABLE #Linea;
        INSERT #Linea
        SELECT o.OrdenID,e.Nombre,CONVERT(INT,RAND(CHECKSUM(NEWID()))*1000000),
            CASE WHEN RAND(CHECKSUM(NEWID()))<0.10 THEN 2 ELSE 1 END,
            CONVERT(DECIMAL(6,2),0.50+CONVERT(INT,RAND(CHECKSUM(NEWID()))*5)*0.25),
            1+CONVERT(INT,RAND(CHECKSUM(NEWID()))*3)
        FROM dbo.OrdenServicio o JOIN dbo.Tecnico t ON t.TecnicoID=o.TecnicoID
        JOIN dbo.Especialidad e ON e.EspecialidadID=t.EspecialidadID
        WHERE o.OrdenID>=@Inicio AND o.OrdenID<@Inicio+@Lote AND o.Estado IN(N'Finalizado',N'En proceso');

        INSERT dbo.DetalleServicio(OrdenID,ServicioID,Cantidad,HorasTrabajo,CostoManoObra)
        SELECT l.OrdenID,p.ServicioID,l.Unidades,l.HorasUnidad*l.Unidades,
            ROUND(l.HorasUnidad*l.Unidades*s.PrecioBase,2)
        FROM #Linea l CROSS JOIN (VALUES(0),(1)) k(n)
        JOIN #ServicioPool p ON p.Categoria=l.Categoria AND p.Pos=1+(l.Semilla+k.n)%p.CantidadServicios
        JOIN dbo.Servicio s ON s.ServicioID=p.ServicioID;

        /* 1 consumo en órdenes impares, 2 en pares: 297300 líneas en total.
           Costo guarda el costo TOTAL histórico de adquisición de la línea.
           Venta simulada de repuestos = ROUND(SUM(Costo) * 1.30, 2) por orden.
        */
        INSERT dbo.ConsumoRepuesto(OrdenID,RepuestoID,Cantidad,Costo)
        SELECT l.OrdenID,p.RepuestoID,l.CantidadRepuesto,l.CantidadRepuesto*r.CostoUnitario
        FROM #Linea l CROSS JOIN (VALUES(0),(1)) k(n)
        JOIN #RepuestoPool p ON p.Categoria=l.Categoria AND p.Pos=1+(l.Semilla+k.n)%p.CantidadRepuestos
        JOIN dbo.Repuesto r ON r.RepuestoID=p.RepuestoID
        WHERE k.n=0 OR l.OrdenID%2=0;
        SET @Inicio+=@Lote;
    END;
    RAISERROR(N'396400 detalles y 297300 consumos generados.',0,1) WITH NOWAIT;

    /* Compras: 100 proveedores x 36 meses = 3600 cabeceras y 18000 líneas.
       Un proveedor abastece 5 SKU. Se compra el día 1 lo previsto para el mes.
       Saldo inicial 0; enero añade 25..50 unidades de seguridad por SKU;
       los otros meses añaden 1. El stock permanece no negativo cada día.
       No se modelan devoluciones, flete, crédito fiscal ni variación de costos.
    */
    SELECT DATEFROMPARTS(YEAR(o.FechaIngreso),MONTH(o.FechaIngreso),1) AS Mes,
           c.RepuestoID,SUM(c.Cantidad) AS Cantidad
    INTO #ConsumoMes FROM dbo.ConsumoRepuesto c
    JOIN dbo.OrdenServicio o ON o.OrdenID=c.OrdenID
    GROUP BY DATEFROMPARTS(YEAR(o.FechaIngreso),MONTH(o.FechaIngreso),1),c.RepuestoID;
    CREATE UNIQUE CLUSTERED INDEX IX_ConsumoMes ON #ConsumoMes(Mes,RepuestoID);

    SET IDENTITY_INSERT dbo.CompraRepuesto ON;
    INSERT dbo.CompraRepuesto(CompraID,ProveedorID,FechaCompra,MontoTotal)
    SELECT (m.n-1)*100+p.ProveedorID,p.ProveedorID,DATEADD(MONTH,m.n-1,@Desde),1.00
    FROM #N m CROSS JOIN dbo.Proveedor p WHERE m.n<=36;
    SET IDENTITY_INSERT dbo.CompraRepuesto OFF;
    INSERT dbo.DetalleCompraRepuesto(CompraID,RepuestoID,Cantidad,CostoUnitario,Importe)
    SELECT c.CompraID,r.RepuestoID,q.Cantidad,r.CostoUnitario,q.Cantidad*r.CostoUnitario
    FROM dbo.CompraRepuesto c
    JOIN dbo.Repuesto r ON 1+(r.RepuestoID-1)%100=c.ProveedorID
    LEFT JOIN #ConsumoMes cm ON cm.Mes=c.FechaCompra AND cm.RepuestoID=r.RepuestoID
    CROSS APPLY(VALUES(COALESCE(cm.Cantidad,0)+CASE WHEN c.FechaCompra=@Desde THEN 25+r.RepuestoID%26 ELSE 1 END)) q(Cantidad);
    ;WITH Compra AS (SELECT CompraID,SUM(Importe) AS Monto FROM dbo.DetalleCompraRepuesto GROUP BY CompraID)
    UPDATE c SET MontoTotal=d.Monto FROM dbo.CompraRepuesto c JOIN Compra d ON d.CompraID=c.CompraID;
    ;WITH Entradas AS (SELECT RepuestoID,SUM(Cantidad) AS Cantidad FROM dbo.DetalleCompraRepuesto GROUP BY RepuestoID),
    Salidas AS (SELECT RepuestoID,SUM(Cantidad) AS Cantidad FROM dbo.ConsumoRepuesto GROUP BY RepuestoID)
    UPDATE r SET StockActual=e.Cantidad-COALESCE(s.Cantidad,0)
    FROM dbo.Repuesto r JOIN Entradas e ON e.RepuestoID=r.RepuestoID
    LEFT JOIN Salidas s ON s.RepuestoID=r.RepuestoID;

    /* Factura: 1 documento por orden; sólo finalizadas generan Emitida.
       Borrador/Anulada: sin fecha fiscal, importes cero y sin pagos.
       Es una adaptación académica, no un sistema de comprobantes fiscales.
       IGV 18% es un parámetro fijo del escenario; montos expresados en PEN.
       Las agregaciones separadas evitan multiplicar detalles por repuestos.
    */
    ;WITH ManoObra AS (SELECT OrdenID,SUM(CostoManoObra) AS Importe FROM dbo.DetalleServicio GROUP BY OrdenID),
    Material AS (SELECT OrdenID,SUM(Costo) AS Importe FROM dbo.ConsumoRepuesto GROUP BY OrdenID)
    SELECT o.OrdenID,
       CONVERT(DECIMAL(14,2),CASE WHEN o.Estado=N'Finalizado' THEN m.Importe+ROUND(r.Importe*1.30,2) ELSE 0 END) AS Subtotal,
       CASE WHEN o.Estado=N'Finalizado' THEN 'Emitida' WHEN o.Estado=N'Cancelado' THEN 'Anulada' ELSE 'Borrador' END AS EstadoFactura,
       CASE WHEN o.Estado=N'Finalizado' THEN DATEADD(DAY,1,o.FechaSalida) ELSE NULL END AS FechaFactura,
       CASE WHEN o.Estado<>N'Finalizado' THEN 'No aplica'
            WHEN (o.OrdenID-1)%198 <194 THEN 'Pagado'
            WHEN (o.OrdenID-1)%198 =194 THEN 'Parcial' ELSE 'Pendiente' END AS EstadoPago
    INTO #FacturaBase FROM dbo.OrdenServicio o
    LEFT JOIN ManoObra m ON m.OrdenID=o.OrdenID LEFT JOIN Material r ON r.OrdenID=o.OrdenID;
    SET IDENTITY_INSERT dbo.Factura ON;
    INSERT dbo.Factura(FacturaID,OrdenID,FechaFactura,Subtotal,IGV,Total,EstadoPago,EstadoFactura)
    SELECT OrdenID,OrdenID,FechaFactura,Subtotal,ROUND(Subtotal*0.18,2),Subtotal+ROUND(Subtotal*0.18,2),EstadoPago,EstadoFactura
    FROM #FacturaBase;
    SET IDENTITY_INSERT dbo.Factura OFF;

    /* 198000 = 1000 grupos de 198 facturas; la pauta se distribuye en todo el período.
       En cada grupo: 190 de pago único, 4 con 2 pagos completos, 1 con 2 parciales,
       3 sin pago. Resultado: 200000 pagos positivos, sin exceder el total.
       El segundo pago completo se calcula por diferencia para no perder centavos.
    */
    SELECT f.FacturaID,f.Total,f.FechaFactura,(f.OrdenID-1)%198 AS Grupo,
       CONVERT(DECIMAL(14,2),ROUND(f.Total*0.60,2)) AS PrimerPagoCompleto,
       CONVERT(DECIMAL(14,2),ROUND(f.Total*0.20,2)) AS PrimerPagoParcial,
       CONVERT(DECIMAL(14,2),ROUND(f.Total*0.30,2)) AS SegundoPagoParcial
    INTO #PagoBase FROM dbo.Factura f WHERE f.EstadoFactura='Emitida' AND (f.OrdenID-1)%198<=194;
    INSERT dbo.Pago(FacturaID,FechaPago,MontoPagado,MetodoPago)
    SELECT f.FacturaID,
       CASE WHEN DATEADD(DAY,k.n,f.FechaFactura)>@Corte THEN @Corte ELSE DATEADD(DAY,k.n,f.FechaFactura) END,
       CASE WHEN f.Grupo<190 THEN f.Total WHEN f.Grupo<194 AND k.n=1 THEN f.PrimerPagoCompleto
            WHEN f.Grupo<194 THEN f.Total-f.PrimerPagoCompleto
            WHEN k.n=1 THEN f.PrimerPagoParcial ELSE f.SegundoPagoParcial END,
       CASE WHEN f.FacturaID%10<7 THEN N'Transferencia' WHEN f.FacturaID%10<9 THEN N'Tarjeta' ELSE N'Efectivo' END
    FROM #PagoBase f CROSS JOIN (VALUES(1),(2)) k(n) WHERE k.n=1 OR f.Grupo>=190;

    IF (SELECT COUNT(*) FROM dbo.OrdenServicio)<>200000
       OR (SELECT COUNT(*) FROM dbo.DetalleServicio)<>396400
       OR (SELECT COUNT(*) FROM dbo.ConsumoRepuesto)<>297300
       OR (SELECT COUNT(*) FROM dbo.Factura)<>200000
       OR (SELECT COUNT(*) FROM dbo.Pago)<>200000
        THROW 51008,N'Conteos inesperados; se revierte toda la carga operativa.',1;
    IF EXISTS(SELECT 1 FROM dbo.Pago WHERE FechaPago>@Corte)
       OR EXISTS(SELECT 1 FROM dbo.Factura WHERE FechaFactura>@Corte)
        THROW 51009,N'Fecha fuera del corte simulado; se revierte la carga.',1;

    COMMIT TRANSACTION;
    RAISERROR(N'Carga completa confirmada. Ejecutar 04_validacion.sql.',0,1) WITH NOWAIT;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    -- IDENTITY_INSERT es estado de sesión; se desactiva también ante un error.
    SET IDENTITY_INSERT dbo.Cliente OFF;
    SET IDENTITY_INSERT dbo.Vehiculo OFF;
    SET IDENTITY_INSERT dbo.Tecnico OFF;
    SET IDENTITY_INSERT dbo.OrdenServicio OFF;
    SET IDENTITY_INSERT dbo.CompraRepuesto OFF;
    SET IDENTITY_INSERT dbo.Factura OFF;
    THROW;
END CATCH;
GO
