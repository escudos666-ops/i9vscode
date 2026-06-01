import { getWhatsappStatus } from "@/lib/whatsapp/client";

export async function GET() {
  const result = await getWhatsappStatus();

  return Response.json(result, {
    status: result.ok ? 200 : 400
  });
}