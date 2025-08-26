#!/bin/bash

curl -s https://api.openai.com/v1/batches?limit=100 \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  | jq -r '.data[].id' \
  | xargs -I {} curl -s https://api.openai.com/v1/batches/{}/cancel \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -X POST
