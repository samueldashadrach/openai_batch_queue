#!/bin/bash

# usage: ./script.sh outfile mapfile
# likely used in split --filter

# end script if any error. this script's error handling is not good. partial file write is possible.
set -eo pipefail && \
MERGED_UUID="$(uuidgen)" && \
tee >( 
    # First pipeline: Extract custom_ids and create mapping JSONL
    jq -s -c --arg uuid "$MERGED_UUID" '{uuid: $uuid, custom_ids: map(.custom_id)}' >> "$2"
) | 
# Second pipeline: Create merged JSON object
jq -s -c --arg custom_id "$MERGED_UUID" '{
    body: {
        input: map(.body.input),
        model: "text-embedding-3-small"
    },
    url: "/v1/embeddings",
    method: "POST",
    custom_id: $custom_id
}' >> "$1"
