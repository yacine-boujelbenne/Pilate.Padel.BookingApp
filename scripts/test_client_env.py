import unittest
from prepare_client_env import public_environment


class PublicEnvironmentTests(unittest.TestCase):
    def test_private_tokens_and_smtp_credentials_are_never_exported(self):
        output = public_environment('''SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=test-public-key
API_TOKEN=private-mailtrap-token
MAILTRAP_SMTP_PASSWORD=private-smtp-password
OTHER_SECRET=private-secret
''')
        self.assertIn('SUPABASE_URL=https://example.supabase.co', output)
        self.assertIn('SUPABASE_ANON_KEY=test-public-key', output)
        self.assertNotIn('private-', output)
        self.assertNotIn('API_TOKEN', output)
        self.assertNotIn('SMTP', output)

    def test_quoted_values_and_comments_remain_valid_dotenv(self):
        output = public_environment('''export SUPABASE_URL="https://example.supabase.co" # public
SUPABASE_ANON_KEY='public-key'
''')
        self.assertIn('SUPABASE_URL="https://example.supabase.co" # public', output)
        self.assertIn("SUPABASE_ANON_KEY='public-key'", output)

    def test_missing_empty_or_interpolated_values_fail_without_echoing_secrets(self):
        for value in ['', '""', '# missing', '$PRIVATE_TOKEN', '"unclosed']:
            with self.subTest(value=value), self.assertRaises(ValueError):
                public_environment('SUPABASE_URL=https://example.supabase.co\nSUPABASE_ANON_KEY='+value)
        with self.assertRaises(ValueError):
            public_environment('API_TOKEN=private-token')


if __name__ == '__main__':
    unittest.main()
