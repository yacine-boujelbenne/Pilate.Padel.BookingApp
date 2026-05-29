param(
  [string]$ProjectRef = $env:SUPABASE_PROJECT_REF
)

if (-not $ProjectRef) {
  Write-Error "Set SUPABASE_PROJECT_REF environment variable or pass -ProjectRef"
  exit 1
}

Write-Host "Deploying function send-push-notification to project $ProjectRef"

supabase functions deploy send-push-notification --project-ref $ProjectRef

Write-Host "Setting secrets from environment (if present)"
supabase secrets set \
  MAILTRAP_API_TOKEN=$env:MAILTRAP_API_TOKEN \
  MAILTRAP_FROM_EMAIL=$env:MAILTRAP_FROM_EMAIL \
  MAILTRAP_FROM_NAME=$env:MAILTRAP_FROM_NAME \
  MAILTRAP_SMTP_HOST=$env:MAILTRAP_SMTP_HOST \
  MAILTRAP_SMTP_USER=$env:MAILTRAP_SMTP_USER \
  MAILTRAP_SMTP_PASS=$env:MAILTRAP_SMTP_PASS \
  FCM_SERVICE_ACCOUNT_BASE64=$env:FCM_SERVICE_ACCOUNT_BASE64 \
  --project-ref $ProjectRef

Write-Host "Deployment complete. Use 'supabase functions list --project-ref $ProjectRef' to verify."
