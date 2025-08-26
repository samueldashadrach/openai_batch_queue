#!/usr/bin/env bash

cat "$1" \
| while IFS= read -r line; do echo "$line" | htmlq -t p; done \
| sed -E 's/[[:space:]]+/ /g' \
| tr -d '\n' \
| fold -w 1000 \
| { cat; printf "\n"; } \
| nl -v0 -i1000 -n rz -w 16 -s $'\t' \
| jq -Rc --arg pfx "$1" '
  split("\t") | {
    custom_id: ($pfx + "#" + .[0]),
    method: "POST",
    url: "/v1/embeddings",
    body: {
      model: "text-embedding-3-small",
      input: .[1]
    }
  }
' \
| split -l 50000 - "$2batch_"