#!/usr/bin/env bash
# Proyecto 3 TTS - Azure SQL Database gratuito y reproducible.
# Ejecutar manualmente en Azure Cloud Shell (Bash) después de revisar el archivo.
set -euo pipefail

SUBSCRIPTION_NAME="Azure for Students"
RESOURCE_GROUP="rg-tts-p3-dev"
LOCATION="centralus"
SQL_SERVER="sql-tts-p3-dev-joseneyra"
DATABASE_NAME="TTS_OLTP"
SQL_ADMIN_USER="ttsadmin"

TAGS=(
  Project="TTS-DataWarehouse"
  Environment="Development"
  Owner="JoseNeyra"
  CostCenter="Academic"
  ManagedBy="AzureCLI"
)

az account set --subscription "$SUBSCRIPTION_NAME"

if ! az group show --name "$RESOURCE_GROUP" --output none 2>/dev/null; then
  echo "Falta el grupo de recursos $RESOURCE_GROUP. Ejecute primero 01_crear_grupo_recursos.sh."
  exit 1
fi

if ! az sql server show --resource-group "$RESOURCE_GROUP" --name "$SQL_SERVER" --output none 2>/dev/null; then
  ENTRA_OBJECT_ID="$(az ad signed-in-user show --query id --output tsv)"
  ENTRA_DISPLAY_NAME="$(az ad signed-in-user show --query displayName --output tsv)"

  read -rsp "Contraseña nueva para el administrador SQL ${SQL_ADMIN_USER}: " SQL_ADMIN_PASSWORD
  echo

  az sql server create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$SQL_SERVER" \
    --location "$LOCATION" \
    --admin-user "$SQL_ADMIN_USER" \
    --admin-password "$SQL_ADMIN_PASSWORD" \
    --external-admin-name "$ENTRA_DISPLAY_NAME" \
    --external-admin-sid "$ENTRA_OBJECT_ID" \
    --external-admin-principal-type User \
    --enable-public-network true \
    --minimal-tls-version 1.2 \
    --tags "${TAGS[@]}" \
    --output none

  unset SQL_ADMIN_PASSWORD
else
  echo "El servidor $SQL_SERVER ya existe; no se vuelve a crear."
fi

SERVER_ID="$(az sql server show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$SQL_SERVER" \
  --query id --output tsv)"

az tag update \
  --resource-id "$SERVER_ID" \
  --operation Merge \
  --tags "${TAGS[@]}" \
  --output none

# Esta regla permite la conexión desde servicios de Azure. La autenticación y
# los permisos de base de datos continúan siendo obligatorios.
az sql server firewall-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --server "$SQL_SERVER" \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0 \
  --output none

# Para reproducir la regla del equipo local, ejecute antes:
# export CLIENT_IP="203.0.113.10"
if [[ -n "${CLIENT_IP:-}" ]]; then
  az sql server firewall-rule create \
    --resource-group "$RESOURCE_GROUP" \
    --server "$SQL_SERVER" \
    --name ClienteDesarrollo \
    --start-ip-address "$CLIENT_IP" \
    --end-ip-address "$CLIENT_IP" \
    --output none
else
  echo "CLIENT_IP no está definida; no se crea una regla para el equipo local."
fi

if ! az sql db show \
  --resource-group "$RESOURCE_GROUP" \
  --server "$SQL_SERVER" \
  --name "$DATABASE_NAME" \
  --output none 2>/dev/null; then
  az sql db create \
    --resource-group "$RESOURCE_GROUP" \
    --server "$SQL_SERVER" \
    --name "$DATABASE_NAME" \
    --edition GeneralPurpose \
    --family Gen5 \
    --capacity 2 \
    --compute-model Serverless \
    --auto-pause-delay 60 \
    --min-capacity 0.5 \
    --max-size 32GB \
    --collation Modern_Spanish_CI_AS \
    --backup-storage-redundancy Local \
    --zone-redundant false \
    --ledger-on Disabled \
    --use-free-limit true \
    --free-limit-exhaustion-behavior AutoPause \
    --tags "${TAGS[@]}" \
    --output none
else
  echo "La base $DATABASE_NAME ya existe; no se vuelve a crear."
fi

DATABASE_ID="$(az sql db show \
  --resource-group "$RESOURCE_GROUP" \
  --server "$SQL_SERVER" \
  --name "$DATABASE_NAME" \
  --query id --output tsv)"

az tag update \
  --resource-id "$DATABASE_ID" \
  --operation Merge \
  --tags "${TAGS[@]}" \
  --output none

az sql db show \
  --resource-group "$RESOURCE_GROUP" \
  --server "$SQL_SERVER" \
  --name "$DATABASE_NAME" \
  --query '{database:name,status:status,location:location,sku:sku.name,tier:sku.tier,capacity:sku.capacity,maxSizeBytes:maxSizeBytes,autoPauseDelay:autoPauseDelay,freeLimit:useFreeLimit,freeLimitBehavior:freeLimitExhaustionBehavior,collation:collation}' \
  --output table
