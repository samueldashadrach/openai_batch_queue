#!/bin/bash

curl -s https://api.openai.com/v1/files \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  | jq -r '.data[].id' \
  | xargs -I {} curl -s -X DELETE https://api.openai.com/v1/files/{} \
    -H "Authorization: Bearer $OPENAI_API_KEY"
    