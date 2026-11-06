#!/usr/bin/env python3
"""Export only public Flutter configuration from the local, private .env."""
from pathlib import Path
import re
import sys

PUBLIC_KEYS = ('SUPABASE_URL', 'SUPABASE_ANON_KEY')
ROOT = Path(__file__).resolve().parent.parent


def public_environment(source: str) -> str:
    values = {}
    for line in source.splitlines():
        match = re.fullmatch(r'\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)', line)
        if match and match[1] in PUBLIC_KEYS:
            value = match[2].strip()
            if not value or value.startswith('#'):
                raise ValueError('Public Supabase configuration is incomplete.')
            # Public client values must be self-contained, single-line literals.
            if '$' in value:
                raise ValueError('Use literal public Supabase values, without variable references.')
            if value.startswith(('"', "'")):
                quote = value[0]
                if quote not in value[1:]:
                    raise ValueError('Public Supabase configuration has an unclosed quote.')
                end = value.index(quote, 1)
                if not value[1:end].strip() or value[end+1:].strip() and not value[end+1:].strip().startswith('#'):
                    raise ValueError('Public Supabase configuration is incomplete or malformed.')
            values[match[1]] = value
    if any(key not in values for key in PUBLIC_KEYS):
        raise ValueError('The local .env needs SUPABASE_URL and SUPABASE_ANON_KEY.')
    return '# Generated public app configuration. Do not add private tokens.\n' + ''.join(
        f'{key}={values[key]}\n' for key in PUBLIC_KEYS
    )


def main() -> int:
    destination = ROOT / '.env.client'
    try:
        result = public_environment((ROOT / '.env').read_text())
    except (OSError, ValueError) as error:
        destination.unlink(missing_ok=True)
        print(str(error) if isinstance(error, ValueError) else 'Could not read the local .env.', file=sys.stderr)
        return 1
    destination.write_text(result)
    print('Prepared .env.client with public Supabase configuration only.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
