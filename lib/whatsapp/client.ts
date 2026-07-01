import { env } from "@/lib/config/env";

type WahaResult = {
  ok: boolean;
  configured: boolean;
  status: number;
  data: unknown;
};

function normalizeChatId(to: string) {
  const clean = to.trim();

  if (clean.includes("@c.us") || clean.includes("@g.us")) {
    return clean;
  }

  const digitsOnly = clean.replace(/[^\d]/g, "");

  if (!digitsOnly) {
    throw new Error("WhatsApp recipient is empty. Use a phone number like 31600000000.");
  }

  return `${digitsOnly}@c.us`;
}

async function callWaha(path: string, options: RequestInit = {}): Promise<WahaResult> {
  if (!env.wahaUrl || !env.wahaApiKey) {
    return {
      ok: false,
      configured: false,
      status: 0,
      data: {
        note: "WAHA_URL and WAHA_API_KEY are missing in .env.local. Restart npm run dev after editing."
      }
    };
  }

  const response = await fetch(`${env.wahaUrl}${path}`, {
    ...options,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-Api-Key": env.wahaApiKey,
      ...(options.headers ?? {})
    },
    cache: "no-store"
  });

  let data: unknown;

  try {
    data = await response.json();
  } catch {
    data = await response.text();
  }

  return {
    ok: response.ok,
    configured: true,
    status: response.status,
    data
  };
}

export async function getWhatsappStatus() {
  return callWaha(`/api/sessions/${env.wahaSession}`);
}

export async function startWhatsappSession() {
  return callWaha(`/api/sessions/${env.wahaSession}/start`, {
    method: "POST"
  });
}

export async function getWhatsappQr() {
  return callWaha(`/api/${env.wahaSession}/auth/qr?format=image`, {
    method: "GET",
    headers: {
      Accept: "application/json"
    }
  });
}

export async function sendWhatsappMessage(to: string, text: string) {
  if (!text.trim()) {
    return {
      ok: false,
      configured: true,
      status: 400,
      data: {
        error: "Message text is required."
      }
    };
  }

  const chatId = normalizeChatId(to);

  return callWaha("/api/sendText", {
    method: "POST",
    body: JSON.stringify({
      session: env.wahaSession,
      chatId,
      text
    })
  });
}