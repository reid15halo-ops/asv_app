Migration: Export DB catches to per-user/year JSON files

This script reads all rows from the `catch` table and writes them into per-user per-year JSON files in the Supabase Storage bucket `catch_photos` as `users/<memberId>/catches-<year>.json`.

Usage (locally or on a trusted machine):

1. Install dependencies:

```bash
cd tools/migration
npm ci
```

2. Set environment variables:

```bash
export SUPABASE_URL=your_supabase_url
export SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

3. Options and run:

- Dry run (report only, no writes):

```bash
DRY_RUN=1 node index.js
```

- Batching (process in batches of N groups) and pause between batches:

```bash
BATCH_SIZE=50 PAUSE_MS=500 node index.js
```

- Normal run:

```bash
node index.js
```

Notes & Safety:
- This script uses the Supabase service role key. Keep it secret.
- It merges with any existing per-user/year JSON files and performs deduplication by `id` (items with the same `id` keep the latest record from the DB). Items without `id` are appended.
- Please backup your storage if you want to retain previous versions.
