#!/bin/bash

# cd DISK_WITH_ENOUGH_STORAGE
# vi all_tokens.sh
# source all_tokens.sh && sudo apt update && sudo apt upgrade -y && sudo apt install jq uuid-runtime parallel -y && git clone https://$GH_TOKEN@github.com/samueldashadrach/epub-llm-search.git

# $DATA_DIR/batches should contain batches

# For large datasets:
#  - IMPORTANT: OpenAI has 100 GB file storage limit. Don't upload large dataset all at once.
#  - consider running each step individually and counting vectors processed successfully on each step
#  - DATA_DIR must be on a disk with sufficient storage. batchembeds, batchembeds2048 files are BIG (>1 GB possible).

SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"
DATA_DIR="$1"
PINECONE_INDEX_HOST="$2"

"$SCRIPTS_DIR"/openai_batch2048.sh "$DATA_DIR/batches" "$DATA_DIR/batches2048" "$DATA_DIR/batchmaps2048"
"$SCRIPTS_DIR"/openai_queue_batch_123.sh "$DATA_DIR"
"$SCRIPTS_DIR"/openai_unbatch2048.sh "$DATA_DIR/batchembeds2048" "$DATA_DIR/batchmaps2048" "$DATA_DIR/batchembeds"
"$SCRIPTS_DIR"/pinecone_upsert.sh "$DATA_DIR/batchembeds" easy "$PINECONE_INDEX_HOST"
