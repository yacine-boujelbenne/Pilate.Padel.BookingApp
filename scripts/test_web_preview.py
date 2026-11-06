from functools import partial
from http.server import ThreadingHTTPServer
from pathlib import Path
from tempfile import TemporaryDirectory
from threading import Thread
from urllib.error import HTTPError
from urllib.request import urlopen
import unittest

from serve_web import AppHandler


class WebPreviewTests(unittest.TestCase):
    def test_public_assets_and_spa_routes_work_while_private_files_are_denied(self):
        with TemporaryDirectory() as directory:
            source = Path(directory)
            build = source / 'build'
            (build / 'assets').mkdir(parents=True)
            (source / '.env').write_text('API_TOKEN=private-test-token')
            (build / 'index.html').write_text('Test app')
            (build / 'assets' / '.env.client').write_text('SUPABASE_URL=test-public-value')
            (build / '.env').symlink_to(source / '.env')
            (build / 'leaked-config.txt').symlink_to(source / '.env')
            server = ThreadingHTTPServer(('127.0.0.1', 0), partial(AppHandler, directory=str(build)))
            thread = Thread(target=server.serve_forever, daemon=True)
            thread.start()
            base = f'http://127.0.0.1:{server.server_port}'
            try:
                for path in ['/', '/reset-password']:
                    with urlopen(base+path) as response:
                        self.assertEqual(response.read(), b'Test app')
                with urlopen(base+'/assets/.env.client') as response:
                    self.assertIn(b'SUPABASE_URL', response.read())
                for path in ['/.env', '/.env.smtp', '/assets/.env', '/leaked-config.txt', '/assets/']:
                    with self.subTest(path=path), self.assertRaises(HTTPError) as error:
                        urlopen(base+path)
                    self.assertEqual(error.exception.code, 404)
            finally:
                server.shutdown()
                server.server_close()
                thread.join()


if __name__ == '__main__':
    unittest.main()
