import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (_req) => {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Opening Fl\xe9x Pilates...</title>
      <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          display: flex;
          align-items: center;
          justify-content: center;
          min-height: 100vh;
          background: #EBF3EE;
          color: #2C3A33;
          padding: 24px;
        }
        .card {
          background: #fff;
          border-radius: 16px;
          padding: 32px 24px;
          max-width: 360px;
          width: 100%;
          text-align: center;
          box-shadow: 0 2px 12px rgba(0,0,0,0.08);
        }
        .spinner {
          width: 40px;
          height: 40px;
          border: 3px solid #D4E4DA;
          border-top-color: #5A6E62;
          border-radius: 50%;
          animation: spin 0.8s linear infinite;
          margin: 0 auto 16px;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        h2 { font-size: 18px; margin-bottom: 8px; }
        p { color: #7A9082; font-size: 14px; margin-bottom: 20px; }
        .btn {
          display: inline-block;
          padding: 14px 28px;
          background: #5A6E62;
          color: #fff;
          text-decoration: none;
          border-radius: 12px;
          font-size: 16px;
          font-weight: 600;
          border: none;
          cursor: pointer;
        }
        .hidden { display: none; }
        .error { color: #A03030; font-size: 14px; margin-top: 12px; }
      </style>
    </head>
    <body>
      <div class="card">
        <div id="loading">
          <div class="spinner"></div>
          <h2>Opening Fl\xe9x Pilates...</h2>
          <p>If the app doesn't open automatically, tap the button below.</p>
        </div>
        <div id="fallback" class="hidden">
          <a id="openLink" class="btn" href="flexpilates://auth/reset-password">Open in app</a>
          <p class="error hidden" id="errorMsg"></p>
        </div>
      </div>
      <script>
        (function() {
          var hash = window.location.hash.substring(1);
          var base = 'flexpilates://auth/reset-password';
          var url = hash ? base + '#' + hash : base;

          document.getElementById('openLink').href = url;

          setTimeout(function() {
            window.location.href = url;
          }, 300);

          setTimeout(function() {
            document.getElementById('loading').classList.add('hidden');
            document.getElementById('fallback').classList.remove('hidden');
          }, 3000);
        })();
      </script>
    </body>
    </html>
  `

  return new Response(html, {
    headers: { 'Content-Type': 'text/html; charset=utf-8' },
  })
})
