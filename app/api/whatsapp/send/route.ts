import { sendWhatsappMessage } from "@/lib/whatsapp/client";

export async function POST(request: Request) {
  const body = await request.json();

  const to = String(body.to ?? "");
  const text = String(body.text ?? "");

  const result = await sendWhatsappMessage(to, text);

  return Response.json(result, {
    status: result.ok ? 200 : 400
  });
}