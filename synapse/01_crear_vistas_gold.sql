-- Ejecutar en el pool SQL serverless Built-in y en la base de datos tts_dw.
-- La fuente sin credencial usa la identidad de Microsoft Entra del usuario.

CREATE EXTERNAL DATA SOURCE gold_lake
WITH (
    LOCATION = 'https://stttsp3devjoseneyra.dfs.core.windows.net/gold'
);
GO

CREATE SCHEMA gold;
GO

CREATE VIEW gold.dim_cliente AS
SELECT *
FROM OPENROWSET(
    BULK 'synapse/dim_cliente/*.parquet',
    DATA_SOURCE = 'gold_lake',
    FORMAT = 'PARQUET'
) AS filas;
GO

CREATE VIEW gold.dim_vehiculo AS
SELECT *
FROM OPENROWSET(
    BULK 'synapse/dim_vehiculo/*.parquet',
    DATA_SOURCE = 'gold_lake',
    FORMAT = 'PARQUET'
) AS filas;
GO

CREATE VIEW gold.dim_tecnico AS
SELECT *
FROM OPENROWSET(
    BULK 'synapse/dim_tecnico/*.parquet',
    DATA_SOURCE = 'gold_lake',
    FORMAT = 'PARQUET'
) AS filas;
GO

CREATE VIEW gold.dim_servicio AS
SELECT *
FROM OPENROWSET(
    BULK 'synapse/dim_servicio/*.parquet',
    DATA_SOURCE = 'gold_lake',
    FORMAT = 'PARQUET'
) AS filas;
GO

CREATE VIEW gold.dim_repuesto AS
SELECT *
FROM OPENROWSET(
    BULK 'synapse/dim_repuesto/*.parquet',
    DATA_SOURCE = 'gold_lake',
    FORMAT = 'PARQUET'
) AS filas;
GO

CREATE VIEW gold.dim_fecha AS
SELECT *
FROM OPENROWSET(
    BULK 'synapse/dim_fecha/*.parquet',
    DATA_SOURCE = 'gold_lake',
    FORMAT = 'PARQUET'
) AS filas;
GO

CREATE VIEW gold.fact_servicio AS
SELECT *
FROM OPENROWSET(
    BULK 'synapse/fact_servicio/*.parquet',
    DATA_SOURCE = 'gold_lake',
    FORMAT = 'PARQUET'
) AS filas;
GO

CREATE VIEW gold.fact_consumo_repuesto AS
SELECT *
FROM OPENROWSET(
    BULK 'synapse/fact_consumo_repuesto/*.parquet',
    DATA_SOURCE = 'gold_lake',
    FORMAT = 'PARQUET'
) AS filas;
GO

CREATE VIEW gold.fact_factura AS
SELECT *
FROM OPENROWSET(
    BULK 'synapse/fact_factura/*.parquet',
    DATA_SOURCE = 'gold_lake',
    FORMAT = 'PARQUET'
) AS filas;
GO
