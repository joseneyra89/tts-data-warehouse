# Silver

Los modelos `stg_*` limpian nombres, normalizan texto y fijan tipos antes de construir el modelo dimensional.

Se materializan incrementalmente con estrategia Delta `merge` y la clave primaria del OLTP como `unique_key`. Bronze es una réplica de estado actual mantenida por ADF, por lo que esta primera versión compara el estado completo en cada micro-lote. La optimización por versión de Delta/CDF se incorporará después de validar el primer ciclo dbt; no se simula un LSN que ADF no haya persistido.
