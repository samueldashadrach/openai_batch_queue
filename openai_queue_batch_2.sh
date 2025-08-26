#!/bin/bash

# usage: ./script.sh <read logfile> <write logfile>
# refer to logfile format in script 1
# Must be filled in read logfile: input_filepath, input_file_id

function checkAllBatches() {
  # Pagination settings
  local limit=100
  local after=""
  local has_more=true

  while [ "$has_more" = "true" ]; do
    # Build URL with optional "after" for pagination
    local url="https://api.openai.com/v1/batches?limit=$limit"
    if [ -n "$after" ]; then
      url="$url&after=$after"
    fi
    # Retrieve the current page of batches
    local response
    response=$(curl --retry 10 -s "$url" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -H "Content-Type: application/json")
    # If curl returned no data or an error, handle it
    if [ -z "$response" ]; then
      return 1
    fi
    
    # Check for any batch whose status is not completed/failed/cancelled
    local invalid_ids
    invalid_ids=$(echo "$response" | jq -r \
      '.data[]
       | select(.status != "completed"
                and .status != "failed"
                and .status != "cancelled")
       | .id')
    # echo "$response" | jq -r '.data[] | "\(.id) => \(.status)"'  
    # echo "$invalid_ids"
    if [ -n "$invalid_ids" ]; then
      return 1
    fi
    # Prepare for next page if any
    has_more=$(echo "$response" | jq -r '.has_more // "false"')
    if [ "$has_more" = "true" ]; then
      after=$(echo "$response" | jq -r '.last_id')
    fi
  done

  return 0
}

while IFS='' read -r line
do
  INPUT_FILE_ID=$(echo "$line" | jq -r '.input_file_id') &&\
	BATCH_ID=$(curl --retry 10 "https://api.openai.com/v1/batches" -H "Authorization: Bearer $OPENAI_API_KEY"\
     -H "Content-Type: application/json"\
     -d '{"input_file_id":"'"$INPUT_FILE_ID"'","endpoint":"/v1/embeddings","completion_window":"24h"}' | jq -r .id) &&\
  echo "$line" | jq -c --arg batch_id "$BATCH_ID" '. + {batch_id: $batch_id}' >> "$2"
done < "$1"

while ! checkAllBatches
do
  echo "$(date -Is): sleeping 1 minute"
  sleep 1m
done
