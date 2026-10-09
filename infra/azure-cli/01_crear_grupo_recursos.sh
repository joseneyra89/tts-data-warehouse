#!/usr/bin/env bash
# Proyecto 3 TTS - base administrativa sin costo.
set -euo pipefail

SUBSCRIPTION_NAME="Azure for Students"
RESOURCE_GROUP="rg-tts-p3-dev"
LOCATION="eastus"

az account set --subscription "$SUBSCRIPTION_NAME"

az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags \
    Project="TTS-DataWarehouse" \
    Environment="Development" \
    Owner="JoseNeyra" \
    CostCenter="Academic" \
    ManagedBy="AzureCLI"

az group show \
  --name "$RESOURCE_GROUP" \
  --query '{name:name,location:location,provisioningState:properties.provisioningState,tags:tags}' \
  --output jsonc
