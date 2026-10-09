/*
TRUCK TOP SERVICE S.A.C. | Azure 01 - Modelo relacional e integridad
Azure SQL Database. Conectarse directamente a TTS_OLTP antes de ejecutar.
Las PK IDENTITY son claves técnicas estables para dimensiones y hechos del DW.
Las FK se crean habilitadas y se mantienen activas durante toda la carga.
No hay eliminaciones en cascada ni restricciones que impidan fechas posteriores
a 2026: ese intervalo pertenece a los datos sintéticos, no al modelo operativo.
Se añade DetalleCompraRepuesto para relacionar compras, repuestos e inventario.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

IF DB_NAME() <> N'TTS_OLTP'
BEGIN
    PRINT N'DETENIDO: el contexto actual no es TTS_OLTP.';
    SET NOEXEC ON;
    ;THROW 51001, N'Contexto incorrecto: debe ejecutarse en TTS_OLTP.', 1;
END;
IF EXISTS (SELECT 1 FROM sys.tables WHERE schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    PRINT N'DETENIDO: la base ya contiene tablas dbo. No se modifica el modelo existente.';
    SET NOEXEC ON;
    ;THROW 51002, N'La base ya contiene tablas dbo. La creación se detiene sin modificar datos.', 1;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    CREATE TABLE dbo.Cliente
    (
        ClienteID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Cliente PRIMARY KEY,
        RUC VARCHAR(11) NOT NULL CONSTRAINT UQ_Cliente_RUC UNIQUE,
        RazonSocial VARCHAR(150) NOT NULL,
        Telefono VARCHAR(20) NOT NULL,
        Direccion NVARCHAR(200) NOT NULL,
        Ciudad NVARCHAR(80) NOT NULL,
        TipoCliente NVARCHAR(30) NOT NULL,
        FechaRegistro DATE NOT NULL,
        Estado NVARCHAR(12) NOT NULL,
        CONSTRAINT CK_Cliente_RUC CHECK (LEN(RUC) = 11 AND RUC NOT LIKE '%[^0-9]%'),
        CONSTRAINT CK_Cliente_Tipo CHECK (TipoCliente IN (N'Transporte',N'Minería',N'Construcción',N'Logística')),
        CONSTRAINT CK_Cliente_Estado CHECK (Estado IN (N'Activo',N'Inactivo'))
    );

    CREATE TABLE dbo.MarcaVehiculo
    (
        MarcaID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MarcaVehiculo PRIMARY KEY,
        NombreMarca NVARCHAR(60) NOT NULL CONSTRAINT UQ_MarcaVehiculo_Nombre UNIQUE
    );

    CREATE TABLE dbo.ModeloVehiculo
    (
        ModeloID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ModeloVehiculo PRIMARY KEY,
        MarcaID INT NOT NULL,
        NombreModelo NVARCHAR(80) NOT NULL,
        CONSTRAINT FK_ModeloVehiculo_Marca FOREIGN KEY (MarcaID) REFERENCES dbo.MarcaVehiculo(MarcaID),
        CONSTRAINT UQ_ModeloVehiculo_MarcaNombre UNIQUE (MarcaID,NombreModelo)
    );

    CREATE TABLE dbo.Vehiculo
    (
        VehiculoID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Vehiculo PRIMARY KEY,
        ClienteID INT NOT NULL,
        ModeloID INT NOT NULL,
        Placa VARCHAR(10) NOT NULL CONSTRAINT UQ_Vehiculo_Placa UNIQUE,
        [Año] SMALLINT NOT NULL,
        KilometrajeActual INT NOT NULL,
        TipoVehiculo NVARCHAR(30) NOT NULL,
        CONSTRAINT FK_Vehiculo_Cliente FOREIGN KEY (ClienteID) REFERENCES dbo.Cliente(ClienteID),
        CONSTRAINT FK_Vehiculo_Modelo FOREIGN KEY (ModeloID) REFERENCES dbo.ModeloVehiculo(ModeloID),
        -- Esta clave permite comprobar que cliente y vehículo de una orden coinciden.
        CONSTRAINT UQ_Vehiculo_VehiculoCliente UNIQUE (VehiculoID,ClienteID),
        CONSTRAINT CK_Vehiculo_Ano CHECK ([Año] BETWEEN 1980 AND 2100),
        CONSTRAINT CK_Vehiculo_Kilometraje CHECK (KilometrajeActual >= 0),
        CONSTRAINT CK_Vehiculo_Tipo CHECK (TipoVehiculo IN (N'Camión pesado',N'Tracto camión',N'Camión minero'))
    );

    CREATE TABLE dbo.Especialidad
    (
        EspecialidadID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Especialidad PRIMARY KEY,
        Nombre NVARCHAR(60) NOT NULL CONSTRAINT UQ_Especialidad_Nombre UNIQUE
    );

    CREATE TABLE dbo.Tecnico
    (
        TecnicoID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Tecnico PRIMARY KEY,
        Nombre NVARCHAR(80) NOT NULL,
        Apellido NVARCHAR(100) NOT NULL,
        EspecialidadID INT NOT NULL,
        FechaIngreso DATE NOT NULL,
        Estado NVARCHAR(12) NOT NULL,
        CONSTRAINT FK_Tecnico_Especialidad FOREIGN KEY (EspecialidadID) REFERENCES dbo.Especialidad(EspecialidadID),
        CONSTRAINT CK_Tecnico_Estado CHECK (Estado IN (N'Activo',N'Inactivo'))
    );

    CREATE TABLE dbo.Servicio
    (
        ServicioID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Servicio PRIMARY KEY,
        NombreServicio NVARCHAR(150) NOT NULL CONSTRAINT UQ_Servicio_Nombre UNIQUE,
        Categoria NVARCHAR(60) NOT NULL,
        -- Para este proyecto PrecioBase es la TARIFA DE VENTA POR HORA en soles.
        PrecioBase DECIMAL(10,2) NOT NULL,
        CONSTRAINT CK_Servicio_Categoria CHECK (Categoria IN (N'Preventivo',N'Correctivo',N'Diagnóstico',N'Motor',N'Transmisión',N'Sistema eléctrico')),
        CONSTRAINT CK_Servicio_Precio CHECK (PrecioBase > 0)
    );

    CREATE TABLE dbo.OrdenServicio
    (
        OrdenID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_OrdenServicio PRIMARY KEY,
        ClienteID INT NOT NULL,
        VehiculoID INT NOT NULL,
        TecnicoID INT NOT NULL,
        FechaIngreso DATETIME2(0) NOT NULL,
        FechaSalida DATETIME2(0) NULL,
        Estado NVARCHAR(15) NOT NULL,
        Prioridad NVARCHAR(5) NOT NULL,
        Observacion NVARCHAR(500) NULL,
        CONSTRAINT FK_OrdenServicio_Cliente FOREIGN KEY (ClienteID) REFERENCES dbo.Cliente(ClienteID),
        CONSTRAINT FK_OrdenServicio_VehiculoCliente FOREIGN KEY (VehiculoID,ClienteID) REFERENCES dbo.Vehiculo(VehiculoID,ClienteID),
        CONSTRAINT FK_OrdenServicio_Tecnico FOREIGN KEY (TecnicoID) REFERENCES dbo.Tecnico(TecnicoID),
        CONSTRAINT CK_OrdenServicio_Estado CHECK (Estado IN (N'Pendiente',N'En proceso',N'Finalizado',N'Cancelado')),
        CONSTRAINT CK_OrdenServicio_Prioridad CHECK (Prioridad IN (N'Alta',N'Media',N'Baja')),
        CONSTRAINT CK_OrdenServicio_Fechas CHECK (FechaSalida IS NULL OR FechaSalida >= FechaIngreso),
        CONSTRAINT CK_OrdenServicio_Cierre CHECK
        (
            (Estado = N'Finalizado' AND FechaSalida IS NOT NULL)
            OR (Estado IN (N'Pendiente',N'En proceso') AND FechaSalida IS NULL)
            OR Estado = N'Cancelado'
        )
    );

    CREATE TABLE dbo.DetalleServicio
    (
        DetalleID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DetalleServicio PRIMARY KEY,
        OrdenID INT NOT NULL,
        ServicioID INT NOT NULL,
        Cantidad SMALLINT NOT NULL,
        -- HorasTrabajo contiene TODAS las horas de la línea, incluida Cantidad.
        HorasTrabajo DECIMAL(6,2) NOT NULL,
        -- Importe de VENTA total histórico: HorasTrabajo * tarifa aplicada.
        -- Aunque el campo se llama CostoManoObra, no representa costo interno.
        CostoManoObra DECIMAL(12,2) NOT NULL,
        CONSTRAINT FK_DetalleServicio_Orden FOREIGN KEY (OrdenID) REFERENCES dbo.OrdenServicio(OrdenID),
        CONSTRAINT FK_DetalleServicio_Servicio FOREIGN KEY (ServicioID) REFERENCES dbo.Servicio(ServicioID),
        CONSTRAINT UQ_DetalleServicio_OrdenServicio UNIQUE (OrdenID,ServicioID),
        CONSTRAINT CK_DetalleServicio_Valores CHECK (Cantidad > 0 AND HorasTrabajo > 0 AND CostoManoObra > 0)
    );

    CREATE TABLE dbo.Repuesto
    (
        RepuestoID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Repuesto PRIMARY KEY,
        NombreRepuesto NVARCHAR(150) NOT NULL CONSTRAINT UQ_Repuesto_Nombre UNIQUE,
        Categoria NVARCHAR(60) NOT NULL,
        Marca NVARCHAR(60) NOT NULL,
        CostoUnitario DECIMAL(12,2) NOT NULL,
        StockActual INT NOT NULL,
        CONSTRAINT CK_Repuesto_Valores CHECK (CostoUnitario > 0 AND StockActual >= 0)
    );

    CREATE TABLE dbo.ConsumoRepuesto
    (
        ConsumoID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ConsumoRepuesto PRIMARY KEY,
        OrdenID INT NOT NULL,
        RepuestoID INT NOT NULL,
        Cantidad INT NOT NULL,
        -- Costo TOTAL histórico de la línea, no precio unitario de venta.
        Costo DECIMAL(12,2) NOT NULL,
        CONSTRAINT FK_ConsumoRepuesto_Orden FOREIGN KEY (OrdenID) REFERENCES dbo.OrdenServicio(OrdenID),
        CONSTRAINT FK_ConsumoRepuesto_Repuesto FOREIGN KEY (RepuestoID) REFERENCES dbo.Repuesto(RepuestoID),
        CONSTRAINT UQ_ConsumoRepuesto_OrdenRepuesto UNIQUE (OrdenID,RepuestoID),
        CONSTRAINT CK_ConsumoRepuesto_Valores CHECK (Cantidad > 0 AND Costo > 0)
    );

    CREATE TABLE dbo.Proveedor
    (
        ProveedorID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Proveedor PRIMARY KEY,
        RUC VARCHAR(11) NOT NULL CONSTRAINT UQ_Proveedor_RUC UNIQUE,
        NombreProveedor NVARCHAR(150) NOT NULL,
        Telefono VARCHAR(20) NOT NULL,
        CONSTRAINT CK_Proveedor_RUC CHECK (LEN(RUC) = 11 AND RUC NOT LIKE '%[^0-9]%')
    );

    CREATE TABLE dbo.CompraRepuesto
    (
        CompraID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CompraRepuesto PRIMARY KEY,
        ProveedorID INT NOT NULL,
        FechaCompra DATE NOT NULL,
        -- Total sin IGV, igual a la suma de importes de DetalleCompraRepuesto.
        MontoTotal DECIMAL(14,2) NOT NULL,
        CONSTRAINT FK_CompraRepuesto_Proveedor FOREIGN KEY (ProveedorID) REFERENCES dbo.Proveedor(ProveedorID),
        CONSTRAINT CK_CompraRepuesto_Monto CHECK (MontoTotal >= 0)
    );

    CREATE TABLE dbo.DetalleCompraRepuesto
    (
        DetalleCompraID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DetalleCompraRepuesto PRIMARY KEY,
        CompraID INT NOT NULL,
        RepuestoID INT NOT NULL,
        Cantidad INT NOT NULL,
        CostoUnitario DECIMAL(12,2) NOT NULL,
        Importe DECIMAL(14,2) NOT NULL,
        CONSTRAINT FK_DetalleCompraRepuesto_Compra FOREIGN KEY (CompraID) REFERENCES dbo.CompraRepuesto(CompraID),
        CONSTRAINT FK_DetalleCompraRepuesto_Repuesto FOREIGN KEY (RepuestoID) REFERENCES dbo.Repuesto(RepuestoID),
        CONSTRAINT UQ_DetalleCompraRepuesto_CompraRepuesto UNIQUE (CompraID,RepuestoID),
        CONSTRAINT CK_DetalleCompraRepuesto_Valores CHECK (Cantidad > 0 AND CostoUnitario > 0 AND Importe = ROUND(Cantidad * CostoUnitario,2))
    );

    CREATE TABLE dbo.Factura
    (
        FacturaID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Factura PRIMARY KEY,
        OrdenID INT NOT NULL CONSTRAINT UQ_Factura_Orden UNIQUE,
        FechaFactura DATETIME2(0) NULL,
        Subtotal DECIMAL(14,2) NOT NULL,
        IGV DECIMAL(14,2) NOT NULL,
        Total DECIMAL(14,2) NOT NULL,
        EstadoPago VARCHAR(12) NOT NULL,
        -- Permite representar una ficha de facturación sin emitir ingresos.
        EstadoFactura VARCHAR(12) NOT NULL,
        CONSTRAINT FK_Factura_Orden FOREIGN KEY (OrdenID) REFERENCES dbo.OrdenServicio(OrdenID),
        CONSTRAINT CK_Factura_EstadoFactura CHECK (EstadoFactura IN ('Emitida','Borrador','Anulada')),
        CONSTRAINT CK_Factura_EstadoPago CHECK (EstadoPago IN ('Pagado','Parcial','Pendiente','No aplica')),
        CONSTRAINT CK_Factura_Importes CHECK (Subtotal >= 0 AND IGV >= 0 AND Total = Subtotal + IGV),
        -- Supuesto académico: IGV del 18%, redondeado al centavo por factura.
        CONSTRAINT CK_Factura_IGV CHECK (IGV = ROUND(Subtotal * CAST(0.18 AS DECIMAL(3,2)),2)),
        CONSTRAINT CK_Factura_Emision CHECK
        (
            (EstadoFactura = 'Emitida' AND FechaFactura IS NOT NULL AND Subtotal > 0 AND EstadoPago IN ('Pagado','Parcial','Pendiente'))
            OR
            (EstadoFactura IN ('Borrador','Anulada') AND FechaFactura IS NULL AND Subtotal = 0 AND IGV = 0 AND Total = 0 AND EstadoPago = 'No aplica')
        )
    );

    CREATE TABLE dbo.Pago
    (
        PagoID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Pago PRIMARY KEY,
        FacturaID INT NOT NULL,
        FechaPago DATETIME2(0) NOT NULL,
        MontoPagado DECIMAL(14,2) NOT NULL,
        MetodoPago NVARCHAR(30) NOT NULL,
        CONSTRAINT FK_Pago_Factura FOREIGN KEY (FacturaID) REFERENCES dbo.Factura(FacturaID),
        CONSTRAINT CK_Pago_Monto CHECK (MontoPagado > 0),
        CONSTRAINT CK_Pago_Metodo CHECK (MetodoPago IN (N'Transferencia',N'Depósito',N'Efectivo',N'Tarjeta',N'Cheque'))
    );

    -- SQL Server no crea índices automáticamente para las FK. Los índices
    -- compuestos UNIQUE anteriores ya cubren las FK cuyo primer campo es OrdenID.
    CREATE INDEX IX_Vehiculo_Cliente ON dbo.Vehiculo(ClienteID);
    CREATE INDEX IX_Vehiculo_Modelo ON dbo.Vehiculo(ModeloID);
    CREATE INDEX IX_Tecnico_Especialidad ON dbo.Tecnico(EspecialidadID);
    CREATE INDEX IX_OrdenServicio_ClienteFecha ON dbo.OrdenServicio(ClienteID,FechaIngreso);
    CREATE INDEX IX_OrdenServicio_VehiculoCliente ON dbo.OrdenServicio(VehiculoID,ClienteID);
    CREATE INDEX IX_OrdenServicio_TecnicoFecha ON dbo.OrdenServicio(TecnicoID,FechaIngreso) INCLUDE (Estado,FechaSalida);
    CREATE INDEX IX_OrdenServicio_FechaIngreso ON dbo.OrdenServicio(FechaIngreso) INCLUDE (Estado);
    CREATE INDEX IX_DetalleServicio_Servicio ON dbo.DetalleServicio(ServicioID) INCLUDE (OrdenID,Cantidad,HorasTrabajo,CostoManoObra);
    CREATE INDEX IX_ConsumoRepuesto_Repuesto ON dbo.ConsumoRepuesto(RepuestoID) INCLUDE (OrdenID,Cantidad,Costo);
    CREATE INDEX IX_CompraRepuesto_ProveedorFecha ON dbo.CompraRepuesto(ProveedorID,FechaCompra);
    CREATE INDEX IX_DetalleCompraRepuesto_Repuesto ON dbo.DetalleCompraRepuesto(RepuestoID) INCLUDE (CompraID,Cantidad);
    CREATE INDEX IX_Factura_FechaFactura ON dbo.Factura(FechaFactura) INCLUDE (EstadoFactura,Subtotal,IGV,Total,EstadoPago);
    CREATE INDEX IX_Pago_FacturaFecha ON dbo.Pago(FacturaID,FechaPago) INCLUDE (MontoPagado);

    COMMIT TRANSACTION;
    PRINT N'Modelo creado: 15 tablas solicitadas y DetalleCompraRepuesto para trazabilidad del inventario.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT ERROR_MESSAGE();
    SET NOEXEC ON;
    ;THROW;
END CATCH;
GO
