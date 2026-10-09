/*
TRUCK TOP SERVICE S.A.C. | Azure 02 - Catálogos y maestros de baja cardinalidad
Azure SQL Database. Ejecutar después de 01_crear_tablas.sql.

Cantidades: 5 marcas, 25 modelos, 6 especialidades, 50 servicios,
100 proveedores y 500 repuestos (50 familias x 10 referencias sintéticas).
Cliente, Vehiculo y Tecnico se generan en 04_generacion_masiva.sql.

Todos los importes están expresados en soles (PEN). PrecioBase es tarifa/hora.
Los proveedores, RUC y referencias TTS son ficticios, sin verificación SUNAT.
Las marcas y modelos se usan como contexto académico; las referencias TTS no
afirman una compatibilidad mecánica validada contra catálogos de fabricantes.
StockActual comienza en cero y será conciliado con compras menos consumos.

IDENTITY_INSERT fija los ID de catálogos para que la generación masiva tenga
un contrato estable. Las tablas conservan IDENTITY para nuevas altas normales.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> N'TTS_OLTP'
BEGIN
    PRINT N'DETENIDO: el contexto actual no es TTS_OLTP.';
    SET NOEXEC ON;
    ;THROW 51003, N'Contexto incorrecto: debe ejecutarse en TTS_OLTP.', 1;
END;
IF OBJECT_ID(N'dbo.Repuesto', N'U') IS NULL OR OBJECT_ID(N'dbo.Servicio', N'U') IS NULL
BEGIN
    PRINT N'DETENIDO: ejecute antes 02_crear_tablas.sql.';
    SET NOEXEC ON;
    ;THROW 51004, N'Falta el modelo relacional. Ejecute 02_crear_tablas.sql.', 1;
END;
IF EXISTS (SELECT 1 FROM dbo.MarcaVehiculo)
   OR EXISTS (SELECT 1 FROM dbo.ModeloVehiculo)
   OR EXISTS (SELECT 1 FROM dbo.Especialidad)
   OR EXISTS (SELECT 1 FROM dbo.Servicio)
   OR EXISTS (SELECT 1 FROM dbo.Proveedor)
   OR EXISTS (SELECT 1 FROM dbo.Repuesto)
BEGIN
    PRINT N'DETENIDO: los catálogos deben estar vacíos. No se borraron datos.';
    SET NOEXEC ON;
    ;THROW 51005, N'Los catálogos deben estar vacíos. No se insertaron ni eliminaron datos.', 1;
END;

DECLARE @TablaIdentity SYSNAME = NULL;
BEGIN TRY
    BEGIN TRANSACTION;

    CREATE TABLE #NumerosMaestros (n INT NOT NULL PRIMARY KEY);
    ;WITH Digitos AS
    (
        SELECT d FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS D(d)
    )
    INSERT #NumerosMaestros(n)
    SELECT 1 + u.d + 10 * d.d + 100 * c.d
    FROM Digitos AS u CROSS JOIN Digitos AS d CROSS JOIN Digitos AS c
    WHERE 1 + u.d + 10 * d.d + 100 * c.d <= 500;

    SET @TablaIdentity = N'MarcaVehiculo';
    SET IDENTITY_INSERT dbo.MarcaVehiculo ON;
    INSERT dbo.MarcaVehiculo (MarcaID,NombreMarca) VALUES
        (1,N'Volvo'),(2,N'Scania'),(3,N'Mercedes Benz'),(4,N'MAN'),(5,N'Caterpillar');
    SET IDENTITY_INSERT dbo.MarcaVehiculo OFF;
    SET @TablaIdentity = NULL;

    SET @TablaIdentity = N'ModeloVehiculo';
    SET IDENTITY_INSERT dbo.ModeloVehiculo ON;
    INSERT dbo.ModeloVehiculo (ModeloID,MarcaID,NombreModelo) VALUES
        (1,1,N'FH'),(2,1,N'FM'),(3,1,N'FMX'),(4,1,N'VM'),(5,1,N'FE'),
        (6,2,N'R 450'),(7,2,N'R 500'),(8,2,N'G 410'),(9,2,N'P 410'),(10,2,N'P 360'),
        (11,3,N'Actros'),(12,3,N'Arocs'),(13,3,N'Axor'),(14,3,N'Atego'),(15,3,N'Econic'),
        (16,4,N'TGX 26.480'),(17,4,N'TGX 26.540'),(18,4,N'TGS 33.440'),(19,4,N'TGS 40.480'),(20,4,N'TGA 26.440'),
        (21,5,N'773G'),(22,5,N'775G'),(23,5,N'777G'),(24,5,N'785D'),(25,5,N'793F');
    SET IDENTITY_INSERT dbo.ModeloVehiculo OFF;
    SET @TablaIdentity = NULL;

    SET @TablaIdentity = N'Especialidad';
    SET IDENTITY_INSERT dbo.Especialidad ON;
    INSERT dbo.Especialidad (EspecialidadID,Nombre) VALUES
        (1,N'Preventivo'),(2,N'Correctivo'),(3,N'Diagnóstico'),
        (4,N'Motor'),(5,N'Transmisión'),(6,N'Sistema eléctrico');
    SET IDENTITY_INSERT dbo.Especialidad OFF;
    SET @TablaIdentity = NULL;

    SET @TablaIdentity = N'Servicio';
    SET IDENTITY_INSERT dbo.Servicio ON;
    INSERT dbo.Servicio (ServicioID,NombreServicio,Categoria,PrecioBase) VALUES
        (1,N'Cambio de aceite y filtro de motor',N'Preventivo',110.00),
        (2,N'Reemplazo de filtros de combustible',N'Preventivo',105.00),
        (3,N'Reemplazo de filtro de aire',N'Preventivo',95.00),
        (4,N'Engrase de chasis y articulaciones',N'Preventivo',95.00),
        (5,N'Mantenimiento del sistema de refrigeración',N'Preventivo',115.00),
        (6,N'Inspección de frenos y ajuste preventivo',N'Preventivo',120.00),
        (7,N'Revisión de correas y tensores',N'Preventivo',105.00),
        (8,N'Mantenimiento de secador de aire',N'Preventivo',115.00),
        (9,N'Inspección general de flota',N'Preventivo',125.00),
        (10,N'Reemplazo de pastillas de freno',N'Correctivo',135.00),
        (11,N'Reparación de frenos de tambor',N'Correctivo',140.00),
        (12,N'Reemplazo de cámara de freno',N'Correctivo',135.00),
        (13,N'Reparación de suspensión',N'Correctivo',150.00),
        (14,N'Reemplazo de terminales de dirección',N'Correctivo',140.00),
        (15,N'Reemplazo de rodamientos de rueda',N'Correctivo',145.00),
        (16,N'Corrección de fugas neumáticas',N'Correctivo',130.00),
        (17,N'Reparación de cubos y espárragos',N'Correctivo',135.00),
        (18,N'Ajuste y reparación de quinta rueda',N'Correctivo',150.00),
        (19,N'Escaneo electrónico integral',N'Diagnóstico',150.00),
        (20,N'Diagnóstico de fallas de motor',N'Diagnóstico',170.00),
        (21,N'Diagnóstico de presión de combustible',N'Diagnóstico',160.00),
        (22,N'Diagnóstico de temperatura y refrigeración',N'Diagnóstico',150.00),
        (23,N'Diagnóstico de frenos ABS y EBS',N'Diagnóstico',165.00),
        (24,N'Prueba de compresión de cilindros',N'Diagnóstico',175.00),
        (25,N'Análisis de vibraciones del tren motriz',N'Diagnóstico',170.00),
        (26,N'Diagnóstico de comunicación CAN',N'Diagnóstico',180.00),
        (27,N'Reemplazo y calibración de inyectores',N'Motor',185.00),
        (28,N'Reemplazo de bomba de agua',N'Motor',165.00),
        (29,N'Reparación de turbocompresor',N'Motor',195.00),
        (30,N'Reparación de culata',N'Motor',200.00),
        (31,N'Reemplazo de juntas de motor',N'Motor',170.00),
        (32,N'Reparación de conjunto pistón y camisa',N'Motor',210.00),
        (33,N'Reemplazo de bomba de aceite',N'Motor',185.00),
        (34,N'Reparación de sistema de admisión',N'Motor',175.00),
        (35,N'Reemplazo de kit de embrague',N'Transmisión',175.00),
        (36,N'Reparación de caja de cambios',N'Transmisión',200.00),
        (37,N'Reparación de diferencial',N'Transmisión',190.00),
        (38,N'Reemplazo de crucetas de cardán',N'Transmisión',160.00),
        (39,N'Reemplazo de retenes de transmisión',N'Transmisión',155.00),
        (40,N'Reparación de actuador de embrague',N'Transmisión',180.00),
        (41,N'Reemplazo de soporte de cardán',N'Transmisión',160.00),
        (42,N'Reparación de sincronizadores',N'Transmisión',195.00),
        (43,N'Reemplazo de alternador',N'Sistema eléctrico',145.00),
        (44,N'Reparación de motor de arranque',N'Sistema eléctrico',150.00),
        (45,N'Reemplazo y prueba de baterías',N'Sistema eléctrico',115.00),
        (46,N'Reparación de arnés eléctrico',N'Sistema eléctrico',160.00),
        (47,N'Reparación de sistema de iluminación',N'Sistema eléctrico',125.00),
        (48,N'Reemplazo de relés y fusibles',N'Sistema eléctrico',110.00),
        (49,N'Reparación de circuitos de carga',N'Sistema eléctrico',150.00),
        (50,N'Reemplazo de sensor eléctrico',N'Sistema eléctrico',155.00);
    SET IDENTITY_INSERT dbo.Servicio OFF;
    SET @TablaIdentity = NULL;

    -- Nombres comerciales ficticios y teléfonos de demostración. El RUC usa
    -- una base elegida para este generador, sin afirmar que esté libre o inscrita.
    SET @TablaIdentity = N'Proveedor';
    SET IDENTITY_INSERT dbo.Proveedor ON;
    INSERT dbo.Proveedor (ProveedorID,RUC,NombreProveedor,Telefono)
    SELECT n.n,
           '208' + RIGHT('0000000' + CONVERT(VARCHAR(7),n.n),7) + '0',
           CONCAT(CASE (n.n-1)%10
                    WHEN 0 THEN N'Repuestos Diésel Andinos'
                    WHEN 1 THEN N'Suministros Pesados del Pacífico'
                    WHEN 2 THEN N'Motores y Filtros del Sur'
                    WHEN 3 THEN N'Importaciones Ruta Minera'
                    WHEN 4 THEN N'Autopartes del Altiplano'
                    WHEN 5 THEN N'Distribuidora Mecánica del Norte'
                    WHEN 6 THEN N'Tecnología de Frenos Central'
                    WHEN 7 THEN N'Transmisiones del Valle'
                    WHEN 8 THEN N'Componentes Eléctricos del Perú'
                    ELSE N'Suministros de Flota del Oriente' END,
                  N' ',RIGHT(N'000'+CONVERT(NVARCHAR(3),n.n),3),N' S.A.C.'),
           '01' + RIGHT('0000000' + CONVERT(VARCHAR(7),6000000+n.n),7)
    FROM #NumerosMaestros AS n WHERE n.n <= 100;
    SET IDENTITY_INSERT dbo.Proveedor OFF;
    SET @TablaIdentity = NULL;

    CREATE TABLE #FamiliaRepuesto
    (
        FamiliaID INT NOT NULL PRIMARY KEY,
        Nombre NVARCHAR(100) NOT NULL,
        Categoria NVARCHAR(60) NOT NULL,
        Marca NVARCHAR(60) NOT NULL,
        CostoBase DECIMAL(12,2) NOT NULL
    );
    -- Categoria identifica la línea de mantenimiento atendida por el repuesto.
    INSERT #FamiliaRepuesto (FamiliaID,Nombre,Categoria,Marca,CostoBase) VALUES
        (1,N'Filtro de aceite de motor',N'Preventivo',N'MANN-FILTER',85.00),
        (2,N'Filtro de combustible diésel',N'Preventivo',N'Mahle',115.00),
        (3,N'Filtro de aire primario',N'Preventivo',N'Donaldson',185.00),
        (4,N'Filtro separador de agua',N'Preventivo',N'Racor',145.00),
        (5,N'Aceite de motor diésel, bidón 20 L',N'Preventivo',N'Shell',350.00),
        (6,N'Refrigerante, envase 5 L',N'Preventivo',N'Mobil',78.00),
        (7,N'Grasa de servicio pesado, cartucho',N'Preventivo',N'SKF',42.00),
        (8,N'Correa auxiliar de motor',N'Preventivo',N'Gates',155.00),
        (9,N'Cartucho secador de aire',N'Preventivo',N'WABCO',185.00),
        (10,N'Juego de sellos para drenaje',N'Preventivo',N'Elring',24.00),
        (11,N'Juego de pastillas de freno pesado',N'Correctivo',N'Bendix',480.00),
        (12,N'Juego de zapatas de freno',N'Correctivo',N'Ferodo',365.00),
        (13,N'Disco de freno ventilado',N'Correctivo',N'Brembo',695.00),
        (14,N'Tambor de freno de eje pesado',N'Correctivo',N'Meritor',810.00),
        (15,N'Cámara neumática de freno',N'Correctivo',N'WABCO',310.00),
        (16,N'Amortiguador de suspensión',N'Correctivo',N'Sachs',385.00),
        (17,N'Terminal de dirección',N'Correctivo',N'TRW',220.00),
        (18,N'Buje de suspensión reforzado',N'Correctivo',N'Febi',95.00),
        (19,N'Rodamiento de cubo de rueda',N'Correctivo',N'SKF',285.00),
        (20,N'Juego de espárragos y tuercas de rueda',N'Correctivo',N'Febi',135.00),
        (21,N'Sensor de presión para diagnóstico',N'Diagnóstico',N'Bosch',235.00),
        (22,N'Sensor de temperatura para diagnóstico',N'Diagnóstico',N'Bosch',125.00),
        (23,N'Conector de diagnóstico de vehículo pesado',N'Diagnóstico',N'Deutsch',75.00),
        (24,N'Kit de terminales y conectores estancos',N'Diagnóstico',N'TE Connectivity',48.00),
        (25,N'Cable de reparación para señal de sensores',N'Diagnóstico',N'Bosch',65.00),
        (26,N'Inyector diésel de alta presión',N'Motor',N'Bosch',1850.00),
        (27,N'Bomba de agua de motor pesado',N'Motor',N'SKF',680.00),
        (28,N'Turbocompresor de motor diésel',N'Motor',N'Garrett',2850.00),
        (29,N'Empaquetadura de culata',N'Motor',N'Elring',385.00),
        (30,N'Junta de tapa de balancines',N'Motor',N'Elring',110.00),
        (31,N'Kit de pistón y camisa',N'Motor',N'Mahle',1450.00),
        (32,N'Juego de aros de pistón',N'Motor',N'Mahle',295.00),
        (33,N'Bomba de aceite de motor',N'Motor',N'Pierburg',890.00),
        (34,N'Manguera reforzada de admisión',N'Motor',N'Gates',165.00),
        (35,N'Juego de cojinetes de biela',N'Motor',N'Glyco',385.00),
        (36,N'Kit de embrague de servicio pesado',N'Transmisión',N'Sachs',1950.00),
        (37,N'Rodamiento de caja de cambios',N'Transmisión',N'SKF',385.00),
        (38,N'Juego de rodamientos de diferencial',N'Transmisión',N'Timken',780.00),
        (39,N'Cruceta de cardán reforzada',N'Transmisión',N'Spicer',285.00),
        (40,N'Retén de eje de transmisión',N'Transmisión',N'Corteco',85.00),
        (41,N'Actuador de embrague',N'Transmisión',N'WABCO',890.00),
        (42,N'Soporte central de cardán',N'Transmisión',N'SKF',315.00),
        (43,N'Anillo sincronizador de caja',N'Transmisión',N'ZF',425.00),
        (44,N'Alternador de servicio pesado 24 V',N'Sistema eléctrico',N'Bosch',1150.00),
        (45,N'Motor de arranque 24 V',N'Sistema eléctrico',N'Bosch',1380.00),
        (46,N'Batería de servicio pesado 12 V',N'Sistema eléctrico',N'Varta',685.00),
        (47,N'Arnés de reparación de instalación eléctrica',N'Sistema eléctrico',N'Delphi',185.00),
        (48,N'Faro de trabajo de vehículo pesado',N'Sistema eléctrico',N'Hella',225.00),
        (49,N'Kit de relés y fusibles 24 V',N'Sistema eléctrico',N'Hella',75.00),
        (50,N'Sensor de velocidad de rueda',N'Sistema eléctrico',N'WABCO',245.00);

    SET @TablaIdentity = N'Repuesto';
    SET IDENTITY_INSERT dbo.Repuesto ON;
    INSERT dbo.Repuesto (RepuestoID,NombreRepuesto,Categoria,Marca,CostoUnitario,StockActual)
    SELECT (f.FamiliaID-1)*10+n.n,
           CONCAT(f.Nombre,N' | TTS-',RIGHT(N'000'+CONVERT(NVARCHAR(3),f.FamiliaID),3),
                  N'-',RIGHT(N'00'+CONVERT(NVARCHAR(2),n.n),2)),
           f.Categoria,f.Marca,
           CAST(ROUND(f.CostoBase * (1.00 + (n.n-1) * 0.075),2) AS DECIMAL(12,2)),
           0
    FROM #FamiliaRepuesto AS f
    CROSS JOIN #NumerosMaestros AS n WHERE n.n <= 10;
    SET IDENTITY_INSERT dbo.Repuesto OFF;
    SET @TablaIdentity = NULL;

    IF (SELECT COUNT(*) FROM dbo.MarcaVehiculo) <> 5
       OR (SELECT COUNT(*) FROM dbo.ModeloVehiculo) <> 25
       OR (SELECT COUNT(*) FROM dbo.Especialidad) <> 6
       OR (SELECT COUNT(*) FROM dbo.Servicio) <> 50
       OR (SELECT COUNT(*) FROM dbo.Proveedor) <> 100
       OR (SELECT COUNT(*) FROM dbo.Repuesto) <> 500
    BEGIN
        ;THROW 51006, N'Los conteos de maestros no coinciden con el contrato. Se revierte la carga.', 1;
    END;

    DROP TABLE #FamiliaRepuesto;
    DROP TABLE #NumerosMaestros;
    COMMIT TRANSACTION;
    PRINT N'Maestros cargados y verificados. Continúe con 03_generacion_masiva.sql.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    -- IDENTITY_INSERT es de sesión; se apaga incluso si la carga ha fallado.
    IF @TablaIdentity IS NOT NULL
    BEGIN
        DECLARE @ApagarIdentity NVARCHAR(300) =
            N'SET IDENTITY_INSERT dbo.' + QUOTENAME(@TablaIdentity) + N' OFF;';
        EXEC sys.sp_executesql @ApagarIdentity;
    END;
    PRINT ERROR_MESSAGE();
    SET NOEXEC ON;
    ;THROW;
END CATCH;
GO
