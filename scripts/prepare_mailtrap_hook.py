#!/usr/bin/env python3
"""Prepare private server secrets for the Supabase Mailtrap API hook."""
import argparse
import base64
import json
from pathlib import Path
import secrets
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent.parent


def load_env(path):
    values = {}
    if not path.exists():
        return values
    for line in path.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            key, value = line.split('=', 1)
            value = value.strip()
            values[key.strip()] = json.loads(value) if value.startswith('"') else value.strip("'")
    return values


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--mode', choices=['sandbox', 'live'], default='sandbox')
    parser.add_argument('--from-email')
    args = parser.parse_args()
    local = load_env(ROOT / '.env')
    token = local.get('MAILTRAP_API_TOKEN') or local.get('API_TOKEN')
    if not token:
        parser.error('Add the Mailtrap API token to your local .env.')
    sender = args.from_email or local.get('MAILTRAP_FROM_EMAIL')
    if args.mode == 'live' and not sender:
        parser.error('Live mode requires --from-email with a sender permitted by Mailtrap.')
    destination = ROOT / '.env.mailtrap-hook'
    previous = load_env(destination)
    values = {
        'MAILTRAP_API_TOKEN': token,
        'MAILTRAP_MODE': args.mode,
        'MAILTRAP_FROM_EMAIL': sender or 'hello@demomailtrap.co',
        'SEND_EMAIL_HOOK_SECRET': previous.get('SEND_EMAIL_HOOK_SECRET') or
            'v1,whsec_'+base64.b64encode(secrets.token_bytes(32)).decode(),
    }
    if args.mode == 'sandbox':
        inbox = local.get('MAILTRAP_INBOX_ID')
        if not inbox:
            def get(path):
                request = Request('https://mailtrap.io/api'+path,
                    headers={'Authorization': 'Bearer '+token, 'Accept': 'application/json'})
                with urlopen(request, timeout=15) as response:
                    return json.load(response)
            try:
                accounts = get('/accounts')
                inboxes = [item for account in accounts
                    for item in get('/accounts/'+str(account['id'])+'/inboxes')]
            except (HTTPError, URLError, ValueError):
                parser.error('Could not retrieve sandbox metadata. Check token access or set MAILTRAP_INBOX_ID locally.')
            if len(inboxes) != 1:
                parser.error('Set MAILTRAP_INBOX_ID in .env to select the intended sandbox.')
            inbox = str(inboxes[0]['id'])
        if not inbox.isdigit():
            parser.error('MAILTRAP_INBOX_ID must be a numeric sandbox ID.')
        values['MAILTRAP_INBOX_ID'] = inbox
    destination.write_text('# Private Supabase Edge Function secrets. Never bundle or commit this file.\n'+
        ''.join(key+'='+json.dumps(value)+'\n' for key, value in values.items()))
    destination.chmod(0o600)
    print('Prepared ignored .env.mailtrap-hook for '+args.mode+' delivery. No secret values printed.')


if __name__ == '__main__':
    main()
