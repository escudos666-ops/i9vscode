import { db } from "@/lib/db";

export async function GET() {
  const data = await db.getAll();
  return Response.json(data);
}

export async function POST(request: Request) {
  const body = await request.json();
  const text = String(body.text ?? "");

  const note = await db.addNote(text);

  return Response.json({ ok: true, note });
}