# Quick Start Guide

## Deploy in 5 Minutes

### Step 1: Prerequisites
- Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Get a [Hugging Face Token](https://huggingface.co/settings/tokens)

### Step 2: Deploy

```bash
cd scripts
./deploy.sh
```

When prompted, enter your Hugging Face token.

### Step 3: Test

The deployment script will output your API URL. Test it:

```bash
curl https://your-app.azurecontainerapps.io/health
```

### Step 4: Use

```bash
curl -X POST "https://your-app.azurecontainerapps.io/generate" \
  -H "Content-Type: application/json" \
  -d '{"inputs": "Hello, how are you?"}'
```

## Common Models to Try

### Small (Fast, Low Cost)
```json
"modelId": "google/flan-t5-small"
```

### Medium (Balanced)
```json
"modelId": "microsoft/phi-2"
```

### Large (Best Quality, Requires GPU)
```json
"modelId": "mistralai/Mistral-7B-v0.1"
```

## Change Model

1. Edit `infrastructure/parameters.json`
2. Change `modelId` value
3. Re-run `./deploy.sh`

## Costs

- **Development (scale-to-zero)**: ~$5-10/month
- **Production (always-on small model)**: ~$30-50/month
- **Production (always-on large model with GPU)**: ~$200-500/month

Set `minReplicas: 0` in parameters.json for scale-to-zero.

## Need Help?

See full [README.md](./README.md) for detailed documentation.
