#!/bin/bash

# usage: ./script.sh <read logfile> <write logfile> <batchembeds2048 (output) dir> <(optional) delete keyword>

# for logfile format refer to script 1
# Must be filled in read logfile: input_filepath, input_file_id, batch_id, output_filepath

mkdir -p "$3"
while IFS='' read -r line
do	
	INPUT_FILEPATH=$(echo "$line" | jq -r '.input_filepath') &&\
	BATCH_ID=$(echo "$line" | jq -r '.batch_id') &&\
	INPUT_FILE_ID=$(echo "$line" | jq -r '.input_file_id') &&\
	RESPONSE=$(curl --retry 10 "https://api.openai.com/v1/batches/$BATCH_ID" \
		-H "Authorization: Bearer $OPENAI_API_KEY" \
		-H "Content-Type: application/json") &&\
	STATUS=$(echo "$RESPONSE" | jq -r '.status') &&\
	if [[ "$STATUS" == "completed" ]]
	then
		OUTPUT_FILE_ID=$(echo "$RESPONSE" | jq -r '.output_file_id') &&\
		OUTPUT_FILEPATH="$(readlink -f "$3")"'/'"$(basename "$INPUT_FILEPATH")" &&\
		curl --retry 10 "https://api.openai.com/v1/files/$OUTPUT_FILE_ID/content" \
			-H "Authorization: Bearer $OPENAI_API_KEY" > "$OUTPUT_FILEPATH" &&\
		echo "$line" | \
		jq -c --arg output_file_id "$OUTPUT_FILE_ID" --arg output_filepath "$OUTPUT_FILEPATH" \
		'. + {output_file_id: $output_file_id, output_filepath: $output_filepath}' >> "$2"

		if [[ "$4" == "delete" ]]
		then
			curl --retry 10 "https://api.openai.com/v1/files/$INPUT_FILE_ID" \
				-X DELETE \
				-H "Authorization: Bearer $OPENAI_API_KEY" && \
			curl --retry 10 "https://api.openai.com/v1/files/$OUTPUT_FILE_ID" \
				-X DELETE \
				-H "Authorization: Bearer $OPENAI_API_KEY"
		fi
	fi
done < "$1"