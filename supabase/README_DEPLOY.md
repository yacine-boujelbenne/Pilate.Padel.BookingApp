# Supabase deployment helper

This folder contains helper scripts to deploy the updated edge function and apply the database migration included in this repo.

Prerequisites
- `supabase` CLI installed and authenticated (`supabase login`).
- `psql` available for applying SQL migrations (or use your preferred DB client).
- Set `SUPABASE_PROJECT_REF` (or pass `-ProjectRef`) and `DATABASE_URL` (or pass `-DatabaseUrl`) when running the scripts.

Apply migration (PowerShell)
```powershell
.\apply_migration.ps1 -DatabaseUrl $env:DATABASE_URL
```

Deploy function and set secrets (PowerShell)
```powershell
# ensure MAILTRAP_* and FCM_* env vars are set
.\deploy_functions.ps1 -ProjectRef $env:SUPABASE_PROJECT_REF
```

Notes
- Do NOT paste secrets into chat. Use environment variables or CI secret stores.
- If the project is inaccessible or unhealthy, check the Supabase project dashboard and your network access.
