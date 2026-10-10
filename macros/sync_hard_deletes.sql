{% macro execute_hard_delete_sync(mappings) %}
    {% if execute %}
        {% for mapping in mappings %}
            {% set delete_sql %}
                delete from {{ mapping['target'] }} as tgt
                where not exists (
                    select 1
                    from {{ mapping['source'] }} as src
                    where src.{{ adapter.quote(mapping['source_key']) }}
                        = tgt.{{ adapter.quote(mapping['target_key']) }}
                )
            {% endset %}

            {% do log(
                'Sincronizando eliminaciones: ' ~ mapping['source'] ~
                ' -> ' ~ mapping['target'],
                info=true
            ) %}
            {% do run_query(delete_sql) %}
        {% endfor %}
    {% endif %}
{% endmacro %}


{% macro sync_silver_hard_deletes() %}
    {% set mappings = [
        {'target': ref('stg_cliente'), 'source': source('bronze', 'cliente'), 'target_key': 'cliente_id', 'source_key': 'ClienteID'},
        {'target': ref('stg_vehiculo'), 'source': source('bronze', 'vehiculo'), 'target_key': 'vehiculo_id', 'source_key': 'VehiculoID'},
        {'target': ref('stg_tecnico'), 'source': source('bronze', 'tecnico'), 'target_key': 'tecnico_id', 'source_key': 'TecnicoID'},
        {'target': ref('stg_servicio'), 'source': source('bronze', 'servicio'), 'target_key': 'servicio_id', 'source_key': 'ServicioID'},
        {'target': ref('stg_repuesto'), 'source': source('bronze', 'repuesto'), 'target_key': 'repuesto_id', 'source_key': 'RepuestoID'},
        {'target': ref('stg_orden_servicio'), 'source': source('bronze', 'ordenservicio'), 'target_key': 'orden_id', 'source_key': 'OrdenID'},
        {'target': ref('stg_detalle_servicio'), 'source': source('bronze', 'detalleservicio'), 'target_key': 'detalle_id', 'source_key': 'DetalleID'},
        {'target': ref('stg_consumo_repuesto'), 'source': source('bronze', 'consumorepuesto'), 'target_key': 'consumo_id', 'source_key': 'ConsumoID'},
        {'target': ref('stg_factura'), 'source': source('bronze', 'factura'), 'target_key': 'factura_id', 'source_key': 'FacturaID'},
        {'target': ref('stg_marca_vehiculo'), 'source': source('bronze', 'marcavehiculo'), 'target_key': 'marca_id', 'source_key': 'MarcaID'},
        {'target': ref('stg_modelo_vehiculo'), 'source': source('bronze', 'modelovehiculo'), 'target_key': 'modelo_id', 'source_key': 'ModeloID'},
        {'target': ref('stg_especialidad'), 'source': source('bronze', 'especialidad'), 'target_key': 'especialidad_id', 'source_key': 'EspecialidadID'}
    ] %}

    {% do execute_hard_delete_sync(mappings) %}
{% endmacro %}


{% macro sync_gold_hard_deletes() %}
    {% set mappings = [
        {'target': ref('dim_cliente'), 'source': ref('stg_cliente'), 'target_key': 'cliente_key', 'source_key': 'cliente_id'},
        {'target': ref('dim_vehiculo'), 'source': ref('stg_vehiculo'), 'target_key': 'vehiculo_key', 'source_key': 'vehiculo_id'},
        {'target': ref('dim_tecnico'), 'source': ref('stg_tecnico'), 'target_key': 'tecnico_key', 'source_key': 'tecnico_id'},
        {'target': ref('dim_servicio'), 'source': ref('stg_servicio'), 'target_key': 'servicio_key', 'source_key': 'servicio_id'},
        {'target': ref('dim_repuesto'), 'source': ref('stg_repuesto'), 'target_key': 'repuesto_key', 'source_key': 'repuesto_id'},
        {'target': ref('fact_servicio'), 'source': ref('stg_detalle_servicio'), 'target_key': 'detalle_servicio_key', 'source_key': 'detalle_id'},
        {'target': ref('fact_consumo_repuesto'), 'source': ref('stg_consumo_repuesto'), 'target_key': 'consumo_repuesto_key', 'source_key': 'consumo_id'},
        {'target': ref('fact_factura'), 'source': ref('stg_factura'), 'target_key': 'factura_key', 'source_key': 'factura_id'}
    ] %}

    {% do execute_hard_delete_sync(mappings) %}
{% endmacro %}
