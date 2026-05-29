param(
  [string]$DatabaseUrl = $env:DATABASE_URL
)

if (-not $DatabaseUrl) {
  Write-Error "Set DATABASE_URL environment variable or pass -DatabaseUrl"
  exit 1
}

$migration = "migrations/20260525_0011_repair_user_settings.sql"
if (-not (Test-Path $migration)) {
  Write-Error "Migration file not found: $migration"
  exit 1
}

Write-Host "Applying migration $migration to database..."

psql $DatabaseUrl -f $migration

if ($LASTEXITCODE -ne 0) {
  Write-Error "psql returned exit code $LASTEXITCODE"
  exit $LASTEXITCODE
}

Write-Host "Migration applied successfully."
