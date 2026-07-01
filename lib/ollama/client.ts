import { env } from "@/lib/config/env";

export async function askOllama(prompt: string): Promise<string> {
  if (!prompt.trim()) return "Type a message first.";

  try {
    const response = await fetch(`${env.ollamaUrl}/api/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: env.ollamaModel,
        prompt,
        stream: false
      })
    });

    if (!response.ok) return `Ollama returned HTTP ${response.status}.`;

    const data = await response.json();
    return data.response ?? "No response from Ollama.";
  } catch {
    return "Could not connect to Ollama. Start Ollama first.";
  }
}

export async function getOllamaStatus() {
  try {
    const response = await fetch(`${env.ollamaUrl}/api/tags`, { cache: "no-store" });
    return { ok: response.ok, url: env.ollamaUrl, model: env.ollamaModel };
  } catch {
    return { ok: false, url: env.ollamaUrl, model: env.ollamaModel };
  }
}