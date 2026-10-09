#!/usr/bin/env bash
# Proyecto 3 TTS - ADLS Gen2 con zonas Medallion.
# Ejecutar manualmente en Azure Cloud Shell (Bash) después de revisar el archivo.
set -euo pipefail

SUBSCRIPTION_NAME="Azure for Students"
RESOURCE_GROUP="rg-tts-p3-dev"
LOCATION="centralus"
STORAGE_ACCOUNT="stttsp3devjoseneyra"

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

if ! az storage account show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$STORAGE_ACCOUNT" \
  --output none 2>/dev/null; then
  az storage account create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$STORAGE_ACCOUNT" \
    --location "$LOCATION" \
    --kind StorageV2 \
    --sku Standard_LRS \
    --access-tier Hot \
    --enable-hierarchical-namespace true \
    --enable-sftp false \
    --enable-nfs-v3 false \
    --enable-local-user false \
    --https-only true \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --allow-shared-key-access true \
    --allow-cross-tenant-replication false \
    --allowed-copy-scope AAD \
    --public-network-access Enabled \
    --default-action Allow \
    --routing-choice MicrosoftRouting \
    --dns-endpoint-type Standard \
    --require-infrastructure-encryption false \
    --tags "${TAGS[@]}" \
    --output none
else
  echo "La cuenta $STORAGE_ACCOUNT ya existe; no se vuelve a crear."
fi

az storage account update \
  --resource-group "$RESOURCE_GROUP" \
  --name "$STORAGE_ACCOUNT" \
  --allow-blob-public-access false \
  --allow-shared-key-access true \
  --allow-cross-tenant-replication false \
  --allowed-copy-scope AAD \
  --public-network-access Enabled \
  --default-action Allow \
  --routing-choice MicrosoftRouting \
  --min-tls-version TLS1_2 \
  --tags "${TAGS[@]}" \
  --output none

az storage account blob-service-properties update \
  --resource-group "$RESOURCE_GROUP" \
  --account-name "$STORAGE_ACCOUNT" \
  --enable-delete-retention true \
  --delete-retention-days 7 \
  --enable-container-delete-retention true \
  --container-delete-retention-days 7 \
  --enable-versioning false \
  --enable-change-feed false \
  --output none

STORAGE_ID="$(az storage account show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$STORAGE_ACCOUNT" \
  --query id --output tsv)"

CURRENT_USER_ID="$(az ad signed-in-user show --query id --output tsv)"

ROLE_COUNT="$(az role assignment list \
  --assignee "$CURRENT_USER_ID" \
  --scope "$STORAGE_ID" \
  --role "Storage Blob Data Owner" \
  --query 'length(@)' --output tsv)"

if [[ "$ROLE_COUNT" == "0" ]]; then
  az role assignment create \
    --assignee-object-id "$CURRENT_USER_ID" \
    --assignee-principal-type User \
    --role "Storage Blob Data Owner" \
    --scope "$STORAGE_ID" \
    --output none
else
  echo "El usuario actual ya tiene Storage Blob Data Owner en la cuenta."
fi

for CONTAINER in bronze silver gold; do
  az storage container create \
    --account-name "$STORAGE_ACCOUNT" \
    --name "$CONTAINER" \
    --auth-mode login \
    --public-access off \
    --output none
done

az storage account show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$STORAGE_ACCOUNT" \
  --query '{name:name,location:location,kind:kind,sku:sku.name,hns:isHnsEnabled,accessTier:accessTier,httpsOnly:enableHttpsTrafficOnly,tls:minimumTlsVersion,publicBlobAccess:allowBlobPublicAccess,copyScope:allowedCopyScope}' \
  --output table

az storage container list \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --query "[?name=='bronze' || name=='silver' || name=='gold'].{container:name,publicAccess:properties.publicAccess}" \
  --output table
