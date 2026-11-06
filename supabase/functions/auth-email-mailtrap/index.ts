import { createMailtrapHook } from "./handler.ts";

Deno.serve(createMailtrapHook({
  env: (name) => Deno.env.get(name),
  log: (message) => console.error(message),
}));
