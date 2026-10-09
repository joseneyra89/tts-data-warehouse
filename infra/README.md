# Infraestructura Azure

Los scripts de esta carpeta se ejecutan desde Azure Cloud Shell (Bash), en orden numérico y solo después de revisarlos. El primer script crea únicamente el grupo de recursos `rg-tts-p3-dev` en `eastus` y aplica etiquetas para el control de costos. Un grupo de recursos no genera cobro.

El segundo script reproduce el servidor lógico y Azure SQL Database gratuito que se aprobaron manualmente en el portal. Los recursos de datos usan `centralus` porque la suscripción educativa no permitió crear Azure SQL en East US. Las etiquetas se aplican directamente a cada recurso porque Azure no las hereda automáticamente desde el grupo.

El tercer script reproduce ADLS Gen2 con almacenamiento Standard LRS, espacio de nombres jerárquico, recuperación de siete días y los contenedores privados `bronze`, `silver` y `gold`. La identidad de Microsoft Entra se usa para el plano de datos; el script no contiene claves.
