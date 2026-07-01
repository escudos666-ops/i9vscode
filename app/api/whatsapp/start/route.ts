import { startWhatsappSession } from "@/lib/whatsapp/client";

export async function POST() {
  const result = await startWhatsappSession();

  return Response.json(result, {
    status: result.ok ? 200 : 400
  });
}