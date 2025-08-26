#!/bin/bash

# HOW TO RUN
#
# sudo apt install jq -y
# git pull && ./openai_batch2048.sh /root/data/batches/ /root/data/batches2048/ /root/data/batchmaps2048/

rm -rf "$2" && mkdir "$2" && rm -rf "$3" && mkdir "$3" && \
for infile in "$1"*
do
	outfile="$2$(basename "$infile")"
	mapfile="$3$(basename "$infile")"
	echo "$infile -> $outfile"
	split "$infile" -l 2048 --filter "$(dirname "$(readlink -f "$0")")/openai_batch2048_helper.sh $outfile $mapfile"
done

# warning: encountering non-utf-8 will discard the entire 2048 chunk
