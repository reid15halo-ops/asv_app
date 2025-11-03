Annual export tool

This small Node script aggregates per-user/year JSON catch files from Supabase Storage, converts them to CSVs, zips everything and emails it to a list of recipients via SendGrid.

Required repository secrets (GitHub):
- SUPABASE_URL — your Supabase project URL
- SUPABASE_SERVICE_ROLE_KEY — service role key (needed to read storage objects broadly)
- SENDGRID_API_KEY — SendGrid API key used to send email
- SENDER_EMAIL — verified sender email for SendGrid
- EXPORT_EDGE_URL — URL to the Supabase Edge Function used to authorize the export
- EXPORT_EDGE_SECRET — pre-shared secret passed to the Edge Function via X-EXPORT-SECRET header

By default the workflow emails the following addresses:
 - asvgrossostheimjugend@gmail.com
 - reid15_halo@yahoo.de
 - erwinglawion@aol.com

How to test locally:
1. Install dependencies in tools/annual-export: `npm ci`
2. Set environment variables (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SENDGRID_API_KEY, SENDER_EMAIL)
3. Run: `node index.js`

You can also trigger the GitHub Actions workflow manually from the Actions tab (workflow_dispatch).

Security note: The exporter uses the Supabase service role key; protect it carefully. The workflow now first calls a Supabase Edge Function (EXPORT_EDGE_URL) with a pre-shared secret (EXPORT_EDGE_SECRET) to authorize the job. That Edge Function should validate admin rights and only then allow the CI to run the exporter. This reduces risk of unauthorized runs.
