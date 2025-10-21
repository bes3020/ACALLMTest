#!/bin/bash

set -e

# Configuration
RESOURCE_GROUP="rg-huggingface-llm"
LOCATION="eastus"
STORAGE_ACCOUNT="hfmodelstorage$RANDOM"
SHARE_NAME="modeldata"
CONTAINER_YAML="container-instance.yaml"

echo "🚀 Deploying Hugging Face LLM to Azure Container Instances"
echo ""

# Get Hugging Face token
read -p "Enter your Hugging Face token (or press Enter to skip): " HF_TOKEN

# Create resource group
echo "📦 Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account for model cache
echo "💾 Creating storage account for model cache..."
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2

# Get storage key
STORAGE_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --query "[0].value" \
  --output tsv)

# Create file share
echo "📁 Creating file share..."
az storage share create \
  --name $SHARE_NAME \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY

# Update YAML with storage details and token
echo "📝 Updating deployment configuration..."
sed -e "s/YOUR_STORAGE_ACCOUNT_NAME/$STORAGE_ACCOUNT/g" \
    -e "s/YOUR_STORAGE_ACCOUNT_KEY/$STORAGE_KEY/g" \
    -e "s/YOUR_HF_TOKEN_HERE/${HF_TOKEN:-none}/g" \
    $CONTAINER_YAML > container-instance-configured.yaml

# Deploy container
echo "🚢 Deploying container instance..."
az container create \
  --resource-group $RESOURCE_GROUP \
  --file container-instance-configured.yaml

# Get FQDN
FQDN=$(az container show \
  --resource-group $RESOURCE_GROUP \
  --name huggingface-llm \
  --query ipAddress.fqdn \
  --output tsv)

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🌐 Your LLM API is available at:"
echo "   http://$FQDN"
echo ""
echo "🔍 Health check:"
echo "   curl http://$FQDN/health"
echo ""
echo "📝 Generate text:"
echo "   curl -X POST http://$FQDN/generate \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"inputs\": \"Hello, how are you?\", \"parameters\": {\"max_new_tokens\": 50}}'"
echo ""
echo "📊 View logs:"
echo "   az container logs --resource-group $RESOURCE_GROUP --name huggingface-llm --follow"
echo ""

# Clean up temp file
rm -f container-instance-configured.yaml
