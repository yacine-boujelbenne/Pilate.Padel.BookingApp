declare const Deno: {
  env: {
    get(key: string): string | undefined;
  };
  serve(handler: (req: Request) => Response | Promise<Response>): void;
};

interface ChatMessage {
  role: string;
  content: string | { type: string;[key: string]: unknown };
}

interface ChatCompletionRequest {
  messages: ChatMessage[];
  max_tokens?: number;
  temperature?: number;
}

Deno.serve(async (req: Request) => {
  const origin = req.headers.get('origin') || '*';
  const requestedHeaders = req.headers.get('access-control-request-headers');
  const allowHeaders = requestedHeaders || 'Content-Type, Authorization, apikey, x-client-info';
  const corsHeaders: Record<string, string> = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "POST, OPTIONS, GET",
    "Access-Control-Allow-Headers": allowHeaders,
    "Access-Control-Allow-Credentials": "true",
    "Vary": "Origin",
  };

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: corsHeaders,
    });
  }

  try {
    const body = await req.json() as ChatCompletionRequest;
    const apiKey = Deno.env.get("GROQ_API_KEY");

    if (!apiKey) {
      return new Response(
        JSON.stringify({
          error: "Groq API key not configured. Set GROQ_API_KEY environment variable."
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    for (const msg of body.messages) {
      if (typeof msg.content !== "string") {
        return new Response(
          JSON.stringify({
            choices: [{
              message: {
                content: "I'm sorry, but I can only process text messages. Please send your question as plain text and I'll be happy to help with Pilates and Padel recommendations!"
              }
            }]
          }),
          { status: 200, headers: corsHeaders }
        );
      }
    }

    const response = await callGroq(apiKey, body);
    return new Response(JSON.stringify(response), {
      status: 200,
      headers: corsHeaders,
    });

  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: corsHeaders,
    });
  }
});

async function callGroq(
  apiKey: string,
  request: ChatCompletionRequest
): Promise<Record<string, unknown>> {
  const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: "llama-3.1-8b-instant",
      messages: request.messages,
      max_tokens: request.max_tokens ?? 500,
      temperature: request.temperature ?? 0.7,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Groq API error: ${response.status} - ${errorText}`);
  }

  return await response.json();
}

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/chat-completion' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"messages":[{"role":"user","content":"Hello"}]}'

*/