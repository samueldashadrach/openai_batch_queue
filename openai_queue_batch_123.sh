#!/bin/bash

# OpenAI 100 GB file storage limit
#  => if you have more than 100 GB of batches, group 50 batches into megabatch to process them
# make sure OPENAI_API_KEY is set in env, using "source" command
# usage: ./scriptname.sh <data dir>

SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"
DATA_DIR="$1"
megabatch_size=50 # use 50 if each batchembed file is ~1 GB
daily_size=10000 #350 # recommended: a multiple of megabatch_size. use 350 assuming tier 5 (4B tokens/day), 10M tokens/batch

declare -i count=0
mkdir -p "$DATA_DIR/logs"
for INPUT_FILEPATH in "$DATA_DIR"/batches2048/*
do
	[ -f "$INPUT_FILEPATH" ] || continue # skip non-files
	readlink -f "$INPUT_FILEPATH" | jq -R -c '{input_filepath: .}' >> "$DATA_DIR/logs/log_$((count/megabatch_size))_0.jsonl"
	if (( count % megabatch_size == megabatch_size - 1 ))
	then
		"$SCRIPTS_DIR"/openai_queue_batch_1.sh "$DATA_DIR/logs/log_$((count/megabatch_size))_0.jsonl" "$DATA_DIR/logs/log_$((count/megabatch_size))_1.jsonl" "$DATA_DIR/batches2048"
		"$SCRIPTS_DIR"/openai_queue_batch_2.sh "$DATA_DIR/logs/log_$((count/megabatch_size))_1.jsonl" "$DATA_DIR/logs/log_$((count/megabatch_size))_2.jsonl"
		"$SCRIPTS_DIR"/openai_queue_batch_3.sh "$DATA_DIR/logs/log_$((count/megabatch_size))_2.jsonl" "$DATA_DIR/logs/log_$((count/megabatch_size))_3.jsonl" "$DATA_DIR/batchembeds2048" delete
	fi
	if (( count == daily_size - 1 ))
	then
		date -Is
		echo "Sleeping 1 day" # During this sleep is when you should move the previous batchembeds2048 files out of the disk, if disk is getting filled
		sleep 1d
	fi
	count=$((count + 1))
done

# final megabatch may be less than megabatch_size
if (( count > 0 && count % megabatch_size != 0 ))
then
	"$SCRIPTS_DIR"/openai_queue_batch_1.sh "$DATA_DIR/logs/log_$((count/megabatch_size))_0.jsonl" "$DATA_DIR/logs/log_$((count/megabatch_size))_1.jsonl" "$DATA_DIR/batches2048"
	"$SCRIPTS_DIR"/openai_queue_batch_2.sh "$DATA_DIR/logs/log_$((count/megabatch_size))_1.jsonl" "$DATA_DIR/logs/log_$((count/megabatch_size))_2.jsonl"
	"$SCRIPTS_DIR"/openai_queue_batch_3.sh "$DATA_DIR/logs/log_$((count/megabatch_size))_2.jsonl" "$DATA_DIR/logs/log_$((count/megabatch_size))_3.jsonl" "$DATA_DIR/batchembeds2048" delete
fi
