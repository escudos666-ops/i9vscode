import fs from "node:fs/promises";
import path from "node:path";

export async function getWorkspaceInfo() {
  const root = process.cwd();
  const items = await fs.readdir(root, { withFileTypes: true });

  return {
    ok: true,
    root,
    folders: items.filter((item) => item.isDirectory()).map((item) => item.name),
    files: items.filter((item) => item.isFile()).map((item) => item.name),
    workspaceFile: path.join(root, "vscode-dash-ai.code-workspace")
  };
}