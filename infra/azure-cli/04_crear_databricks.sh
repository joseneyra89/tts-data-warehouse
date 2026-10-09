#!/usr/bin/env bash
set -euo pipefail

# Azure Databricks para ejecutar dbt y construir las capas Silver y Gold.
RESOURCE_GROUP="rg-tts-p3-dev"
LOCATION="centralus"
WORKSPACE="adb-tts-p3-dev-joseneyra"
ACCESS_CONNECTOR="ac-tts-p3-dev-joseneyra"
STORAGE_ACCOUNT="stttsp3devjoseneyra"

az extension add --name databricks --upgrade --yes
az provider register --namespace Microsoft.Databricks --wait

if ! az databricks workspace show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WORKSPACE" >/dev/null 2>&1; then
  az databricks workspace create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$WORKSPACE" \
    --location "$LOCATION" \
    --sku premium \
    --compute-mode Hybrid \
    --public-network-access Enabled \
    --tags Project=TTS Environment=dev Course=DataWarehouse
fi

if ! az databricks access-connector show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACCESS_CONNECTOR" >/dev/null 2>&1; then
  az databricks access-connector create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$ACCESS_CONNECTOR" \
    --location "$LOCATION" \
    --identity-type SystemAssigned
fi

connectorPrincipalId="$(az databricks access-connector show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACCESS_CONNECTOR" \
  --query identity.principalId \
  --output tsv)"

storageId="$(az storage account show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$STORAGE_ACCOUNT" \
  --query id \
  --output tsv)"

roleAssignmentId="$(az role assignment list \
  --assignee "$connectorPrincipalId" \
  --scope "$storageId" \
  --query "[?roleDefinitionName=='Storage Blob Data Contributor'] | [0].id" \
  --output tsv)"

if [[ -z "$roleAssignmentId" ]]; then
  az role assignment create \
    --assignee-object-id "$connectorPrincipalId" \
    --assignee-principal-type ServicePrincipal \
    --role "Storage Blob Data Contributor" \
    --scope "$storageId"
fi

echo "Workspace:"
az databricks workspace show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WORKSPACE" \
  --query "{name:name,provisioningState:provisioningState,workspaceUrl:workspaceUrl,sku:sku.name}" \
  --output table

echo "Access Connector:"
az databricks access-connector show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACCESS_CONNECTOR" \
  --query "{name:name,principalId:identity.principalId,provisioningState:provisioningState}" \
  --output table
