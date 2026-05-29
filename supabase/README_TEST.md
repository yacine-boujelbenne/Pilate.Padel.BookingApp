# Test harness for push / follow notifications

Use the PowerShell helper to invoke the deployed `send-push-notification` function with sample payloads.

Examples (from repo root):

```powershell
# ensure SUPABASE_PROJECT_REF is set for your project (or pass -ProjectRef)
# e.g. $env:SUPABASE_PROJECT_REF = "<PROJECT_REF>"

# Invoke default sample (coach_session_assigned)
.\supabase\invoke_follow_event.ps1

# Invoke a specific payload file
.\supabase\invoke_follow_event.ps1 -Payload "supabase/test_payloads/session_spot_opened.json"
```

If you see delivery results, check Mailtrap for emails and the app for in-app notifications.
