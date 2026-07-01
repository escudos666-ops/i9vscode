import { askOllama } from "@/lib/ollama/client";

export async function POST(request: Request) {
  const body = await request.json();
  const prompt = String(body.prompt ?? body.message ?? "");

  const reply = await askOllama(prompt);

  return Response.json({ ok: true, reply });
}