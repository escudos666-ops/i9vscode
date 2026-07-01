import { getOllamaStatus } from "@/lib/ollama/client";
import { db } from "@/lib/db";

export async function GET() {
  const ollama = await getOllamaStatus();
  const database = await db.getAll();

  return Response.json({
    ok: true,
    app: "VSCode Dash AI",
    services: {
      ollama,
      database: {
        ok: true,
        notes: database.notes.length,
        events: database.events.length
      },
      outlook: { configured: Boolean(process.env.OUTLOOK_TENANT_ID) },
      shopify: { configured: Boolean(process.env.SHOPIFY_STORE) },
      whatsapp: { configured: Boolean(process.env.WHATSAPP_PHONE_NUMBER_ID) }
    }
  });
}