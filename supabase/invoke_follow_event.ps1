param(
  [string]$Payload = "supabase/test_payloads/coach_session_assigned.json",
  [string]$ProjectRef = $env:SUPABASE_PROJECT_REF
)

if (-not $ProjectRef) {
  Write-Error "Set SUPABASE_PROJECT_REF environment variable or pass -ProjectRef"
  exit 1
}

if (-not (Test-Path $Payload)) {
  Write-Error "Payload file not found: $Payload"
  exit 1
}

$body = Get-Content $Payload -Raw

# Prefer the bundled supabase CLI if present
$supabaseCliPath = Join-Path $PSScriptRoot "..\.tools\supabase\supabase.exe"
if (Test-Path $supabaseCliPath) {
  $exe = $supabaseCliPath
} else {
  $exe = "supabase"
}

$arguments = @(
  'functions',
  'invoke',
  'send-push-notification',
  '--project-ref',
  $ProjectRef,
  '--body',
  $body,
  '--watch'
)

Start-Process -FilePath $exe -ArgumentList $arguments -NoNewWindow -Wait
