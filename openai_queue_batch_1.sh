#!/bin/bash

# usage: ./script.sh <read logfile> <write logfile> <batches2048 (input) dir>

# logfile format: input_filepath input_file_id batch_id output_file_id output_filepath
# must be filled in read logfile: input_filepath

shopt -s extglob
while IFS='' read -r line
do  
    INPUT_FILEPATH=$(echo "$line" | jq -r '.input_filepath') && \
    INPUT_FILE_ID=$(curl --retry 10 https://api.openai.com/v1/files -H "Authorization: Bearer $OPENAI_API_KEY"\
        -F purpose="batch" -F file="@$INPUT_FILEPATH" | jq -r .id) && \
    echo "$line" | jq -c --arg input_filepath "$(readlink -f "$INPUT_FILEPATH")" \
        --arg input_file_id "$INPUT_FILE_ID" \
        '. + {input_filepath: $input_filepath, input_file_id: $input_file_id}' >> "$2"
done < "$1"
