import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (_req) => {
    const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Email confirmed</title>
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
          max-width: 420px;
          width: 100%;
          text-align: center;
          box-shadow: 0 2px 12px rgba(0,0,0,0.08);
        }
        h2 { font-size: 20px; margin-bottom: 10px; }
        p { color: #7A9082; font-size: 14px; margin-bottom: 18px; line-height: 1.5; }
        .btn {
          display: inline-block;
          padding: 14px 28px;
          background: #5A6E62;
          color: #fff;
          text-decoration: none;
          border-radius: 12px;
          font-size: 16px;
          font-weight: 600;
        }
      </style>
    </head>
    <body>
      <div class="card">
        <h2>Your email is confirmed</h2>
        <p>You can now return to the app and sign in with your new account.</p>
        <a class="btn" href="/login">Go to login</a>
      </div>
    </body>
    </html>
  `

    return new Response(html, {
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
    })
})
