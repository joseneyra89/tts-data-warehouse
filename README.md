# Proyecto 3 - TTS Data Warehouse en Azure

Este repositorio contiene la implementación académica de **TRUCK TOP SERVICE** para el Proyecto 3. Su objetivo es propagar cambios del OLTP hasta Power BI Service mediante CDC, arquitectura Medallion y micro-lotes.

## Arquitectura objetivo

```text
Azure SQL Database (OLTP + CDC)
  -> Azure Data Factory CDC
  -> ADLS Gen2 /bronze (eventos crudos)
  -> dbt: /silver (datos depurados) -> /gold (modelo dimensional)
  -> Azure Synapse Analytics
  -> Power BI Service
```

## Regla de costos

El presupuesto es US$100 de Azure for Students para un año. Ningún recurso de cómputo se deja ejecutándose fuera de una sesión de trabajo o demostración. En especial, el recurso CDC de ADF usa cómputo de Data Flow, y un pool dedicado de Synapse se pausa inmediatamente después de cada ejecución.

La guía de implementación empieza en [00_guias/01_ruta_de_aprendizaje.md](00_guias/01_ruta_de_aprendizaje.md).

## Estado

Etapa actual: 0 - diseño y preparación local. Azure Cloud Shell fue validado el 2026-09-14 con la suscripción Azure for Students en estado Enabled. Se eligió la sesión efímera sin almacenamiento, por lo que no se creó una cuenta de almacenamiento para Cloud Shell ni se consumen recursos persistentes para esta herramienta.
