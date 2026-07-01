import { getWorkspaceInfo } from "@/lib/vscode/client";

export async function GET() {
  const result = await getWorkspaceInfo();
  return Response.json(result);
}