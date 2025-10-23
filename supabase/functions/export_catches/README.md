Export Catches Edge Function

This function is a skeleton demonstrating how to implement a server-side export endpoint that only admins can call.

Deployment (Supabase Functions):
1. Install supabase cli and login.
2. From the repo root run: `supabase functions deploy export_catches --project-ref <your-ref>`
3. Set env vars for the function (SUPABASE_SERVICE_ROLE_KEY) — prefer to use project secrets.

Notes:
- The example checks `user.user.user_metadata.is_admin`. Adjust admin-checks to your project's auth model (e.g., RLS, role claim, or member table lookup).
- The function currently returns a placeholder response. Replace the placeholder with logic to assemble XLSX/ZIP or trigger an async job that performs the export and emailing.
