import fs from "node:fs/promises";
import path from "node:path";
import { randomUUID } from "node:crypto";
import { env } from "@/lib/config/env";

type DbData = {
  createdAt: string;
  notes: Array<{ id: string; text: string; createdAt: string }>;
  events: Array<{ id: string; source: string; message: string; createdAt: string }>;
};

function getDbPath() {
  return path.resolve(process.cwd(), env.appDbPath);
}

async function ensureDb(): Promise<DbData> {
  const dbPath = getDbPath();

  try {
    const raw = await fs.readFile(dbPath, "utf8");
    return JSON.parse(raw) as DbData;
  } catch {
    const fresh: DbData = {
      createdAt: new Date().toISOString(),
      notes: [],
      events: []
    };

    await fs.mkdir(path.dirname(dbPath), { recursive: true });
    await fs.writeFile(dbPath, JSON.stringify(fresh, null, 2), "utf8");
    return fresh;
  }
}

async function saveDb(data: DbData) {
  const dbPath = getDbPath();
  await fs.mkdir(path.dirname(dbPath), { recursive: true });
  await fs.writeFile(dbPath, JSON.stringify(data, null, 2), "utf8");
}

export const db = {
  async getAll() {
    return ensureDb();
  },

  async addNote(text: string) {
    const data = await ensureDb();

    const note = {
      id: randomUUID(),
      text,
      createdAt: new Date().toISOString()
    };

    data.notes.unshift(note);
    await saveDb(data);
    return note;
  },

  async addEvent(source: string, message: string) {
    const data = await ensureDb();

    const event = {
      id: randomUUID(),
      source,
      message,
      createdAt: new Date().toISOString()
    };

    data.events.unshift(event);
    await saveDb(data);
    return event;
  }
};