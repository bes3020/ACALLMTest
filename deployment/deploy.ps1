# PowerShell deployment script

$ErrorActionPreference = "Stop"

# Configuration
$RESOURCE_GROUP = "rg-huggingface-llm"
$LOCATION = "eastus"
$STORAGE_ACCOUNT = "hfmodelstorage" + (Get-Random -Maximum 99999)
$SHARE_NAME = "modeldata"
$CONTAINER_YAML = "container-instance.yaml"

Write-Host "🚀 Deploying Hugging Face LLM to Azure Container Instances" -ForegroundColor Green
Write-Host ""

# Get Hugging Face token
$HF_TOKEN = Read-Host "Enter your Hugging Face token (or press Enter to skip)"

# Create resource group
Write-Host "📦 Creating resource group..." -ForegroundColor Cyan
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
Write-Host "💾 Creating storage account for model cache..." -ForegroundColor Cyan
az storage account create `
  --name $STORAGE_ACCOUNT `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION `
  --sku Standard_LRS `
  --kind StorageV2

# Get storage key
$STORAGE_KEY = az storage account keys list `
  --resource-group $RESOURCE_GROUP `
  --account-name $STORAGE_ACCOUNT `
  --query "[0].value" `
  --output tsv

# Create file share
Write-Host "📁 Creating file share..." -ForegroundColor Cyan
az storage share create `
  --name $SHARE_NAME `
  --account-name $STORAGE_ACCOUNT `
  --account-key $STORAGE_KEY

# Update YAML
Write-Host "📝 Updating deployment configuration..." -ForegroundColor Cyan
$yaml = Get-Content $CONTAINER_YAML -Raw
$yaml = $yaml -replace 'YOUR_STORAGE_ACCOUNT_NAME', $STORAGE_ACCOUNT
$yaml = $yaml -replace 'YOUR_STORAGE_ACCOUNT_KEY', $STORAGE_KEY
$yaml = $yaml -replace 'YOUR_HF_TOKEN_HERE', $(if ($HF_TOKEN) { $HF_TOKEN } else { 'none' })
$yaml | Set-Content "container-instance-configured.yaml"

# Deploy container
Write-Host "🚢 Deploying container instance..." -ForegroundColor Cyan
az container create `
  --resource-group $RESOURCE_GROUP `
  --file container-instance-configured.yaml

# Get FQDN
$FQDN = az container show `
  --resource-group $RESOURCE_GROUP `
  --name huggingface-llm `
  --query ipAddress.fqdn `
  --output tsv

Write-Host ""
Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Your LLM API is available at:" -ForegroundColor Green
Write-Host "   http://$FQDN" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔍 Health check:" -ForegroundColor Cyan
Write-Host "   curl http://$FQDN/health"
Write-Host ""
Write-Host "📝 Generate text:" -ForegroundColor Cyan
Write-Host "   curl -X POST http://$FQDN/generate ``"
Write-Host "     -H 'Content-Type: application/json' ``"
Write-Host "     -d '{`"inputs`": `"Hello, how are you?`", `"parameters`": {`"max_new_tokens`": 50}}'"
Write-Host ""
Write-Host "📊 View logs:" -ForegroundColor Cyan
Write-Host "   az container logs --resource-group $RESOURCE_GROUP --name huggingface-llm --follow"
Write-Host ""

# Clean up
Remove-Item "container-instance-configured.yaml" -ErrorAction SilentlyContinue
