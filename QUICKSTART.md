# Quick Start - 2 Commands

## Deploy

```bash
cd deployment
./deploy.sh
```

Enter your Hugging Face token when prompted (or skip for public models).

## Test

```bash
curl -X POST http://your-url.eastus.azurecontainer.io/generate \
  -H "Content-Type: application/json" \
  -d '{"inputs": "Hello!"}'
```

## Change Model

Edit `deployment/container-instance.yaml`:

```yaml
- name: MODEL_ID
  value: 'microsoft/phi-2'
```

Redeploy:
```bash
./deploy.sh
```

Done! 🎉
