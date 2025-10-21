# Hugging Face LLM on Azure Container Instances

Deploy any Hugging Face text generation model to Azure using a simple YAML configuration.

## What This Does

Uses [Hugging Face Text Generation Inference (TGI)](https://github.com/huggingface/text-generation-inference) to automatically:
- Download and serve any Hugging Face model
- Provide OpenAI-compatible API endpoints
- Cache models in Azure File Share for faster restarts

## Quick Start

### 1. Prerequisites
- Azure CLI: `az login`
- Hugging Face token: https://huggingface.co/settings/tokens (optional for public models)

### 2. Deploy

```bash
cd deployment
./deploy.sh
```

That's it! The script will:
1. Create a storage account for model caching
2. Deploy the TGI container
3. Output your API URL

### 3. Use Your LLM

```bash
# Health check
curl http://your-url.eastus.azurecontainer.io/health

# Generate text
curl -X POST http://your-url.eastus.azurecontainer.io/generate \
  -H "Content-Type: application/json" \
  -d '{
    "inputs": "What is the capital of France?",
    "parameters": {
      "max_new_tokens": 50,
      "temperature": 0.7
    }
  }'
```

## Customize the Deployment

Edit `deployment/container-instance.yaml`:

### Change Model

```yaml
- name: MODEL_ID
  value: 'microsoft/phi-2'  # or any HuggingFace model
```

Popular models:
- **Small** (2 CPU, 8GB): `TinyLlama/TinyLlama-1.1B-Chat-v1.0`, `google/flan-t5-base`
- **Medium** (4 CPU, 16GB): `microsoft/phi-2`, `mistralai/Mistral-7B-Instruct-v0.1`
- **Large** (GPU required): `meta-llama/Llama-2-13b-hf`

### Adjust Resources

```yaml
resources:
  requests:
    memoryInGB: 16
    cpu: 4
  limits:
    memoryInGB: 16
    cpu: 4
```

### Add Your Hugging Face Token

```yaml
- name: HUGGING_FACE_HUB_TOKEN
  secureValue: 'hf_your_token_here'
```

Required for:
- Private models
- Gated models (Llama, etc.)
- Avoiding rate limits

## Manual Deployment

If you prefer manual control:

```bash
# 1. Create resource group
az group create --name rg-huggingface-llm --location eastus

# 2. Create storage account
az storage account create \
  --name hfmodelstorage123 \
  --resource-group rg-huggingface-llm \
  --sku Standard_LRS

# 3. Get storage key
STORAGE_KEY=$(az storage account keys list \
  --resource-group rg-huggingface-llm \
  --account-name hfmodelstorage123 \
  --query "[0].value" -o tsv)

# 4. Create file share
az storage share create \
  --name modeldata \
  --account-name hfmodelstorage123 \
  --account-key $STORAGE_KEY

# 5. Update YAML with storage account name and key

# 6. Deploy
az container create \
  --resource-group rg-huggingface-llm \
  --file deployment/container-instance.yaml
```

## API Endpoints

### Generate Text
```bash
POST /generate
{
  "inputs": "Your prompt",
  "parameters": {
    "max_new_tokens": 100,
    "temperature": 0.7,
    "top_p": 0.9
  }
}
```

### Stream Generation
```bash
POST /generate_stream
```

### Health Check
```bash
GET /health
```

### Metrics
```bash
GET /metrics
```

## Monitoring

```bash
# View logs
az container logs \
  --resource-group rg-huggingface-llm \
  --name huggingface-llm \
  --follow

# Check status
az container show \
  --resource-group rg-huggingface-llm \
  --name huggingface-llm \
  --query instanceView.state
```

## Cost Optimization

- **Model caching**: Azure File Share persists downloaded models (~$0.12/GB/month)
- **Right-size resources**: Start with 2 CPU / 8GB, scale up if needed
- **Stop when not in use**: Delete container, keep storage for faster restart

**Estimated costs:**
- Small model (2 CPU, 8GB): ~$60-80/month if running 24/7
- Storage: ~$1-5/month for model cache
- **Tip**: Delete container when not in use, redeploy in seconds

## Troubleshooting

### Container keeps restarting
- Model too large for allocated memory
- Increase `memoryInGB` in YAML
- Check logs: `az container logs --name huggingface-llm -g rg-huggingface-llm`

### Download fails
- Invalid Hugging Face token
- Model requires authentication
- Check model exists: https://huggingface.co/[MODEL_ID]

### Slow performance
- Model too large for CPU
- Consider GPU-enabled VMs
- Or use smaller/quantized model

## Clean Up

```bash
# Delete everything
az group delete --name rg-huggingface-llm --yes

# Or just delete container (keep storage for faster restart)
az container delete \
  --resource-group rg-huggingface-llm \
  --name huggingface-llm \
  --yes
```

## Additional Resources

- [TGI Documentation](https://huggingface.co/docs/text-generation-inference)
- [Azure Container Instances](https://learn.microsoft.com/en-us/azure/container-instances/)
- [Hugging Face Models](https://huggingface.co/models?pipeline_tag=text-generation)

## License

MIT
