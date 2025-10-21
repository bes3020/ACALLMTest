#!/bin/bash

# Test script for the deployed TGI API
# Usage: ./test-api.sh <CONTAINER_APP_URL>

if [ -z "$1" ]; then
    echo "Usage: ./test-api.sh <CONTAINER_APP_URL>"
    echo "Example: ./test-api.sh https://huggingface-llm.azurecontainerapps.io"
    exit 1
fi

API_URL=$1

echo "Testing Hugging Face TGI API at: $API_URL"
echo ""

# Test 1: Health Check
echo "1️⃣  Testing Health Check..."
curl -s "$API_URL/health" | jq '.'
echo ""
echo ""

# Test 2: Simple Generation
echo "2️⃣  Testing Simple Text Generation..."
curl -s -X POST "$API_URL/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "inputs": "What is the capital of France?",
    "parameters": {
      "max_new_tokens": 50,
      "temperature": 0.7
    }
  }' | jq '.'
echo ""
echo ""

# Test 3: Creative Generation
echo "3️⃣  Testing Creative Generation..."
curl -s -X POST "$API_URL/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "inputs": "Write a haiku about artificial intelligence:",
    "parameters": {
      "max_new_tokens": 100,
      "temperature": 0.9,
      "top_p": 0.95
    }
  }' | jq '.'
echo ""
echo ""

# Test 4: Streaming (if supported)
echo "4️⃣  Testing Streaming Generation..."
curl -s -X POST "$API_URL/generate_stream" \
  -H "Content-Type: application/json" \
  -d '{
    "inputs": "Once upon a time in a land far away",
    "parameters": {
      "max_new_tokens": 50
    }
  }'
echo ""
echo ""

echo "✅ All tests complete!"
