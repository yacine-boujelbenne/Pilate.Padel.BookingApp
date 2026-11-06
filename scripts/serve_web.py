#!/usr/bin/env python3
"""Serve compiled Flutter artifacts, with SPA routing and no project-file access."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parent.parent / 'build' / 'web'


class AppHandler(SimpleHTTPRequestHandler):
    def send_head(self):
        root = Path(self.directory).resolve()
        target = Path(self.translate_path(self.path)).resolve()
        if not target.is_relative_to(root):
            self.send_error(404)
            return None
        relative = target.relative_to(root)
        if relative.as_posix() != 'assets/.env.client' and any(
            part.startswith('.') for part in relative.parts
        ):
            self.send_error(404)
            return None
        if target.is_dir() and not (target / 'index.html').is_file():
            self.send_error(404)
            return None
        if not target.exists() and '.' not in target.name:
            previous = self.path
            self.path = '/index.html'
            try:
                return super().send_head()
            finally:
                self.path = previous
        return super().send_head()

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

    def log_request(self, code='-', size='-'):
        # Recovery callbacks may include a temporary auth code in the query string.
        print(f'{self.command} {urlsplit(self.path).path} {code}', flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8080)
    args = parser.parse_args()
    if not (ROOT / 'index.html').is_file():
        parser.error('Build the web app before starting the preview.')
    server = ThreadingHTTPServer(('127.0.0.1', args.port), partial(AppHandler, directory=str(ROOT)))
    print(f'Fléx preview: http://127.0.0.1:{args.port}', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == '__main__':
    main()
