import { getOutlookMessages } from "@/lib/outlook/client";

export async function GET(request: Request) {
  const url = new URL(request.url);
  const user = url.searchParams.get("user") ?? "me";

  const result = await getOutlookMessages(user);
  return Response.json(result);
}