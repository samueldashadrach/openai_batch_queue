#!/bin/bash

# usage: ./script.sh <batchembeds2048 (input) dir> <maps (input) dir> <batchembeds (output) dir>

# 1) Build a lookup object keyed by .uuid with value = .custom_ids
#    from batchmaps/batch_1.jsonl
# 2) For each line of batchembeds/batch_1.jsonl, look up the matching array
#    $maps[.custom_id], then zip those custom_ids onto the .response.body.data
#    array by index.  Finally, output each data item with its new "custom_id"
#    as a single line of JSON (JSONL).

for mapfile in "$2"*
do
  batchembed2048file="$1$(basename "$mapfile")"
  batchembedfile="$3$(basename "$mapfile")"
  jq -s 'map({ key: .uuid, value: .custom_ids }) | from_entries' "$mapfile" > "$3temp.json"

  while IFS= read -r line || [ -n "$line" ]
  do
    echo "$line" | \
    jq -c --slurpfile maps "$3temp.json" '
      . as $embeds
      | $embeds.response.body.data
      | to_entries
      | map(.value + { custom_id: $maps[0][$embeds.custom_id][.key | tonumber] })
      | .[]
    '
  done < "$batchembed2048file" >> "$batchembedfile"
  echo "$batchembed2048file -> $batchembedfile"
done

rm -rf "$3temp.json"