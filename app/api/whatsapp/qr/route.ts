import { getWhatsappQr } from "@/lib/whatsapp/client";

export async function GET() {
  const result = await getWhatsappQr();

  return Response.json(result, {
    status: result.ok ? 200 : 400
  });
}