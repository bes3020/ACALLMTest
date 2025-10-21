# Test script for the deployed TGI API (PowerShell)
# Usage: .\test-api.ps1 -ApiUrl "https://your-app.azurecontainerapps.io"

param(
    [Parameter(Mandatory=$true)]
    [string]$ApiUrl
)

Write-Host "Testing Hugging Face TGI API at: $ApiUrl" -ForegroundColor Green
Write-Host ""

# Test 1: Health Check
Write-Host "1️⃣  Testing Health Check..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$ApiUrl/health" -Method Get
    $response | ConvertTo-Json
} catch {
    Write-Host "❌ Health check failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 2: Simple Generation
Write-Host "2️⃣  Testing Simple Text Generation..." -ForegroundColor Cyan
$body = @{
    inputs = "What is the capital of France?"
    parameters = @{
        max_new_tokens = 50
        temperature = 0.7
    }
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$ApiUrl/generate" -Method Post -Body $body -ContentType "application/json"
    $response | ConvertTo-Json
} catch {
    Write-Host "❌ Generation failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 3: Creative Generation
Write-Host "3️⃣  Testing Creative Generation..." -ForegroundColor Cyan
$body = @{
    inputs = "Write a haiku about artificial intelligence:"
    parameters = @{
        max_new_tokens = 100
        temperature = 0.9
        top_p = 0.95
    }
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$ApiUrl/generate" -Method Post -Body $body -ContentType "application/json"
    $response | ConvertTo-Json
} catch {
    Write-Host "❌ Generation failed: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "✅ All tests complete!" -ForegroundColor Green
