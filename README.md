2025-08-26

# README

Disclaimer
 - I don't use this repo myself. The repo I use is much more chaotic. I wanted to publish a sanitised repo for public use. I won't update this much.

Use OpenAI Batch API for embeddings to process a large amount of plaintext, while following all their rate limits.

#### How to run

use `openai_gen.sh` to chunk the plaintext and convert to openai format.

use `orchestrate.sh` to merge 2048 strings per request, upload the files, start batches, log openai queue as it processes, download outputs, unmerge 2048 strings per request.

#### Approach used

Rate limits OpenAI enforces for embeddings batch API
 - 100 MB max per file
 - 50k requests max per file
 - 1M requests in queue at a time
 - 4B tokens/day (assume usage tier 5)
 - 100 GB max in file storage at a time

Solution
 - Put 2048 input strings into a single "request" to bypass the 1M requests at time. (This is not documented, and took me a long time to figure out.)
 - Put 50k input strings at a time, to stay within 100 MB per file limit.
 - Queue 50 input files at a time, to stay within 100 GB total file limit. Remember output is bigger than input, for instance each batch embeddings file exceeds 1 GB
 - Delete 50 output files after downloading them, to stay within 100 GB total file limit.
 - If 350 files processed, pause the script until next day, to stay within 4B tokens/day limit.

Technical
 - Use bash and perl everywhere. Using Python or JS or similar risks causing out-of-memory when dataset is large.
 - Use bash pipelines to process everything to avoid making lots of writes to disk and hitting disk I/O limit.
 - Use parallel to easily scale up or down depending on number of cores on your machine.
