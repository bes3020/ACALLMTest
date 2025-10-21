# Hugging Face LLM on Azure Container Apps

Deploy any Hugging Face text generation model to Azure Container Apps using Text Generation Inference (TGI).

## Overview

This solution deploys [Hugging Face Text Generation Inference (TGI)](https://github.com/huggingface/text-generation-inference) as an Azure Container App, allowing you to serve any compatible Hugging Face model with:

- Automatic model download from Hugging Face Hub
- OpenAI-compatible API endpoints
- Auto-scaling based on load
- High-performance inference with optimized kernels
- Streaming support
- Health monitoring

## Architecture

```
┌─────────────────────────────────────┐
│   Azure Container App               │
│  ┌──────────────────────────────┐  │
│  │  TGI Container               │  │
│  │  - Downloads HF Model        │  │
│  │  - Serves API on port 80     │  │
│  │  - Auto-scales 1-3 replicas  │  │
│  └──────────────────────────────┘  │
│                                     │
│  Container App Environment          │
│  - Log Analytics Integration        │
│  - Health Monitoring                │
└─────────────────────────────────────┘
```

## Prerequisites

- Azure CLI installed ([Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- Azure subscription
- Hugging Face account and API token ([Get one here](https://huggingface.co/settings/tokens))
  - Required for private models
  - Recommended for public models to avoid rate limits

## Quick Start

### 1. Get a Hugging Face Token

Visit https://huggingface.co/settings/tokens and create a new token with read access.

### 2. Deploy to Azure

**Linux/macOS:**
```bash
cd scripts
chmod +x deploy.sh
./deploy.sh
```

**Windows (PowerShell):**
```powershell
cd scripts
.\deploy.ps1
```

The script will:
1. Log you into Azure (if needed)
2. Prompt for your Hugging Face token
3. Create a resource group
4. Deploy the infrastructure
5. Output the API URL

### 3. Test Your Deployment

Once deployed, test the API:

```bash
# Health check
curl https://your-app.azurecontainerapps.io/health

# Generate text
curl -X POST "https://your-app.azurecontainerapps.io/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "inputs": "What is the capital of France?",
    "parameters": {
      "max_new_tokens": 50,
      "temperature": 0.7,
      "top_p": 0.9
    }
  }'

# Stream text generation
curl -X POST "https://your-app.azurecontainerapps.io/generate_stream" \
  -H "Content-Type: application/json" \
  -d '{
    "inputs": "Write a short poem about clouds",
    "parameters": {
      "max_new_tokens": 100
    }
  }'
```

## Supported Models

TGI supports most causal language models from Hugging Face, including:

### Small Models (2-4GB RAM, 2 CPU cores)
- `google/flan-t5-small` (default)
- `google/flan-t5-base`
- `distilgpt2`

### Medium Models (4-8GB RAM, 2-4 CPU cores)
- `microsoft/phi-2`
- `google/flan-t5-large`
- `EleutherAI/gpt-neo-1.3B`

### Large Models (Requires GPU)
- `meta-llama/Llama-2-7b-hf`
- `mistralai/Mistral-7B-v0.1`
- `tiiuae/falcon-7b`

**Note:** For models >2B parameters, GPU is strongly recommended. Azure Container Apps supports GPU workloads.

## Configuration

### Change the Model

Edit `infrastructure/parameters.json`:

```json
{
  "modelId": {
    "value": "microsoft/phi-2"
  }
}
```

### Adjust Resources

For larger models, increase CPU and memory:

```json
{
  "cpuCore": {
    "value": "4.0"
  },
  "memorySize": {
    "value": "8Gi"
  }
}
```

### Scaling Configuration

Modify min/max replicas:

```json
{
  "minReplicas": {
    "value": 0
  },
  "maxReplicas": {
    "value": 10
  }
}
```

**Note:** Setting `minReplicas: 0` enables scale-to-zero (cost savings when idle).

## API Endpoints

### Generate Text
```
POST /generate
Content-Type: application/json

{
  "inputs": "Your prompt here",
  "parameters": {
    "max_new_tokens": 100,
    "temperature": 0.7,
    "top_p": 0.9,
    "do_sample": true
  }
}
```

### Stream Generation
```
POST /generate_stream
```
Returns server-sent events for streaming responses.

### Health Check
```
GET /health
```

### Metrics
```
GET /metrics
```
Prometheus-compatible metrics.

## Monitoring

### View Logs
```bash
az containerapp logs show \
  -n huggingface-llm \
  -g rg-huggingface-llm \
  --follow
```

### View Metrics
```bash
az monitor metrics list \
  --resource /subscriptions/{subscription-id}/resourceGroups/rg-huggingface-llm/providers/Microsoft.App/containerApps/huggingface-llm \
  --metric Requests
```

## Cost Optimization

1. **Scale to Zero**: Set `minReplicas: 0` for development
2. **Right-size Resources**: Start small and scale up if needed
3. **Use Consumption Plan**: Pay only for actual usage
4. **Model Size**: Smaller models = lower costs

**Estimated Costs:**
- Small model (2 CPU, 4GB): ~$30-50/month (always on)
- Medium model (4 CPU, 8GB): ~$60-100/month (always on)
- Scale-to-zero: Only pay when processing requests

## Troubleshooting

### Model Download Fails
- Ensure Hugging Face token is valid
- Check model exists and is accessible
- Verify network connectivity

### Out of Memory
- Increase `memorySize` parameter
- Use a smaller model
- Consider GPU-enabled Container Apps

### Slow Performance
- Model may be too large for CPU
- Increase CPU cores
- Consider GPU deployment
- Enable TGI quantization (see advanced config)

### Container Won't Start
Check logs:
```bash
az containerapp logs show -n huggingface-llm -g rg-huggingface-llm --tail 100
```

## Advanced Configuration

### Enable Quantization (Smaller Memory Footprint)

Edit `infrastructure/main.bicep` and add to env variables:
```bicep
{
  name: 'QUANTIZE'
  value: 'bitsandbytes'  // or 'gptq'
}
```

### Custom TGI Parameters

Add environment variables in `main.bicep`:
```bicep
{
  name: 'MAX_BATCH_PREFILL_TOKENS'
  value: '4096'
}
{
  name: 'MAX_BATCH_TOTAL_TOKENS'
  value: '8192'
}
```

## Clean Up

Delete all resources:
```bash
az group delete --name rg-huggingface-llm --yes
```

## Additional Resources

- [TGI Documentation](https://huggingface.co/docs/text-generation-inference)
- [Azure Container Apps Docs](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Hugging Face Models](https://huggingface.co/models)

## License

This project is licensed under the MIT License.
