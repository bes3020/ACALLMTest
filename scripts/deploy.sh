#!/bin/bash

set -e

# Configuration
RESOURCE_GROUP="rg-huggingface-llm"
LOCATION="eastus"
DEPLOYMENT_NAME="huggingface-llm-deployment"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Deploying Hugging Face LLM to Azure Container Apps${NC}"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Azure. Logging in...${NC}"
    az login
fi

# Get Hugging Face token
echo -e "${YELLOW}🔑 Hugging Face Token Setup${NC}"
echo "Enter your Hugging Face token (or press Enter to skip for public models):"
read -s HF_TOKEN

# Create resource group if it doesn't exist
echo -e "${GREEN}📦 Creating resource group: $RESOURCE_GROUP${NC}"
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Deploy Bicep template
echo -e "${GREEN}🏗️  Deploying infrastructure...${NC}"

if [ -z "$HF_TOKEN" ]; then
    echo -e "${YELLOW}⚠️  Deploying without Hugging Face token (may hit rate limits)${NC}"
    az deployment group create \
      --name $DEPLOYMENT_NAME \
      --resource-group $RESOURCE_GROUP \
      --template-file ../infrastructure/main.bicep \
      --parameters ../infrastructure/parameters.json \
      --parameters huggingFaceToken=""
else
    az deployment group create \
      --name $DEPLOYMENT_NAME \
      --resource-group $RESOURCE_GROUP \
      --template-file ../infrastructure/main.bicep \
      --parameters ../infrastructure/parameters.json \
      --parameters huggingFaceToken="$HF_TOKEN"
fi

# Get outputs
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""

CONTAINER_APP_URL=$(az deployment group show \
  --name $DEPLOYMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.outputs.containerAppUrl.value \
  --output tsv)

echo -e "${GREEN}🌐 Your LLM API is available at:${NC}"
echo -e "${YELLOW}$CONTAINER_APP_URL${NC}"
echo ""
echo -e "${GREEN}📝 Example usage:${NC}"
echo ""
echo "curl -X POST \"$CONTAINER_APP_URL/generate\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"inputs\": \"What is the capital of France?\", \"parameters\": {\"max_new_tokens\": 50}}'"
echo ""
echo -e "${GREEN}🔍 Health check:${NC}"
echo "curl $CONTAINER_APP_URL/health"
echo ""
echo -e "${GREEN}📊 View logs:${NC}"
echo "az containerapp logs show -n huggingface-llm -g $RESOURCE_GROUP --follow"
