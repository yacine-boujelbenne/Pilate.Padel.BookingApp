#!/usr/bin/env python3
"""Explicit transport check: captures one test message inside Mailtrap Sandbox."""
import json
import re
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
from prepare_mailtrap_hook import ROOT, load_env


def main():
    cfg = load_env(ROOT / '.env.mailtrap-hook')
    if cfg.get('MAILTRAP_MODE') != 'sandbox' or not cfg.get('MAILTRAP_INBOX_ID', '').isdigit():
        raise SystemExit('This check requires Sandbox mode; it never sends real email.')
    token = cfg.get('MAILTRAP_API_TOKEN')
    if not token:
        raise SystemExit('Prepare the server hook secrets first.')
    payload = {
        'from': {'email': cfg['MAILTRAP_FROM_EMAIL'], 'name': 'Fléx'},
        'to': [{'email': 'integration-check@example.test'}],
        'subject': 'Fléx API integration check — Sandbox',
        'text': 'This confirms Mailtrap API transport to your Sandbox. No account was created, no password was changed, and no authentication link was generated.',
        'category': 'Integration Test',
    }
    request = Request('https://sandbox.api.mailtrap.io/api/send/'+cfg['MAILTRAP_INBOX_ID'],
        data=json.dumps(payload).encode(), headers={
            'Authorization': 'Bearer '+token, 'Content-Type': 'application/json',
            'Accept': 'application/json', 'User-Agent': 'FlexAuth-Mailtrap/1.0'})
    try:
        with urlopen(request, timeout=15) as response:
            result = json.load(response)
        if result.get('success') is not True:
            raise SystemExit('Mailtrap did not accept the sandbox test.')
        print('Mailtrap Sandbox API accepted the integration check. No real recipient was contacted.')
    except HTTPError as error:
        try:
            detail = json.loads(error.read())
            detail = str(detail.get('errors') or detail.get('error') or detail.get('message') or 'No provider detail')
            detail = detail.replace(token, '[redacted]')
            detail = re.sub(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}', '[email]', detail)
        except (ValueError, AttributeError):
            detail = 'Non-JSON provider response'
        raise SystemExit('Mailtrap Sandbox API rejected the check: HTTP '+str(error.code)+'; '+detail[:400])
    except (URLError, ValueError):
        raise SystemExit('Mailtrap Sandbox API transport could not be verified.')


if __name__ == '__main__':
    main()
