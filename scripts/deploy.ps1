# PowerShell deployment script for Windows

$ErrorActionPreference = "Stop"

# Configuration
$RESOURCE_GROUP = "rg-huggingface-llm"
$LOCATION = "eastus"
$DEPLOYMENT_NAME = "huggingface-llm-deployment"

Write-Host "🚀 Deploying Hugging Face LLM to Azure Container Apps" -ForegroundColor Green

# Check if Azure CLI is installed
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check if logged in
try {
    az account show | Out-Null
} catch {
    Write-Host "⚠️  Not logged in to Azure. Logging in..." -ForegroundColor Yellow
    az login
}

# Get Hugging Face token
Write-Host "🔑 Hugging Face Token Setup" -ForegroundColor Yellow
$HF_TOKEN = Read-Host "Enter your Hugging Face token (or press Enter to skip for public models)" -AsSecureString
$HF_TOKEN_PLAIN = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($HF_TOKEN)
)

# Create resource group
Write-Host "📦 Creating resource group: $RESOURCE_GROUP" -ForegroundColor Green
az group create `
  --name $RESOURCE_GROUP `
  --location $LOCATION

# Deploy Bicep template
Write-Host "🏗️  Deploying infrastructure..." -ForegroundColor Green

if ([string]::IsNullOrEmpty($HF_TOKEN_PLAIN)) {
    Write-Host "⚠️  Deploying without Hugging Face token (may hit rate limits)" -ForegroundColor Yellow
    az deployment group create `
      --name $DEPLOYMENT_NAME `
      --resource-group $RESOURCE_GROUP `
      --template-file ..\infrastructure\main.bicep `
      --parameters ..\infrastructure\parameters.json `
      --parameters huggingFaceToken=""
} else {
    az deployment group create `
      --name $DEPLOYMENT_NAME `
      --resource-group $RESOURCE_GROUP `
      --template-file ..\infrastructure\main.bicep `
      --parameters ..\infrastructure\parameters.json `
      --parameters huggingFaceToken="$HF_TOKEN_PLAIN"
}

# Get outputs
Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host ""

$CONTAINER_APP_URL = az deployment group show `
  --name $DEPLOYMENT_NAME `
  --resource-group $RESOURCE_GROUP `
  --query properties.outputs.containerAppUrl.value `
  --output tsv

Write-Host "🌐 Your LLM API is available at:" -ForegroundColor Green
Write-Host $CONTAINER_APP_URL -ForegroundColor Yellow
Write-Host ""
Write-Host "📝 Example usage:" -ForegroundColor Green
Write-Host ""
Write-Host "curl -X POST `"$CONTAINER_APP_URL/generate`" ``"
Write-Host "  -H `"Content-Type: application/json`" ``"
Write-Host "  -d '{`"inputs`": `"What is the capital of France?`", `"parameters`": {`"max_new_tokens`": 50}}'"
Write-Host ""
Write-Host "🔍 Health check:" -ForegroundColor Green
Write-Host "curl $CONTAINER_APP_URL/health"
Write-Host ""
Write-Host "📊 View logs:" -ForegroundColor Green
Write-Host "az containerapp logs show -n huggingface-llm -g $RESOURCE_GROUP --follow"
